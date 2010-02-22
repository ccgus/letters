#!/usr/bin/python

import LBTestLib


script = []
script.append(" * OK [CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION STARTTLS] Courier-IMAP ready. Copyright 1998-2008 Double Precision, Inc.  See COPYING for distribution information.\r\n")

script.append("1 OK LOGIN Ok.\r\n")

script.append('* LSUB (\HasNoChildren) "." "INBOX.zero"\r\n\
* LSUB (\HasNoChildren) "." "INBOX.Sent Messages"\r\n\
* LSUB (\HasNoChildren) "." "INBOX.Apple Mail To Do"\r\n\
* LSUB (\HasChildren) "." "INBOX.Trash"\r\n\
* LSUB (\HasNoChildren) "." "INBOX.Deleted Messages"\r\n\
* LSUB (\HasNoChildren) "." "INBOX.quartz"\r\n\
* LSUB (\HasNoChildren) "." "INBOX.Drafts.es"\r\n\
* LSUB (\HasNoChildren) "." "INBOX.Sent"\r\n\
* LSUB (\Noselect \HasChildren) "." "INBOX.Drafts"\r\n\
* LSUB (\Noselect \HasChildren) "." "INBOX"\r\n\
2 OK LSUB completed\r\n')

script.append("3 OK HAVE A SUPER NICE DAY SUCKA.\r\n")

LBTestLib.runScript(script)

