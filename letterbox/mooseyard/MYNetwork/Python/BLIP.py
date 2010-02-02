# encoding: utf-8
"""
BLIP.py

Created by Jens Alfke on 2008-06-03.
Copyright notice and BSD license at end of file.
"""

import asynchat
import asyncore
from cStringIO import StringIO
import logging
import socket
import struct
import sys
import traceback
import zlib


# Connection status enumeration:
kDisconnected = -1
kClosed  = 0
kOpening = 1
kOpen    = 2
kClosing = 3


# INTERNAL CONSTANTS -- NO TOUCHIES!

kFrameMagicNumber   = 0x9B34F206
kFrameHeaderFormat  = '!LLHH'
kFrameHeaderSize    = 12

kMsgFlag_TypeMask   = 0x000F
kMsgFlag_Compressed = 0x0010
kMsgFlag_Urgent     = 0x0020
kMsgFlag_NoReply    = 0x0040
kMsgFlag_MoreComing = 0x0080
kMsgFlag_Meta       = 0x0100

kMsgType_Request    = 0
kMsgType_Response   = 1
kMsgType_Error      = 2

kMsgProfile_Hi      = "Hi"
kMsgProfile_Bye     = "Bye"

# Logging Setup
class NullLoggingHandler(logging.Handler):
    def emit(self, record):
        pass

log = logging.getLogger('BLIP')
# This line prevents the "No handlers found" warning if the calling code does not use logging.
log.addHandler(NullLoggingHandler())
log.propagate = True


class MessageException(Exception):
    pass

class ConnectionException(Exception):
    pass


### LISTENER AND CONNECTION CLASSES:


class Listener (asyncore.dispatcher):
    "BLIP listener/server class"
    
    def __init__(self, port, sslKeyFile=None, sslCertFile=None):
        "Create a listener on a port"
        asyncore.dispatcher.__init__(self)
        self.onConnected = self.onRequest = None
        self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
        self.bind( ('',port) )
        self.listen(5)
        self.sslKeyFile=sslKeyFile
        self.sslCertFile=sslCertFile
        log.info("Listening on port %u", port)
    
    def handle_accept( self ):
        socket,address = self.accept()
        if self.sslKeyFile:
            socket.ssl(socket,self.sslKeyFile,self.sslCertFile)
        conn = Connection(address, sock=socket, listener=self)
        conn.onRequest = self.onRequest
        if self.onConnected:
            self.onConnected(conn)

    def handle_error(self):
        (typ,val,trace) = sys.exc_info()
        log.error("Listener caught: %s %s\n%s", typ,val,traceback.format_exc())
        self.close()
    


