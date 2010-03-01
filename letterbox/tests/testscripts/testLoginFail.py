#!/usr/bin/python

import LBTestLib


script = []
script.append(" * OK [CAPABILITY IMAP4rev1 UIDPLUS CHILDREN NAMESPACE THREAD=ORDEREDSUBJECT THREAD=REFERENCES SORT QUOTA IDLE ACL ACL2=UNION STARTTLS] \r\n")

script.append("1 NO that wasn't right.\r\n")

LBTestLib.runScript(script)

