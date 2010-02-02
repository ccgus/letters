/*
 * Mail.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class MailItem, MailApplication, MailColor, MailDocument, MailWindow, MailText, MailAttachment, MailParagraph, MailWord, MailCharacter, MailAttributeRun, MailOutgoingMessage, MailLdapServer, MailApplication, MailMessageViewer, MailSignature, MailMessage, MailAccount, MailImapAccount, MailMacAccount, MailPopAccount, MailSmtpServer, MailMailbox, MailRule, MailRuleCondition, MailRecipient, MailBccRecipient, MailCcRecipient, MailToRecipient, MailContainer, MailHeader, MailMailAttachment;

typedef enum {
	MailSavoYes = 'yes ' /* Save the file. */,
	MailSavoNo = 'no  ' /* Do not save the file. */,
	MailSavoAsk = 'ask ' /* Ask the user whether or not to save the file. */
} MailSavo;

typedef enum {
	MailEdmfPlainText = 'dmpt' /* Plain Text */,
	MailEdmfRichText = 'dmrt' /* Rich Text */
} MailEdmf;

typedef enum {
	MailHedeAll = 'hdal' /* All */,
	MailHedeCustom = 'hdcu' /* Custom */,
	MailHedeDefault = 'hdde' /* Default */,
	MailHedeNoHeaders = 'hdnn' /* No headers */
} MailHede;

typedef enum {
	MailLdasBase = 'lsba' /* LDAP scope of 'Base' */,
	MailLdasOneLevel = 'lsol' /* LDAP scope of 'One Level' */,
	MailLdasSubtree = 'lsst' /* LDAP scope of 'Subtree' */
} MailLdas;

typedef enum {
	MailQqclBlue = 'ccbl' /* Blue */,
	MailQqclGreen = 'ccgr' /* Green */,
	MailQqclOrange = 'ccor' /* Orange */,
	MailQqclOther = 'ccot' /* Other */,
	MailQqclPurple = 'ccpu' /* Purple */,
	MailQqclRed = 'ccre' /* Red */,
	MailQqclYellow = 'ccye' /* Yellow */
} MailQqcl;

typedef enum {
	MailMvclAttachmentsColumn = 'ecat' /* Column containing the number of attachments a message contains */,
	MailMvclBuddyAvailabilityColumn = 'ecba' /* Column indicating whether the sender of a message is online or not */,
	MailMvclMessageColor = 'eccl' /* Used to indicate sorting should be done by color */,
	MailMvclDateReceivedColumn = 'ecdr' /* Column containing the date a message was received */,
	MailMvclDateSentColumn = 'ecds' /* Column containing the date a message was sent */,
	MailMvclFlagsColumn = 'ecfl' /* Column containing the flags of a message */,
	MailMvclFromColumn = 'ecfr' /* Column containing the sender's name */,
	MailMvclMailboxColumn = 'ecmb' /* Column containing the name of the mailbox or account a message is in */,
	MailMvclMessageStatusColumn = 'ecms' /* Column indicating a messages status (read, unread, replied to, forwarded, etc) */,
	MailMvclNumberColumn = 'ecnm' /* Column containing the number of a message in a mailbox */,
	MailMvclSizeColumn = 'ecsz' /* Column containing the size of a message */,
	MailMvclSubjectColumn = 'ecsu' /* Column containing the subject of a message */,
	MailMvclToColumn = 'ecto' /* Column containing the recipients of a message */
} MailMvcl;

typedef enum {
	MailExutPassword = 'axct' /* Clear text password */,
	MailExutApop = 'aapo' /* APOP */,
	MailExutKerberos5 = 'axk5' /* Kerberos 5 */,
	MailExutNtlm = 'axnt' /* NTLM */,
	MailExutMd5 = 'axmd' /* MD5 */,
	MailExutNone = 'ccno' /* None */
} MailExut;

typedef enum {
	MailCclrBlue = 'ccbl' /* Blue */,
	MailCclrGray = 'ccgy' /* Gray */,
	MailCclrGreen = 'ccgr' /* Green */,
	MailCclrNone = 'ccno' /* None */,
	MailCclrOrange = 'ccor' /* Orange */,
	MailCclrOther = 'ccot' /* Other */,
	MailCclrPurple = 'ccpu' /* Purple */,
	MailCclrRed = 'ccre' /* Red */,
	MailCclrYellow = 'ccye' /* Yellow */
} MailCclr;

