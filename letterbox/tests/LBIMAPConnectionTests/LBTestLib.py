#!/usr/bin/python
from twisted.internet.protocol import Protocol, Factory
from twisted.internet import reactor

import sys
import time

class TCPHandler(Protocol):
    
    def connectionMade(self):
        self.scriptIdx = 0
        self.stepNextScript()
        
    def dataReceived(self, data):
        print("py: " + data)
        self.stepNextScript()
     
    def stepNextScript(self):
        
        if self.scriptIdx >= len(self.script):
            self.transport.loseConnection()
            print("stopping")
            reactor.stop()
            sys.exit(0)
            
        print("py sending: " + self.script[self.scriptIdx])
        self.transport.write(self.script[self.scriptIdx])
        
        self.scriptIdx = self.scriptIdx + 1

def runScript(aScript):
    TCPHandler.script = aScript
    
    factory = Factory()
    factory.protocol = TCPHandler
    
    port = 1430
    print("Setting up server on port " + str(port))
    reactor.listenTCP(port, factory)
    reactor.run()


