# CloseTestPong.py
# Tests the closing negotiation facilities of the BLIP 1.1 protocol

from BLIP import Listener

import logging
import asyncore
import unittest

class CloseTestPong(unittest.TestCase):
    
    def shouldClose(self):
        logging.info("Allowed to close.")
        return True
    
    def handleConnection(self, conn):
        logging.info("Accepted connection.")
        conn.onCloseRequest = self.shouldClose
    
    def handleRequest(self, req):
        resp = req.response
        resp.body = "Pong"
        resp.send()
    
    def testClose(self):
        listen = Listener(1337)
        listen.onConnected = self.handleConnection
        listen.onRequest = self.handleRequest
        
        try:
            asyncore.loop()
        except KeyboardInterrupt:
            pass


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    unittest.main()