typedef enum {
	MailE9xpAllMessagesAndTheirAttachments = 'x9al' /* All messages and their attachments */,
	MailE9xpAllMessagesButOmitAttachments = 'x9bo' /* All messages but omit attachments */,
	MailE9xpDoNotKeepCopiesOfAnyMessages = 'x9no' /* Do not keep copies of any messages */,
	MailE9xpOnlyMessagesIHaveRead = 'x9wr' /* Only messages I have read */
} MailE9xp;

typedef enum {
	MailEnrqBeginsWithValue = 'rqbw' /* Begins with value */,
	MailEnrqDoesContainValue = 'rqco' /* Does contain value */,
	MailEnrqDoesNotContainValue = 'rqdn' /* Does not contain value */,
	MailEnrqEndsWithValue = 'rqew' /* Ends with value */,
	MailEnrqEqualToValue = 'rqie' /* Equal to value */,
	MailEnrqLessThanValue = 'rqlt' /* Less than value */,
	MailEnrqGreaterThanValue = 'rqgt' /* Greater than value */,
	MailEnrqNone = 'rqno' /* Indicates no qualifier is applicable */
} MailEnrq;

typedef enum {
	MailErutAccount = 'tacc' /* Account */,
	MailErutAnyRecipient = 'tanr' /* Any recipient */,
	MailErutCcHeader = 'tccc' /* Cc header */,
	MailErutMatchesEveryMessage = 'tevm' /* Every message */,
	MailErutFromHeader = 'tfro' /* From header */,
	MailErutHeaderKey = 'thdk' /* An arbitrary header key */,
	MailErutMessageContent = 'tmec' /* Message content */,
	MailErutMessageIsJunkMail = 'tmij' /* Message is junk mail */,
	MailErutSenderIsInMyAddressBook = 'tsii' /* Sender is in my address book */,
	MailErutSenderIsMemberOfGroup = 'tsim' /* Sender is member of group */,
	MailErutSenderIsNotInMyAddressBook = 'tsin' /* Sender is not in my address book */,
	MailErutSenderIsNotMemberOfGroup = 'tsig' /* Sender is not member of group */,
	MailErutSubjectHeader = 'tsub' /* Subject header */,
	MailErutToHeader = 'ttoo' /* To header */,
	MailErutToOrCcHeader = 'ttoc' /* To or Cc header */
} MailErut;

typedef enum {
	MailEtocImap = 'etim' /* IMAP */,
	MailEtocPop = 'etpo' /* POP */,
	MailEtocSmtp = 'etsm' /* SMTP */,
	MailEtocMac = 'etit' /* .Mac */
} MailEtoc;



/*
 * Standard Suite
 */

// Abstract object provides a base class for scripting classes.  It is never used directly.
@interface MailItem : SBObject

@property (copy) NSDictionary *properties;  // All of the object's properties.

