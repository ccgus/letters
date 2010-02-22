#!/usr/bin/python

import LBTestLib


script = []
script.append("* OK [CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION STARTTLS] Courier-IMAP ready. Copyright 1998-2008 Double Precision, Inc.  See COPYING for distribution information.\r\n")

script.append("1 OK LOGIN Ok.\r\n")

script.append("* FLAGS ($NotJunk NotJunk \Draft \Answered \Flagged \Deleted \Seen \Recent)\r\n\
* OK [PERMANENTFLAGS ($NotJunk NotJunk \* \Draft \Answered \Flagged \Deleted \Seen)] Limited\r\n\
* 8 EXISTS\r\n\
* 1 RECENT\r\n\
* OK [UIDVALIDITY 1049043632] Ok\r\n\
* OK [MYRIGHTS \"acdilrsw\"] ACL\r\n\
2 OK [READ-WRITE] Ok\r\n")

script.append("* 1 FETCH (FLAGS (\Seen \Deleted))\r\n\
3 OK STORE completed.\r\n")

script.append("** 1 EXPUNGE\r\n\
* 7 EXISTS\r\n\
* 1 RECENT\r\n\
4 OK EXPUNGE completed\r\n")

LBTestLib.runScript(script)
