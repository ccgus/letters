#!/usr/bin/python

import LBTestLib


script = []
script.append(" * OK [CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION STARTTLS] Courier-IMAP ready. Copyright 1998-2008 Double Precision, Inc.  See COPYING for distribution information.\r\n")

script.append("1 OK HAVE A SUPER NICE DAY SUCKA.\r\n")

LBTestLib.runScript(script)

