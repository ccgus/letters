#!/usr/bin/python

import LBTestLib


script = []
script.append("* OK [CAPABILITY mmp0795 IMAP4 IMAP4rev1 ACL QUOTA LITERAL+ NAMESPACE UIDPLUS CHILDREN BINARY UNSELECT SORT LANGUAGE IDLE XSENDER X-NETSCAPE XSERVERINFO X-SUN-SORT X-SUN-IMAP X-ANNOTATEMORE X-UNAUTHENTICATE XUM1 AUTH=PLAIN] Messaging Multiplexor (Sun Java(tm) System Messaging Server 7.2-7.02 (built Apr 16 2009))\r\n")

script.append("1 OK User logged in\r\n")

script.append('* FLAGS (\Answered \Flagged \Draft \Deleted \Seen)\r\n\
* OK [PERMANENTFLAGS (\Answered \Flagged \Draft \Deleted \Seen \*)]\r\n\
* 1 EXISTS\r\n\
* 0 RECENT\r\n\
* OK [UIDVALIDITY 1266876990]\r\n\
* OK [UIDNEXT 2]\r\n\
2 OK [READ-WRITE] Completed\r\n')

script.append("3 OK HAVE A SUPER NICE DAY SUCKA.\r\n")

LBTestLib.runScript(script)