- (void) open;  // Open an object.
- (void) print;  // Print an object.
- (void) closeSaving:(MailSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveIn:(NSString *)in_ as:(NSString *)as;  // Save an object.

@end

// An application's top level scripting object.
@interface MailApplication : SBApplication
+ (MailApplication *) application;

- (SBElementArray *) documents;
- (SBElementArray *) windows;

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *version;  // The version of the application.

- (void) quitSaving:(MailSavo)saving;  // Quit an application.
- (void) checkForNewMailFor:(MailAccount *)for_;  // Triggers a check for email.
- (NSString *) extractNameFrom:(NSString *)x;  // Command to get the full name out of a fully specified email address. E.g. Calling this with "John Doe <jdoe@example.com>" as the direct object would return "John Doe"
- (NSString *) extractAddressFrom:(NSString *)x;  // Command to get just the email address of a fully specified email address. E.g. Calling this with "John Doe <jdoe@example.com>" as the direct object would return "jdoe@example.com"
- (void) GetURL:(NSString *)x;  // Opens a mailto URL.
- (void) importMailMailboxAt:(NSString *)at;  // Imports a mailbox in Mail's mbox format.
- (void) mailto:(NSString *)x;  // Opens a mailto URL.
- (void) performMailActionWithMessages:(NSArray *)x inMailboxes:(MailMailbox *)inMailboxes forRule:(MailRule *)forRule;  // Script handler invoked by rules and menus that execute AppleScripts.  The direct parameter of this handler is a list of messages being acted upon.
- (void) synchronizeWith:(MailAccount *)with;  // Command to trigger synchronizing of an IMAP account with the server.

@end

// A color.
@interface MailColor : SBObject

- (void) open;  // Open an object.
- (void) print;  // Print an object.
- (void) closeSaving:(MailSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveIn:(NSString *)in_ as:(NSString *)as;  // Save an object.

@end

// A document.
@interface MailDocument : SBObject

@property (copy) NSString *path;  // The document's path.
@property (readonly) BOOL modified;  // Has the document been modified since the last save?
@property (copy) NSString *name;  // The document's name.

- (void) open;  // Open an object.
- (void) print;  // Print an object.
- (void) closeSaving:(MailSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveIn:(NSString *)in_ as:(NSString *)as;  // Save an object.

@end

// A window.
@interface MailWindow : SBObject

@property (copy) NSString *name;  // The full title of the window.
- (NSInteger) id;  // The unique identifier of the window.
@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (readonly) BOOL titled;  // Whether the window has a title bar.
@property NSInteger index;  // The index of the window in the back-to-front window ordering.
@property (readonly) BOOL floating;  // Whether the window floats.
@property (readonly) BOOL miniaturizable;  // Whether the window can be miniaturized.
@property BOOL miniaturized;  // Whether the window is currently miniaturized.
@property (readonly) BOOL modal;  // Whether the window is the application's current modal window.
@property (readonly) BOOL resizable;  // Whether the window can be resized.
@property BOOL visible;  // Whether the window is currently visible.
@property (readonly) BOOL zoomable;  // Whether the window can be zoomed.
@property BOOL zoomed;  // Whether the window is currently zoomed.

- (void) open;  // Open an object.
- (void) print;  // Print an object.
- (void) closeSaving:(MailSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveIn:(NSString *)in_ as:(NSString *)as;  // Save an object.

@end



/*
 * Text Suite
 */

// Rich (styled) text
@interface MailText : SBObject

- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) characters;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property (copy) NSNumber *size;  // The size in points of the first character.

- (void) open;  // Open an object.
- (void) print;  // Print an object.
- (void) closeSaving:(MailSavo)saving savingIn:(NSURL *)savingIn;  // Close an object.
- (void) delete;  // Delete an object.
- (void) duplicateTo:(SBObject *)to;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (void) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) saveIn:(NSString *)in_ as:(NSString *)as;  // Save an object.
- (NSString *) extractNameFrom;  // Command to get the full name out of a fully specified email address. E.g. Calling this with "John Doe <jdoe@example.com>" as the direct object would return "John Doe"
- (NSString *) extractAddressFrom;  // Command to get just the email address of a fully specified email address. E.g. Calling this with "John Doe <jdoe@example.com>" as the direct object would return "jdoe@example.com"
- (void) GetURL;  // Opens a mailto URL.
- (void) mailto;  // Opens a mailto URL.

@end

// Represents an inline text attachment.  This class is used mainly for make commands.
@interface MailAttachment : MailText

@property (copy) NSString *fileName;  // The path to the file for the attachment


@end

// This subdivides the text into paragraphs.
@interface MailParagraph : MailText


@end

// This subdivides the text into words.
@interface MailWord : MailText


@end

// This subdivides the text into characters.
@interface MailCharacter : MailText


@end

// This subdivides the text into chunks that all have the same attributes.
@interface MailAttributeRun : MailText


@end



/*
 * Mail
 */

// A new email message
@interface MailOutgoingMessage : MailItem

- (SBElementArray *) bccRecipients;
- (SBElementArray *) ccRecipients;
- (SBElementArray *) recipients;
- (SBElementArray *) toRecipients;

@property (copy) NSString *sender;  // The sender of the message
@property (copy) NSString *subject;  // The subject of the message
@property (copy) MailText *content;  // The contents of the message
@property BOOL visible;  // Controls whether the message window is shown on the screen.  The default is false
@property (copy) MailSignature *messageSignature;  // The signature of the message
- (NSInteger) id;  // The unique identifier of the message

- (BOOL) send;  // Sends a message.

@end

// LDAP servers for use in type completion in Mail
@interface MailLdapServer : MailItem

@property BOOL enabled;  // Indicates whether this LDAP server will be used for type completion in Mail
@property (copy) NSString *name;  // Name of LDAP server configuration to be displayed in Composing preferences
@property NSInteger port;  // Port number for the LDAP server (default is 389)
@property MailLdas scope;  // Scope setting for the LDAP server
@property (copy) NSString *searchBase;  // Search base for this LDAP server (not required by all LDAP servers)
@property (copy) NSString *hostName;  // Internet address (myldapserver.company.com) for LDAP server


@end

// Mail's top level scripting object.
@interface MailApplication (Mail)

- (SBElementArray *) accounts;
- (SBElementArray *) outgoingMessages;
- (SBElementArray *) smtpServers;
- (SBElementArray *) MacAccounts;
- (SBElementArray *) imapAccounts;
- (SBElementArray *) ldapServers;
- (SBElementArray *) mailboxes;
- (SBElementArray *) messageViewers;
- (SBElementArray *) popAccounts;
- (SBElementArray *) rules;
- (SBElementArray *) signatures;

@property (copy, readonly) NSString *version;  // The version of the application.
@property BOOL alwaysBccMyself;  // Indicates whether you will be included in the Bcc: field of messages which you are composing
@property BOOL alwaysCcMyself;  // Indicates whether you will be included in the Cc: field of messages which you are composing
@property (copy, readonly) NSArray *selection;  // List of messages that the user has selected
@property (copy, readonly) NSString *applicationVersion;  // The build number for the Mail application bundle
@property NSInteger fetchInterval;  // The interval (in minutes) between automatic fetches of new mail
@property (readonly) NSInteger backgroundActivityCount;  // Number of background activities currently running in Mail, according to the Activity Viewer
@property BOOL chooseSignatureWhenComposing;  // Indicates whether user can choose a signature directly in a new compose window
@property BOOL colorQuotedText;  // Indicates whether quoted text should be colored
@property MailEdmf defaultMessageFormat;  // Default format for messages being composed or message replies
@property BOOL downloadHtmlAttachments;  // Indicates whether images and attachments in HTML messages should be downloaded and displayed
@property (copy, readonly) MailMailbox *draftsMailbox;  // The top level Drafts mailbox
@property BOOL expandGroupAddresses;  // Indicates whether group addresses will be expanded when entered into the address fields of a new compose message
@property (copy) NSString *fixedWidthFont;  // Font for plain text messages, only used if 'use fixed width font' is set to true
@property double fixedWidthFontSize;  // Font size for plain text messages, only used if 'use fixed width font' is set to true
@property (copy, readonly) NSString *frameworkVersion;  // The build number for the Message framework, used by Mail
@property MailHede headerDetail;  // The level of detail shown for headers on incoming messages
@property (copy, readonly) MailMailbox *inbox;  // The top level In mailbox
@property BOOL includeAllOriginalMessageText;  // Indicates whether all of the original message will be quoted or only the text you have selected (if any)
@property BOOL quoteOriginalMessage;  // Indicates whether the text of the original message will be included in replies
@property BOOL checkSpellingWhileTyping;  // Indicates whether spelling will be checked automatically in messages being composed
@property (copy, readonly) MailMailbox *junkMailbox;  // The top level Junk mailbox
@property MailQqcl levelOneQuotingColor;  // Color for quoted text with one level of indentation
@property MailQqcl levelTwoQuotingColor;  // Color for quoted text with two levels of indentation
@property MailQqcl levelThreeQuotingColor;  // Color for quoted text with three levels of indentation
@property (copy) NSString *messageFont;  // Font for messages (proportional font)
@property double messageFontSize;  // Font size for messages (proportional font)
@property (copy) NSString *messageListFont;  // Font for message list
@property double messageListFontSize;  // Font size for message list
@property (copy) NSString *newMailSound;  // Name of new mail sound or 'None' if no sound is selected
@property (copy, readonly) MailMailbox *outbox;  // The top level Out mailbox
@property BOOL shouldPlayOtherMailSounds;  // Indicates whether sounds will be played for various things such as when a messages is sent or if no mail is found when manually checking for new mail or if there is a fetch error
@property BOOL sameReplyFormat;  // Indicates whether replies will be in the same text format as the message to which you are replying
@property (copy) NSString *selectedSignature;  // Name of current selected signature (or 'randomly', 'sequentially', or 'none')
@property (copy, readonly) MailMailbox *sentMailbox;  // The top level Sent mailbox
@property BOOL fetchesAutomatically;  // Indicates whether mail will automatically be fetched at a specific interval
@property BOOL highlightSelectedThread;  // Indicates whether threads should be highlighted in the Mail viewer window
@property BOOL showOnlineBuddyStatus;  // Indicates whether Mail will show online buddy status
@property (copy, readonly) MailMailbox *trashMailbox;  // The top level Trash mailbox
@property BOOL useAddressCompletion;  // Indicates whether network directories (LDAP) and Address Book will be used for address completion
@property BOOL useFixedWidthFont;  // Should fixed-width font be used for plain text messages?
@property (copy, readonly) NSString *primaryEmail;  // The user's primary email address

@end

// Represents the object responsible for managing a viewer window
@interface MailMessageViewer : MailItem

- (SBElementArray *) messages;

@property (copy, readonly) MailMailbox *draftsMailbox;  // The top level Drafts mailbox
@property (copy, readonly) MailMailbox *inbox;  // The top level In mailbox
@property (copy, readonly) MailMailbox *junkMailbox;  // The top level Junk mailbox
@property (copy, readonly) MailMailbox *outbox;  // The top level Out mailbox
@property (copy, readonly) MailMailbox *sentMailbox;  // The top level Sent mailbox
@property (copy, readonly) MailMailbox *trashMailbox;  // The top level Trash mailbox
@property MailMvcl sortColumn;  // The column that is currently sorted in the viewer
@property BOOL sortedAscending;  // Whether the viewer is sorted ascending or not
@property BOOL mailboxListVisible;  // Controls whether the list of mailboxes is visible or not
@property BOOL previewPaneIsVisible;  // Controls whether the preview pane of the message viewer window is visible or not
@property MailMvcl visibleColumns;  // List of columns that are visible.  The subject column and the message status column will always be visible
- (NSInteger) id;  // The unique identifier of the message viewer
@property (copy) NSArray *visibleMessages;  // List of messages currently being displayed in the viewer
@property (copy) NSArray *selectedMessages;  // List of messages currently selected
@property (copy) NSArray *selectedMailboxes;  // List of mailboxes currently selected in the list of mailboxes
@property (copy) MailWindow *window;  // The window for the message viewer


@end

// Email signatures
@interface MailSignature : MailItem

@property (copy) NSString *content;  // Contents of email signature. If there is a version with fonts and/or styles, that will be returned over the plain text version
@property (copy) NSString *name;  // Name of the signature


@end



/*
 * Message
 */

// An email message
@interface MailMessage : MailItem

- (SBElementArray *) bccRecipients;
- (SBElementArray *) ccRecipients;
- (SBElementArray *) recipients;
- (SBElementArray *) toRecipients;
- (SBElementArray *) headers;
- (SBElementArray *) mailAttachments;

- (NSInteger) id;  // The unique identifier of the message.
@property (copy, readonly) NSString *allHeaders;  // All the headers of the message
@property MailCclr backgroundColor;  // The background color of the message
@property (copy) MailMailbox *mailbox;  // The mailbox in which this message is filed
@property (copy) MailText *content;  // Contents of an email message
@property (copy, readonly) NSDate *dateReceived;  // The date a message was received
@property (copy, readonly) NSDate *dateSent;  // The date a message was sent
@property BOOL deletedStatus;  // Indicates whether the message is deleted or not
@property BOOL flaggedStatus;  // Indicates whether the message is flagged or not
@property BOOL junkMailStatus;  // Indicates whether the message has been marked junk or evaluated to be junk by the junk mail filter.
@property BOOL readStatus;  // Indicates whether the message is read or not
@property (copy, readonly) NSString *messageId;  // The unique message ID string
@property (copy, readonly) NSString *source;  // Raw source of the message
@property (copy) NSString *replyTo;  // The address that replies should be sent to
@property NSInteger messageSize;  // The size (in bytes) of a message
@property (copy) NSString *sender;  // The sender of the message
@property (copy) NSString *subject;  // The subject of the message
@property BOOL wasForwarded;  // Indicates whether the message was forwarded or not
@property BOOL wasRedirected;  // Indicates whether the message was redirected or not
@property BOOL wasRepliedTo;  // Indicates whether the message was replied to or not

- (void) bounce;  // Bounces a message back to the sender.
- (void) delete;  // Delete a message.
- (void) duplicateTo:(MailMailbox *)to;  // Copy message(s) and put the copies in the specified mailbox.
- (MailOutgoingMessage *) forwardOpeningWindow:(BOOL)openingWindow;  // Creates a forwarded message.
- (void) moveTo:(MailMailbox *)to;  // Move message(s) to a new mailbox.
- (MailOutgoingMessage *) redirectOpeningWindow:(BOOL)openingWindow;  // Creates a redirected message.
- (MailOutgoingMessage *) replyOpeningWindow:(BOOL)openingWindow replyToAll:(BOOL)replyToAll;  // Creates a reply message.

@end

// A Mail account for receiving messages (IMAP/POP/.Mac). To create a new receiving account, use the 'pop account', 'imap account', and 'Mac account' objects
@interface MailAccount : MailItem

- (SBElementArray *) mailboxes;

@property (copy) MailSmtpServer *deliveryAccount;  // The delivery account used when sending mail from this account
@property (copy) NSString *name;  // The name of an account
@property (copy) NSString *password;  // Password for this account. Can be set, but not read via scripting
@property MailExut authentication;  // Preferred authentication scheme for account
@property (readonly) MailEtoc accountType;  // The type of an account
@property (copy) NSArray *emailAddresses;  // The list of email addresses configured for an account
@property (copy) NSString *fullName;  // The users full name configured for an account
@property NSInteger emptyJunkMessagesFrequency;  // Number of days before junk messages are deleted (0 = delete on quit, -1 = never delete)
@property NSInteger emptySentMessagesFrequency;  // Number of days before archived sent messages are deleted (0 = delete on quit, -1 = never delete)
@property NSInteger emptyTrashFrequency;  // Number of days before messages in the trash are permanently deleted (0 = delete on quit, -1 = never delete)
@property BOOL emptyJunkMessagesOnQuit;  // Indicates whether the messages in the junk messages mailboxes will be deleted on quit
@property BOOL emptySentMessagesOnQuit;  // Indicates whether the messages in the sent messages mailboxes will be deleted on quit
@property BOOL emptyTrashOnQuit;  // Indicates whether the messages in deleted messages mailboxes will be permanently deleted on quit
@property BOOL enabled;  // Indicates whether the account is enabled or not
@property (copy) NSString *userName;  // The user name used to connect to an account
@property (copy, readonly) NSURL *accountDirectory;  // The directory where the account stores things on disk
@property NSInteger port;  // The port used to connect to an account
@property (copy) NSString *serverName;  // The host name used to connect to an account
@property BOOL includeWhenGettingNewMail;  // Indicates whether the account will be included when getting new mail
@property BOOL moveDeletedMessagesToTrash;  // Indicates whether messages that are deleted will be moved to the trash mailbox
@property BOOL usesSsl;  // Indicates whether SSL is enabled for this receiving account


@end

// An IMAP email account
@interface MailImapAccount : MailAccount

@property BOOL compactMailboxesWhenClosing;  // Indicates whether an IMAP mailbox is automatically compacted when you quit Mail or switch to another mailbox
@property MailE9xp messageCaching;  // Message caching setting for this account
@property BOOL storeDraftsOnServer;  // Indicates whether drafts will be stored on the IMAP server
@property BOOL storeJunkMailOnServer;  // Indicates whether junk mail will be stored on the IMAP server
@property BOOL storeSentMessagesOnServer;  // Indicates whether sent messages will be stored on the IMAP server
@property BOOL storeDeletedMessagesOnServer;  // Indicates whether deleted messages will be stored on the IMAP server


@end

// A .Mac email account
@interface MailMacAccount : MailImapAccount


@end

// A POP email account
@interface MailPopAccount : MailAccount

@property NSInteger bigMessageWarningSize;  // If message size (in bytes) is over this amount, Mail will prompt you asking whether you want to download the message (-1 = do not prompt)
@property NSInteger delayedMessageDeletionInterval;  // Number of days before messages that have been downloaded will be deleted from the server (0 = delete immediately after downloading)
@property BOOL deleteMailOnServer;  // Indicates whether POP account deletes messages on the server after downloading
@property BOOL deleteMessagesWhenMovedFromInbox;  // Indicates whether messages will be deleted from the server when moved from your POP inbox


@end

// An SMTP account (for sending email)
@interface MailSmtpServer : MailItem

@property (copy, readonly) NSString *name;  // The name of an account
@property (copy) NSString *password;  // Password for this account. Can be set, but not read via scripting
@property (readonly) MailEtoc accountType;  // The type of an account
@property MailExut authentication;  // Preferred authentication scheme for account
@property BOOL enabled;  // Indicates whether the account is enabled or not
@property (copy) NSString *userName;  // The user name used to connect to an account
@property NSInteger port;  // The port used to connect to an account
@property (copy) NSString *serverName;  // The host name used to connect to an account
@property BOOL usesSsl;  // Indicates whether SSL is enabled for this receiving account


@end

// A mailbox that holds messages
@interface MailMailbox : MailItem

- (SBElementArray *) mailboxes;
- (SBElementArray *) messages;

@property (copy) NSString *name;  // The name of a mailbox
@property (readonly) NSInteger unreadCount;  // The number of unread messages in the mailbox
@property (copy, readonly) MailAccount *account;
@property (copy, readonly) MailMailbox *container;


@end

// Class for message rules
@interface MailRule : MailItem

- (SBElementArray *) ruleConditions;

@property MailCclr colorMessage;  // If rule matches, apply this color
@property BOOL deleteMessage;  // If rule matches, delete message
@property (copy) NSString *forwardText;  // If rule matches, prepend this text to the forwarded message. Set to empty string to include no prepended text
@property (copy) NSString *forwardMessage;  // If rule matches, forward message to this address, or multiple addresses, separated by commas. Set to empty string to disable this action
@property BOOL markFlagged;  // If rule matches, mark message as flagged
@property BOOL markRead;  // If rule matches, mark message as read
@property (copy) NSString *playSound;  // If rule matches, play this sound (specify name of sound or path to sound)
@property (copy) NSArray *redirectMessage;  // If rule matches, redirect message to this address or multiple addresses, separate by commas. Set to empty string to disable this action
@property (copy) NSString *replyText;  // If rule matches, reply to message and prepend with this text. Set to empty string to disable this action
@property (copy) NSURL *runScript;  // If rule matches, run this AppleScript.  Set to POSIX path of compiled AppleScript file.  Set to empty string to disable this action
@property BOOL allConditionsMustBeMet;  // Indicates whether all conditions must be met for rule to execute
@property (copy) MailMailbox *copyMessage;  // If rule matches, copy to this mailbox
@property (copy) MailMailbox *moveMessage;  // If rule matches, move to this mailbox
@property BOOL highlightTextUsingColor;  // Indicates whether the color will be used to highlight the text or background of a message in the message list
@property BOOL enabled;  // Indicates whether the rule is enabled
@property (copy) NSString *name;  // Name of rule
@property BOOL shouldCopyMessage;  // Indicates whether the rule has a copy action
@property BOOL shouldMoveMessage;  // Indicates whether the rule has a transfer action
@property BOOL stopEvaluatingRules;  // If rule matches, stop rule evaluation for this message


@end

// Class for conditions that can be attached to a single rule
@interface MailRuleCondition : MailItem

@property (copy) NSString *expression;  // Rule expression field
@property (copy) NSString *header;  // Rule header key
@property MailEnrq qualifier;  // Rule qualifier
@property MailErut ruleType;  // Rule type


@end

// An email recipient
@interface MailRecipient : MailItem

@property (copy) NSString *address;  // The recipients email address
@property (copy) NSString *name;  // The name used for display


@end

// An email recipient in the Bcc: field
@interface MailBccRecipient : MailRecipient


@end

// An email recipient in the Cc: field
@interface MailCcRecipient : MailRecipient


@end

// An email recipient in the To: field
@interface MailToRecipient : MailRecipient


@end

// A mailbox that contains other mailboxes.
@interface MailContainer : MailMailbox


@end

// A header value for a message.  E.g. To, Subject, From.
@interface MailHeader : MailItem

@property (copy) NSString *content;  // Contents of the header
@property (copy) NSString *name;  // Name of the header value


@end

// A file attached to a received message.
@interface MailMailAttachment : MailItem

@property (copy, readonly) NSString *name;  // Name of the attachment
@property (copy, readonly) NSString *MIMEType;  // MIME type of the attachment E.g. text/plain.
@property (readonly) NSInteger fileSize;  // Approximate size in bytes.
@property (readonly) BOOL downloaded;  // Indicates whether the attachment has been downloaded.
- (NSString *) id;  // The unique identifier of the attachment.


@end

