# -*- coding: utf-8 -*-

import sys
import Foundation
import AppKit
import imp
import objc
import os
import os.path
import shutil
import StringIO
import traceback
import string
import imaplib
import time
import email
import uuid

from sqlite3 import dbapi2 as sqlite



class IMAPFetcher (Foundation.NSObject):
    
    def setAccount_(self, anAccount):
        self.account = anAccount;
    
    def setAccountFolder_(self, anAccountFolder):
        self.accountFolder = anAccountFolder;
    
    def connect(self):
        typ = None
        data = None
        try:
            print("Connecting to: " + self.account.imapServer());
            self.mailbox = imaplib.IMAP4_SSL(self.account.imapServer(), 993)
            typ, data = self.mailbox.login(self.account.username(), self.account.password())
        except Exception, e:
            print(e)
            print("Error logging in: " + str(typ))
            print(data)
        
        print("Connected? " + typ)
        
        return typ == 'OK'
    
    def folderNames(self):
        typ   = None
        data  = None
        names = []
        try:
            typ, data = self.mailbox.list();
        except Exception, e:
            print(e)
            print("Error in folderNames: " + str(typ))
            print(data)
        
        return data
    
    def messagesInMailbox_(self, mbox):
        typ   = None
        data  = None
        messages = []
        try:
            self.mailbox.select(mailbox=mbox, readonly=True)
            typ, data = self.mailbox.search(None, 'ALL')
            for num in data[0].split():
                typ, data = self.mailbox.fetch(num, '(RFC822)')
                
                messages.append(data[0][1])
                
                #msg = email.message_from_string(data[0][1]
                
                
                
                #print(data[0][1]);
                #msg = email.message_from_string(data[0][1].decode())
                #print(msg)
                # msg is email.message.Message
            
            print(data);
            
            print("%d messages in %s" % (len(data[0]), mbox))
            
        except Exception, e:
            print(e)
            print("Error in messagesInMailbox: (" + mbox + ") " + str(typ))
            print(data)
        
        return messages