class Connection (asynchat.async_chat):
    def __init__( self, address, sock=None, listener=None, ssl=None ):
        "Opens a connection with the given address. If a connection/socket object is provided it'll use that,"
        "otherwise it'll open a new outgoing socket."
        if sock:
            asynchat.async_chat.__init__(self,sock)
            log.info("Accepted connection from %s",address)
            self.status = kOpen
        else:
            asynchat.async_chat.__init__(self)
            log.info("Opening connection to %s",address)
            self.create_socket(socket.AF_INET, socket.SOCK_STREAM)
            self.status = kOpening
            if ssl:
                ssl(self.socket)
            self.connect(address)
        self.address = address
        self.listener = listener
        self.onRequest = self.onCloseRequest = self.onCloseRefused = None
        self.pendingRequests = {}
        self.pendingResponses = {}
        self.outBox = []
        self.inMessage = None
        self.inNumRequests = self.outNumRequests = 0
        self.sending = False
        self._endOfFrame()
        self._closeWhenPossible = False
    
    def handle_connect(self):
        log.info("Connection open!")
        self.status = kOpen
    
    def handle_error(self):
        (typ,val,trace) = sys.exc_info()
        log.error("Connection caught: %s %s\n%s", typ,val,traceback.format_exc())
        self.discard_buffers()
        self.status = kDisconnected
        self.close()
    
    
    ### SENDING:
    
    @property
    def isOpen(self):
        return self.status==kOpening or self.status==kOpen or self.status==kClosing
    
    @property
    def canSend(self):
        return self.isOpen and not self._closeWhenPossible
    
    def _sendMessage(self, msg):
        if self.isOpen:
            self._outQueueMessage(msg,True)
            if not self.sending:
                log.debug("Waking up the output stream")
                self.sending = True
                self.push_with_producer(self)
            return True
        else:
            return False
    
    def _sendRequest(self, req):
        if self.canSend:
            requestNo = req.requestNo = self.outNumRequests = self.outNumRequests + 1
            response = req.response
            if response:
                response.requestNo = requestNo
                self.pendingResponses[requestNo] = response
                log.debug("pendingResponses[%i] := %s",requestNo,response)
            return self._sendMessage(req)
        else:
            log.warning("%s: Attempt to send a request after the connection has started closing: %s" % (self, req))
            return False
    
    def _outQueueMessage(self, msg,isNew=True):
        n = len(self.outBox)
        index = n
        if msg.urgent and n>1:
            while index > 0:
                otherMsg = self.outBox[index-1]
                if otherMsg.urgent:
                    if index<n:
                        index += 1
                    break
                elif isNew and otherMsg.bytesSent==0:
                    break
                index -= 1
            else:
                index = 1
        
        self.outBox.insert(index,msg)
        if isNew:
            log.info("Queuing %s at index %i",msg,index)
        else:
            log.debug("Re-queueing outgoing message at index %i of %i",index,len(self.outBox))
    
    def more(self):
        n = len(self.outBox)
        if n > 0:
            msg = self.outBox.pop(0)
            frameSize = 4096
            if msg.urgent or n==1 or not self.outBox[0].urgent:
                frameSize *= 4
            data = msg._sendNextFrame(frameSize)
            if msg._moreComing:
                self._outQueueMessage(msg,isNew=False)
            else:
                log.info("Finished sending %s",msg)
            return data
        else:
            log.debug("Nothing more to send")
            self.sending = False
            self._closeIfReady()
            return None
    
    ### RECEIVING:
    
    def collect_incoming_data(self, data):
        if self.expectingHeader:
            if self.inHeader==None:
                self.inHeader = data
            else:
                self.inHeader += data
        elif self.inMessage:
            self.inMessage._receivedData(data)
    
    def found_terminator(self):
        if self.expectingHeader:
            # Got a header:
            (magic, requestNo, flags, frameLen) = struct.unpack(kFrameHeaderFormat,self.inHeader)
            self.inHeader = None
            if magic!=kFrameMagicNumber: raise ConnectionException, "Incorrect frame magic number %x" %magic
            if frameLen < kFrameHeaderSize: raise ConnectionException,"Invalid frame length %u" %frameLen
            frameLen -= kFrameHeaderSize
            log.debug("Incoming frame: type=%i, number=%i, flags=%x, length=%i",
                        (flags&kMsgFlag_TypeMask),requestNo,flags,frameLen)
            self.inMessage = self._inMessageForFrame(requestNo,flags)
            
            if frameLen > 0:
                self.expectingHeader = False
                self.set_terminator(frameLen)
            else:
                self._endOfFrame()
        
        else:
            # Got the frame's payload:
            self._endOfFrame()
    
    def _inMessageForFrame(self, requestNo,flags):
        message = None
        msgType = flags & kMsgFlag_TypeMask
        if msgType==kMsgType_Request:
            message = self.pendingRequests.get(requestNo)
            if message==None and requestNo == self.inNumRequests+1:
                message = IncomingRequest(self,requestNo,flags)
                assert message!=None
                self.pendingRequests[requestNo] = message
                self.inNumRequests += 1
        elif msgType==kMsgType_Response or msgType==kMsgType_Error:
            message = self.pendingResponses.get(requestNo)
            message._updateFlags(flags)
        
        if message != None:
            message._beginFrame(flags)
        else:
            log.warning("Ignoring unexpected frame with type %u, request #%u", msgType,requestNo)
        return message
    
    def _endOfFrame(self):
        msg = self.inMessage
        self.inMessage = None
        self.expectingHeader = True
        self.inHeader = None
        self.set_terminator(kFrameHeaderSize) # wait for binary header
        if msg:
            log.debug("End of frame of %s",msg)
            if not msg._moreComing:
                self._receivedMessage(msg)
    
    def _receivedMessage(self, msg):
        log.info("Received: %s",msg)
        # Remove from pending:
        if msg.isResponse:
            del self.pendingResponses[msg.requestNo]
        else:
            del self.pendingRequests[msg.requestNo]
        # Decode:
        try:
            msg._finished()
            if not msg.isResponse:
                if msg._meta:
                    self._dispatchMetaRequest(msg)
                else:
                    self.onRequest(msg)
                    if not msg.response.sent:
                        log.error("**** Request received, but a response was never sent! Request: %r", msg)
        except Exception, x:
            log.error("Exception handling incoming message: %s", traceback.format_exc())
            #FIX: Send an error reply
        # Check to see if we're done and ready to close:
        self._closeIfReady()
    
    def _dispatchMetaRequest(self, request):
        """Handles dispatching internal meta requests."""
        if request['Profile'] == kMsgProfile_Bye:
            self._handleCloseRequest(request)
        else:
            response = request.response
            response.isError = True
            response['Error-Domain'] = "BLIP"
            response['Error-Code'] = 404
            response.body = "Unknown meta profile"
            response.send()
    
    ### CLOSING:
    
    def _handleCloseRequest(self, request):
        """Handles requests from a peer to close."""
        shouldClose = True
        if self.onCloseRequest:
            shouldClose = self.onCloseRequest()
        if not shouldClose:
            log.debug("Sending resfusal to close...")
            response = request.response
            response.isError = True
            response['Error-Domain'] = "BLIP"
            response['Error-Code'] = 403
            response.body = "Close request denied"
            response.send()
        else:
            log.debug("Sending permission to close...")
            response = request.response
            response.send()
    
    def close(self):
        """Publicly callable close method. Sends close request to peer."""
        if self.status != kOpen:
            return False
        log.info("Sending close request...")
        req = OutgoingRequest(self, None, {'Profile': kMsgProfile_Bye})
        req._meta = True
        req.response.onComplete = self._handleCloseResponse
        if not req.send():
            log.error("Error sending close request.")
            return False
        else:
            self.status = kClosing
        return True
    
    def _handleCloseResponse(self, response):
        """Called when we receive a response to a close request."""
        log.info("Received close response.")
        if response.isError:
            # remote refused to close
            if self.onCloseRefused:
                self.onCloseRefused(response)
            self.status = kOpen
        else:
            # now wait until everything has finished sending, then actually close
            log.info("No refusal, actually closing...")
            self._closeWhenPossible = True
    
    def _closeIfReady(self):
        """Checks if all transmissions are complete and then closes the actual socket."""
        if self._closeWhenPossible and len(self.outBox) == 0 and len(self.pendingRequests) == 0 and len(self.pendingResponses) == 0:
            # self._closeWhenPossible = False
            log.debug("_closeIfReady closing.")
            asynchat.async_chat.close(self)
    
    def handle_close(self):
        """Called when the socket actually closes."""
        log.info("Connection closed!")
        self.pendingRequests = self.pendingResponses = None
        self.outBox = None
        if self.status == kClosing:
            self.status = kClosed
        else:
            self.status = kDisconnected
        asyncore.dispatcher.close(self)


