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
from dateutil.parser import *

# From the python docs for determining the local time zone. http://docs.python.org/library/datetime.html#datetime-objects

# A class capturing the platform's idea of local time.
from datetime import tzinfo, timedelta, datetime

ZERO = timedelta(0)

import time as _time

STDOFFSET = timedelta(seconds = -_time.timezone)
if _time.daylight:
    DSTOFFSET = timedelta(seconds = -_time.altzone)
else:
    DSTOFFSET = STDOFFSET

DSTDIFF = DSTOFFSET - STDOFFSET

class LocalTimezone(tzinfo):

    def utcoffset(self, dt):
        if self._isdst(dt):
            return DSTOFFSET
        else:
            return STDOFFSET

    def dst(self, dt):
        if self._isdst(dt):
            return DSTDIFF
        else:
            return ZERO

    def tzname(self, dt):
        return _time.tzname[self._isdst(dt)]

    def _isdst(self, dt):
        tt = (dt.year, dt.month, dt.day,
              dt.hour, dt.minute, dt.second,
              dt.weekday(), 0, -1)
        stamp = _time.mktime(tt)
        tt = _time.localtime(stamp)
        return tt.tm_isdst > 0

Local = LocalTimezone()

# End of python doc code.

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
    msg = None
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
            send = parse(msg.get("date"), fuzzy=True)
            send = send.astimezone(Local)
            # Apparently this loses fractional seconds. I'm pretty sure we don't care.
            sendsinceepoch = time.mktime(send.timetuple())
            
            receivedsinceepoch = 0
            if msg.has_key("Received"):
                # Multiple received headers is crazy common.
                receivedheaders = msg.get_all("Received")
                for receivedheader in receivedheaders:
                    # The bit after the ";" is the date-time stamp.
                    datestring = receivedheader.partition(";")[2].strip()
                    latestreceived = parse(datestring, fuzzy=True)
                    # For whatever reason, sometimes we get a datetime without the timezone set.
                    if None == latestreceived.tzinfo:
                        latestreceived = latestreceived.replace(tzinfo=Local)
                    latestreceived = latestreceived.astimezone(Local)
                    latestreceivedsinceepoch = time.mktime(latestreceived.timetuple())
                    if latestreceivedsinceepoch > receivedsinceepoch:
                        receivedsinceepoch = latestreceivedsinceepoch
            else:
                # There's no guarantee of a received header. It would appear Apple Mail uses send in these cases.
                receivedsinceepoch = sendsinceepoch
            
            dbcursor.execute("insert into message (uuid, messageid, folder, subject, fromAddress, toAddress, receivedDate, sendDate) values (?,?,?,?,?,?,?,?)",
                             (uid, msg.get("Message-Id"), mbox, msg.get("Subject"), msg.get("From"), msg.get("To"), receivedsinceepoch, sendsinceepoch))
            
    except Exception, e:
            print("Error in select: " + mbox)
            if None != msg:
                print("Last message: " + msg.as_string())
            print(e)
    
sys.exit()

    
mailbox.close()
mailbox.logout()

