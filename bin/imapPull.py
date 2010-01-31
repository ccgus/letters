#!/usr/bin/python

import os
import sys
import string
import getpass
import imaplib
import time
import email
import uuid
from sqlite3 import dbapi2 as sqlite

uname = sys.argv[1]
server = sys.argv[3]

mailbox = imaplib.IMAP4_SSL(server, 993)
mailbox.login(uname, sys.argv[2].encode())

storepath = os.path.expanduser("~/Library/Letters/imap-" + uname + "@" + server + ".letterbox")

if not os.path.exists(storepath):
    os.mkdir(storepath)

dbconn = sqlite.connect(storepath + "/letterscache.db", isolation_level=None)

dbcursor = dbconn.cursor()

dbcursor.execute("create table if not exists letters_meta ( name text, type text, value blob )")
dbcursor.execute("delete from letters_meta")
dbcursor.execute("insert into letters_meta (name, type, value) values (?,?,?)", ("schemaVersion", "int", '1'));
dbcursor.execute("create table if not exists folder ( folder text, subscribed int )");

dbcursor.execute("""create table if not exists message ( uuid text primary key,
                                                         messageid text,
                                                         folder text,
                                                         subject text,
                                                         fromAddress text,
                                                         toAddress text,
                                                         receivedDate float,
                                                         sendDate float)""")

# we're doing a refresh
dbcursor.execute("delete from folder")

typ, data = mailbox.lsub();

mailboxes = []

for mbox in data:
    
    # implementation detail.  only for courier servers probably
    a,b = mbox.split(')')
    mailboxes.append(b[6:-1])

# case insisitive sort.
mailboxes.sort(key=str.lower)

for mbox in mailboxes:
    try:
        dbcursor.execute("insert into folder (folder, subscribed) values (?,?)", (mbox, '1'))
        dbcursor.execute("delete from message where folder = ?", (mbox,))
        mailbox.select(mailbox=mbox, readonly=True)
        typ, data = mailbox.search(None, 'ALL')
        print("%d messages in %s" % (len(data[0]), mbox))
        
        
        folderFSPath = storepath + "/" + mbox
        if not os.path.exists(folderFSPath):
            os.mkdir(folderFSPath)
        
        
        for num in data[0].split():
            typ, data = mailbox.fetch(num, '(RFC822)')
            msg = email.message_from_string(data[0][1])
            
            uid = str(uuid.uuid1())
            
            path = folderFSPath + "/" + uid + ".letterboxmsg"
            
            f = open(path, 'w')
            f.write(str(msg))
            f.close()
            
            print(path)
            
            dbcursor.execute("insert into message (uuid, messageid, folder, subject, fromAddress, toAddress, receivedDate, sendDate) values (?,?,?,?,?,?,?,?)",
                             (uid, msg.get("Message-Id"), mbox, msg.get("Subject"), msg.get("From"), msg.get("To"), 0, 0))
            
            # Tue, 26 Jan 2010 16:28:43 -0800
            
        
    except Exception, e:
            print("Error in select: " + mbox)
            print(e)
    
sys.exit()

    
mailbox.close()
mailbox.logout()