### MESSAGE CLASSES:


class Message (object):
    "Abstract superclass of all request/response objects"
    
    def __init__(self, connection, body=None, properties=None):
        self.connection = connection
        self.body = body
        self.properties = properties or {}
        self.requestNo = None
    
    @property
    def flags(self):
        if self.isResponse:
            if self.isError:
                flags = kMsgType_Error
            else:
                flags = kMsgType_Response
        else:
            flags = kMsgType_Request
        if self.urgent:     flags |= kMsgFlag_Urgent
        if self.compressed: flags |= kMsgFlag_Compressed
        if self.noReply:    flags |= kMsgFlag_NoReply
        if self._moreComing:flags |= kMsgFlag_MoreComing
        if self._meta:      flags |= kMsgFlag_Meta
        return flags
    
    def __str__(self):
        s = "%s[" %(type(self).__name__)
        if self.requestNo != None:
            s += "#%i" %self.requestNo
        if self.urgent:     s += " URG"
        if self.compressed: s += " CMP"
        if self.noReply:    s += " NOR"
        if self._moreComing:s += " MOR"
        if self._meta:      s += " MET"
        if self.body:       s += " %i bytes" %len(self.body)
        return s+"]"
    
    def __repr__(self):
        s = str(self)
        if len(self.properties): s += repr(self.properties)
        return s
    
    @property
    def isResponse(self):
        "Is this message a response?"
        return False
    
    @property
    def contentType(self):
        return self.properties.get('Content-Type')
    
    def __getitem__(self, key):     return self.properties.get(key)
    def __contains__(self, key):    return key in self.properties
    def __len__(self):              return len(self.properties)
    def __nonzero__(self):          return True
    def __iter__(self):             return self.properties.__iter__()


