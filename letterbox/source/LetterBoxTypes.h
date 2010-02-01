/*
 * MailCore
 *
 * Copyright (C) 2007 - Matt Ronge
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of the MailCore project nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRELB, INDIRELB, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRALB, STRILB
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */
 
#define DEST_CHARSET "UTF-8"
#define LBContentTypesPath @"/System/Library/Frameworks/Foundation.framework/Resources/types.plist"


/* ========================= */
/* = List of Message Flags = */
/* ========================= */

//TODO Turn these into extern's, not defines

#define LBFlagNew           MAIL_FLAG_NEW
#define LBFlagSeen          MAIL_FLAG_SEEN
#define LBFlagFlagged       MAIL_FLAG_FLAGGED
#define LBFlagDeleted       MAIL_FLAG_DELETED
#define LBFlagAnswered      MAIL_FLAG_ANSWERED
#define LBFlagForwarded     MAIL_FLAG_FORWARDED
#define LBFlagCancelled     MAIL_FLAG_CANCELLED


/* =========================== */
/* = List of Exception Types = */
/* =========================== */

#define LBMIMEParseError            @"MIMEParserError"
#define LBMIMEParseErrorDesc        @"An error occured during MIME parsing."

#define LBMIMEUnknownError          @"MIMEUnknownError"
#define LBMIMEUnknownErrorDesc      @"I don't know how to parse this MIME structure."

#define LBMemoryError               @"MemoryError"
#define LBMemoryErrorDesc           @"Memory could not be allocated."
                           
#define LBLoginError                @"LoginError"
#define LBLoginErrorDesc            @"Error logging into account."
                           
#define LBUnknownError              @"UnknownError"

#define LBMessageNotFound           @"MessageNotFound"
#define LBMessageNotFoundDesc       @"The message could not be found."

#define LBNoSubscribedFolders       @"NoSubcribedFolders"
#define LBNoSubscribedFoldersDesc   @"There are not any subscribed folders."

#define LBNoFolders                 @"NoFolders"
#define LBNoFoldersDesc             @"There are not any folders on the server."

#define LBFetchError                @"FetchError"
#define LBFetchErrorDesc            @"An error has occurred while fetching from the server."

#define LBSMTPError                 @"SMTPError"
#define LBSMTPErrorDesc             @"An error has occurred while attempting to send via SMTP."

#define LBSMTPSocket                @"SMTPSocket"
#define LBSMTPSocketDesc            @"An error has occurred while attempting to open an SMTP socket connection."

#define LBSMTPHello                 @"SMTPHello"
#define LBSMTPHelloDesc             @"An error occured while introducing ourselves to the server with the ehlo, or helo command."

#define LBSMTPTLS                   @"SMTPTLS"
#define LBSMTPTLSDesc               @"An error occured while attempting to setup a TLS connection with the server."

#define LBSMTPLogin                 @"SMTPLogin"
#define LBSMTPLoginDesc             @"The password or username is invalid."

#define LBSMTPFrom                  @"SMTPFrom"
#define LBSMTPFromDesc              @"An error occured while sending the from address."

#define LBSMTPRecipients            @"SMTPRecipients"
#define LBSMTPRecipientsDesc        @"An error occured while sending the recipient addresses."

#define LBSMTPData                  @"SMTPData"
#define LBSMTPDataDesc              @"An error occured while sending message data."
