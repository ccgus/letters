# CloseTestPing.py
# Tests the closing negotiation facilities of the BLIP 1.1 protocol

from BLIP import Connection, OutgoingRequest

import unittest
import asyncore
import logging

class CloseTestPing(unittest.TestCase):
    
    def handleCloseRefusal(self, resp):
        logging.info("Close request was refused!")
    
    def setUp(self):
        self.connection = Connection( ('localhost', 1337) )
        self.connection.onCloseRefused = self.handleCloseRefusal
    
    def handleResponse(self, resp):
        logging.info("Got response...")
    
    def testClose(self):
        req = OutgoingRequest(self.connection, "Ping")
        req.response.onComplete = self.handleResponse
        req.send()
        
        asyncore.loop(timeout=0, count=5) # give things time to send
        
        self.connection.close()
        
        asyncore.loop()


if __name__ == '__main__':
    logging.basicConfig(level=logging.INFO)
    unittest.main()