class IncomingMessage (Message):
    "Abstract superclass of incoming messages."
    
    def __init__(self, connection, requestNo, flags):
        super(IncomingMessage,self).__init__(connection)
        self.requestNo  = requestNo
        self._updateFlags(flags)
        self.frames     = []
    
    def _updateFlags(self, flags):
        self.urgent     = (flags & kMsgFlag_Urgent) != 0
        self.compressed = (flags & kMsgFlag_Compressed) != 0
        self.noReply    = (flags & kMsgFlag_NoReply) != 0
        self._moreComing= (flags & kMsgFlag_MoreComing) != 0
        self._meta      = (flags & kMsgFlag_Meta) != 0
        self.isError    = (flags & kMsgType_Error) != 0
    
    def _beginFrame(self, flags):
        """Received a frame header."""
        self._moreComing = (flags & kMsgFlag_MoreComing)!=0
    
    def _receivedData(self, data):
        """Received data from a frame."""
        self.frames.append(data)
    
    def _finished(self):
        """The entire message has been received; now decode it."""
        encoded = "".join(self.frames)
        self.frames = None
        
        # Decode the properties:
        if len(encoded) < 2: raise MessageException, "missing properties length"
        propSize = 2 + struct.unpack('!H',encoded[0:2])[0]
        if propSize>len(encoded): raise MessageException, "properties too long to fit"
        if propSize>2 and encoded[propSize-1] != '\000': raise MessageException, "properties are not nul-terminated"
        
        if propSize > 2:
            proplist = encoded[2:propSize-1].split('\000')
        
            if len(proplist) & 1: raise MessageException, "odd number of property strings"
            for i in xrange(0,len(proplist),2):
                def expand(str):
                    if len(str)==1:
                        str = IncomingMessage.__expandDict.get(str,str)
                    return str
                self.properties[ expand(proplist[i])] = expand(proplist[i+1])
        
        encoded = encoded[propSize:]
        # Decode the body:
        if self.compressed and len(encoded)>0:
            try:
                encoded = zlib.decompress(encoded,31)   # window size of 31 needed for gzip format
            except zlib.error:
                raise MessageException, sys.exc_info()[1]
        self.body = encoded
    
    __expandDict= {'\x01' : "Content-Type",
                   '\x02' : "Profile",
                   '\x03' : "application/octet-stream",
                   '\x04' : "text/plain; charset=UTF-8",
                   '\x05' : "text/xml",
                   '\x06' : "text/yaml",
                   '\x07' : "Channel",
                   '\x08' : "Error-Code",
                   '\x09' : "Error-Domain"}


