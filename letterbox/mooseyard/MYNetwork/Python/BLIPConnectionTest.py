#!/usr/bin/env python
# encoding: utf-8
"""
BLIPConnectionTest.py

Created by Jens Alfke on 2008-06-04.
This source file is test/example code, and is in the public domain.
"""

from BLIP import Connection, OutgoingRequest, kOpening

import asyncore
from cStringIO import StringIO
from datetime import datetime
import logging
import random
import unittest


kSendInterval = 0.2
kNBatchedMessages = 4 # send only 40 requests total
kUrgentEvery = 4

def randbool():
    return random.randint(0,1) == 1


class BLIPConnectionTest(unittest.TestCase):

    def setUp(self):
        self.connection = Connection( ('localhost',46353) )
        self.nRepliesPending = 0
   
    def sendRequest(self):
        size = random.randint(0,32767)
        io = StringIO()
        for i in xrange(0,size):
            io.write( chr(i % 256) )
        body = io.getvalue()
        io.close
    
        req = OutgoingRequest(self.connection, body,{'Content-Type': 'application/octet-stream',
                                                     'User-Agent':  'PyBLIP',
                                                     'Date': datetime.now(),
                                                     'Size': size})
        req.compressed = randbool()
        req.urgent     = (random.randint(0,kUrgentEvery-1)==0)
        req.response.onComplete = self.gotResponse
        return req.send()
    
    def gotResponse(self, response):
        self.nRepliesPending -= 1
        logging.info("Got response!: %s (%i pending)",response,self.nRepliesPending)
        request = response.request
        assert response.body == request.body

    def testClient(self):
        lastReqTime = None
        nIterations = 0
        while nIterations < 10:
            asyncore.loop(timeout=kSendInterval,count=1)
            
            now = datetime.now()
            if self.connection.status!=kOpening and (not lastReqTime or (now-lastReqTime).microseconds >= kSendInterval*1.0e6):
                lastReqTime = now
                for i in xrange(0,kNBatchedMessages):
                    if not self.sendRequest():
                        logging.warn("Couldn't send request (connection is probably closed)")
                        break;
                    self.nRepliesPending += 1
                nIterations += 1
    
    def tearDown(self):
        self.connection.close()
        asyncore.loop() # got to give it time to negotiate close; this call should exit eventually

if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    unittest.main()