class OutgoingMessage (Message):
    "Abstract superclass of outgoing requests/responses."
    
    def __init__(self, connection, body=None, properties=None):
        Message.__init__(self,connection,body,properties)
        self.urgent = self.compressed = self.noReply = self._meta = self.isError = False
        self._moreComing = True
    
    def __setitem__(self, key,val):
        self.properties[key] = val
    def __delitem__(self, key):
        del self.properties[key]
    
    @property
    def sent(self):
        return hasattr(self,'encoded')
    
    def _encode(self):
        "Generates the message's encoded form, prior to sending it."
        out = StringIO()
        for (key,value) in self.properties.iteritems():
            def _writePropString(s):
                out.write(str(s))    #FIX: Abbreviate
                out.write('\000')
            _writePropString(key)
            _writePropString(value)
        propertiesSize = out.tell()
        assert propertiesSize<65536     #FIX: Return an error instead
        
        body = self.body or ""
        if self.compressed:
            z = zlib.compressobj(6,zlib.DEFLATED,31)   # window size of 31 needed for gzip format
            out.write(z.compress(body))
            body = z.flush()
        out.write(body)
        
        self.encoded = struct.pack('!H',propertiesSize) + out.getvalue()
        out.close()
        log.debug("Encoded %s into %u bytes", self,len(self.encoded))
        self.bytesSent = 0
    
    def _sendNextFrame(self, maxLen):
        pos = self.bytesSent
        payload = self.encoded[pos:pos+maxLen]
        pos += len(payload)
        self._moreComing = (pos < len(self.encoded))
        if not self._moreComing:
            self.encoded = None
        log.debug("Sending frame of %s; bytes %i--%i", self,pos-len(payload),pos)
        
        header = struct.pack(kFrameHeaderFormat, kFrameMagicNumber,
                                                   self.requestNo,
                                                   self.flags,
                                                   kFrameHeaderSize+len(payload))
        self.bytesSent = pos
        return header + payload


class Request (object):
    @property
    def response(self):
        "The response object for this request."
        if self.noReply:
            return None
        r = self.__dict__.get('_response')
        if r==None:
            r = self._response = self._createResponse()
        return r


class Response (Message):
    def _setRequest(self, request):
        assert not request.noReply
        self.request = request
        self.requestNo = request.requestNo
        self.urgent = request.urgent
    
    @property
    def isResponse(self):
        return True


class IncomingRequest (IncomingMessage, Request):
    def _createResponse(self):
        return OutgoingResponse(self)


class OutgoingRequest (OutgoingMessage, Request):
    def _createResponse(self):
        return IncomingResponse(self)
    
    def send(self):
        self._encode()
        return self.connection._sendRequest(self) and self.response


class IncomingResponse (IncomingMessage, Response):
    def __init__(self, request):
        IncomingMessage.__init__(self,request.connection,None,0)
        self._setRequest(request)
        self.onComplete = None
    
    def _finished(self):
        super(IncomingResponse,self)._finished()
        if self.onComplete:
            try:
                self.onComplete(self)
            except Exception, x:
                log.error("Exception dispatching response: %s", traceback.format_exc())


class OutgoingResponse (OutgoingMessage, Response):
    def __init__(self, request):
        OutgoingMessage.__init__(self,request.connection)
        self._setRequest(request)
    
    def send(self):
        self._encode()
        return self.connection._sendMessage(self)


"""
 Copyright (c) 2008, Jens Alfke <jens@mooseyard.com>. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted
 provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
 and the following disclaimer in the documentation and/or other materials provided with the
 distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRI-
 BUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
 THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
"""
