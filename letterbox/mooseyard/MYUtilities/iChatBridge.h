/*
 * iChat.h
 */

#import <AppKit/AppKit.h>
#import <ScriptingBridge/ScriptingBridge.h>


@class iChatItem, iChatApplication, iChatColor, iChatDocument, iChatWindow, iChatRichText, iChatCharacter, iChatParagraph, iChatWord, iChatAttributeRun, iChatAttachment, iChatApplication, iChatBuddy, iChatService, iChatChat, iChatTextChat, iChatAudioChat, iChatVideoChat, iChatFileTransfer;

typedef enum {
	iChatSaveOptionsYes = 'yes ' /* Save the file. */,
	iChatSaveOptionsNo = 'no  ' /* Do not save the file. */,
	iChatSaveOptionsAsk = 'ask ' /* Ask the user whether or not to save the file. */
} iChatSaveOptions;

typedef enum {
	iChatInviteTypeAudioInvitation = 'acon',
	iChatInviteTypeTextChatInvitation = 'tcon',
	iChatInviteTypeVideoInvitation = 'vcon'
} iChatInviteType;

typedef enum {
	iChatAccountStatusAvailable = 'aval',
	iChatAccountStatusAway = 'away',
	iChatAccountStatusOffline = 'offl',
	iChatAccountStatusInvisible = 'invs',
	iChatAccountStatusIdle = 'idle',
	iChatAccountStatusUnknown = 'unkn'
} iChatAccountStatus;

typedef enum {
	iChatMyStatusAway = 'away',
	iChatMyStatusAvailable = 'aval',
	iChatMyStatusOffline = 'offl',
	iChatMyStatusInvisible = 'invs'
} iChatMyStatus;

typedef enum {
	iChatConnectionStatusDisconnecting = 'dcng',
	iChatConnectionStatusConnected = 'conn',
	iChatConnectionStatusConnecting = 'cong',
	iChatConnectionStatusDisconnected = 'dcon'
} iChatConnectionStatus;

typedef enum {
	iChatCapabilitiesVideoChat = 'vcon',
	iChatCapabilitiesAudioChat = 'acon',
	iChatCapabilitiesMultipersonVideo = 'mwvc',
	iChatCapabilitiesMultipersonAudio = 'mwac'
} iChatCapabilities;

typedef enum {
	iChatScreenSharingNone = 'ssns',
	iChatScreenSharingLocalScreen = 'ssls',
	iChatScreenSharingRemoteScreen = 'ssrs'
} iChatScreenSharing;

typedef enum {
	iChatServiceTypeAIM = 'saim',
	iChatServiceTypeBonjour = 'ssub',
	iChatServiceTypeJabber = 'sjab'
} iChatServiceType;

typedef enum {
	iChatDirectionIncoming = 'FTic',
	iChatDirectionOutgoing = 'FTog'
} iChatDirection;

typedef enum {
	iChatTransferStatusPreparing = 'FTsp',
	iChatTransferStatusWaiting = 'FTsw',
	iChatTransferStatusTransferring = 'FTsg',
	iChatTransferStatusFinalizing = 'FTsz',
	iChatTransferStatusFinished = 'FTsf',
	iChatTransferStatusFailed = 'FTse'
} iChatTransferStatus;

typedef enum {
	iChatAvTypeAudio = 'ICAa',
	iChatAvTypeVideo = 'ICAv'
} iChatAvType;

typedef enum {
	iChatChatTypeInstantMessage = 'ICim',
	iChatChatTypeDirectInstantMessage = 'ICdi',
	iChatChatTypeChatRoom = 'ICcr'
} iChatChatType;

typedef enum {
	iChatJoinStateNotJoined = 'ICJc',
	iChatJoinStateJoining = 'ICJg',
	iChatJoinStateJoined = 'ICJj'
} iChatJoinState;

typedef enum {
	iChatAvConnectionStatusInvited = 'ICAi',
	iChatAvConnectionStatusWaiting = 'ICAw',
	iChatAvConnectionStatusConnecting = 'ICAx',
	iChatAvConnectionStatusConnected = 'ICAc',
	iChatAvConnectionStatusEnded = 'ICAn'
} iChatAvConnectionStatus;



/*
 * Standard Suite
 */

// A scriptable object.
@interface iChatItem : SBObject

@property (copy) NSDictionary *properties;  // All of the object's properties.

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end

// The application's top-level scripting object.
@interface iChatApplication : SBApplication

- (SBElementArray *) documents;
- (SBElementArray *) windows;

@property (copy, readonly) NSString *name;  // The name of the application.
@property (readonly) BOOL frontmost;  // Is this the frontmost (active) application?
@property (copy, readonly) NSString *version;  // The version of the application.

- (void) open:(NSArray *)x;  // Open a document.
- (void) print:(NSURL *)x;  // Print an object.
- (void) quitSaving:(iChatSaveOptions)saving;  // Quit the application.
- (void) invite:(NSArray *)x to:(id)to withMessage:(NSString *)withMessage;  // Invites a buddy to join an existing chat.
- (void) logIn;  // Log in to the specified service, or all services if none is specified. If the account password is not in the keychain the user will be prompted to enter one.
- (void) logOut;  // Logs out of a service, or all services if none is specified.
- (void) send:(id)x to:(id)to;  // Sends a message or file to a buddy or to a chat.
- (void) storeRecentPicture;  // Stores the currently set buddy picture into your recent pictures.
- (void) showChatChooserFor:(iChatBuddy *)for_;  // displays a dialog in iChat to start a new chat with the specified buddy

@end

// A color.
@interface iChatColor : SBObject

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end

// An iChat document.
@interface iChatDocument : SBObject

@property (copy, readonly) NSString *name;  // The document's name.
@property (readonly) BOOL modified;  // Has the document been modified since the last save?
@property (copy, readonly) NSURL *file;  // The document's location on disk.

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end

// A window.
@interface iChatWindow : SBObject

@property (copy, readonly) NSString *name;  // The full title of the window.
- (NSInteger) id;  // The unique identifier of the window.
@property NSInteger index;  // The index of the window, ordered front to back.
@property NSRect bounds;  // The bounding rectangle of the window.
@property (readonly) BOOL closeable;  // Whether the window has a close box.
@property (readonly) BOOL minimizable;  // Whether the window can be minimized.
@property BOOL minimized;  // Whether the window is currently minimized.
@property (readonly) BOOL resizable;  // Whether the window can be resized.
@property BOOL visible;  // Whether the window is currently visible.
@property (readonly) BOOL zoomable;  // Whether the window can be zoomed.
@property BOOL zoomed;  // Whether the window is currently zoomed.
@property (copy, readonly) iChatDocument *document;  // The document whose contents are being displayed in the window.

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end



/*
 * Text Suite
 */

// Rich (styled) text
@interface iChatRichText : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property double size;  // The size in points of the first character.

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end

// This subdivides the text into characters.
@interface iChatCharacter : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end

// This subdivides the text into paragraphs.
@interface iChatParagraph : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end

// This subdivides the text into words.
@interface iChatWord : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end

// This subdivides the text into chunks that all have the same attributes.
@interface iChatAttributeRun : SBObject

- (SBElementArray *) characters;
- (SBElementArray *) paragraphs;
- (SBElementArray *) words;
- (SBElementArray *) attributeRuns;
- (SBElementArray *) attachments;

@property (copy) NSColor *color;  // The color of the first character.
@property (copy) NSString *font;  // The name of the font of the first character.
@property NSInteger size;  // The size in points of the first character.

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.

@end

// Represents an inline text attachment. This class is used mainly for make commands.
@interface iChatAttachment : iChatRichText

@property (copy, readonly) NSURL *file;  // The path to the file for the attachment


@end



/*
 * iChat Suite
 */

// iChat application.
@interface iChatApplication (IChatSuite)

- (SBElementArray *) buddies;
- (SBElementArray *) services;
- (SBElementArray *) fileTransfers;
- (SBElementArray *) chats;
- (SBElementArray *) textChats;
- (SBElementArray *) audioChats;
- (SBElementArray *) videoChats;

@property (readonly) NSInteger idleTime;  // Time in seconds that I have been idle.
@property (copy) NSImage *image;  // My image as it appears in all services.
@property (copy) NSString *statusMessage;  // My status message, visible to other people while I am online.
@property iChatMyStatus status;  // My status on all services.
@property (copy) iChatAudioChat *activeAvChat;  // The currently active audio or video chat.

@end

// A buddy on a service.
@interface iChatBuddy : iChatItem

- (NSString *) id;  // The buddy's service and handle. For example: AIM:JohnDoe007
@property (copy, readonly) iChatService *service;  // The service on which this buddy exists.
@property (copy, readonly) NSString *name;  // The buddy's name as it appears in the buddy list.
@property (copy, readonly) NSString *handle;  // The buddy's online account name.
@property (readonly) iChatAccountStatus status;  // The buddy's current status.
@property (copy, readonly) NSString *statusMessage;  // The buddy's current status message.
@property (readonly) NSInteger idleTime;  // The time in seconds the buddy has been idle.
@property (copy, readonly) NSArray *capabilities;  // The buddy's messaging capabilities.
@property (copy, readonly) NSImage *image;  // The buddy's custom image.
@property (copy, readonly) NSString *firstName;  // The first name from this buddy's Address Book card, if available
@property (copy, readonly) NSString *lastName;  // The last name from this buddy's Address Book card, if available
@property (copy, readonly) NSString *fullName;  // The full name from this buddy's Address Book card, if available


@end

// A service that can be logged in from this system
@interface iChatService : iChatItem

- (SBElementArray *) buddies;
- (SBElementArray *) chats;

- (NSString *) id;  // A guid identifier for this service.
@property (copy) NSString *name;  // The name of this service as defined in Account preferences description field
@property BOOL enabled;  // Is the service enabled?
@property (readonly) iChatConnectionStatus status;  // The connection status for this account.
@property (readonly) iChatServiceType serviceType;  // The type of protocol for this service

- (void) logIn;  // Log in to the specified service, or all services if none is specified. If the account password is not in the keychain the user will be prompted to enter one.
- (void) logOut;  // Logs out of a service, or all services if none is specified.

@end

// An audio, video, or text chat.
@interface iChatChat : SBObject

- (NSString *) id;  // A guid identifier for this chat.
@property (copy, readonly) iChatService *service;  // The service which is participating in this chat.
@property (copy, readonly) NSArray *participants;  // Other participants of this chat. This property may be specified at time of creation.
@property (readonly) BOOL secure;  // Is this chat secure?
@property (readonly) BOOL invitation;  // Is this an invitation to a chat?
@property (readonly) BOOL active;  // Is this chat currently active?
@property (copy, readonly) NSDate *started;  // The date on which this chat started.
@property (copy, readonly) NSDate *updated;  // The date when this chat was last updated.

- (void) closeSaving:(iChatSaveOptions)saving savingIn:(NSURL *)savingIn;  // Close a document.
- (void) saveIn:(NSURL *)in_ as:(NSString *)as;  // Save a document.
- (void) delete;  // Delete an object.
- (SBObject *) duplicateTo:(SBObject *)to withProperties:(NSDictionary *)withProperties;  // Copy object(s) and put the copies at a new location.
- (BOOL) exists;  // Verify if an object exists.
- (SBObject *) moveTo:(SBObject *)to;  // Move object(s) to a new location.
- (void) accept;  // Accepts an incoming text, audio, or video chat invitation, or file transfer
- (void) decline;  // Declines an incoming text, audio, or video chat invitation, or file transfer

@end

// A text chat.
@interface iChatTextChat : iChatChat

@property (copy, readonly) NSString *subject;  // The subject of this chat, if available.
@property (copy, readonly) NSString *invitationMessage;  // An invitation message. This may only be specified at the time of creation. This message will be sent to chat participants when the chat is created.
@property (readonly) iChatJoinState joinState;  // How you are joined to this chat
@property (copy, readonly) NSString *name;  // The address or room name of this chat. This property may be specified at time of creation.
@property (readonly) iChatChatType chatType;  // The type of this chat.


@end

// An audio or video chat.
@interface iChatAudioChat : iChatChat

@property (readonly) iChatScreenSharing screenSharing;  // Type of screen sharing session taking place within this chat.
@property BOOL muted;  // Is the chat muted?
@property (readonly) iChatAvConnectionStatus avConnectionStatus;  // The connection state for this av chat.

- (void) requestRecording;  // Sends a recording request to all participants of an audio or video chat. Recording will not start until all participants have agreed to allow recording.
- (void) stopRecording;  // Ends recording of an audio or video chat.

@end

@interface iChatVideoChat : iChatAudioChat

@property BOOL paused;  // Is the chat paused?
@property BOOL showingFullScreen;  // Is the chat being displayed in full screen mode?
@property BOOL showingLocalVideo;  // Is the local video preview being displayed?

- (void) takeSnapshot;  // Takes a snapshot of a video chat and saves it to a desktop.

@end

// A file being sent or received
@interface iChatFileTransfer : iChatItem

- (NSString *) id;  // The guid for this file transfer
@property (copy, readonly) NSString *name;  // The name of this file
@property (copy, readonly) NSURL *file;  // The local path to this file transfer
@property (readonly) iChatDirection direction;  // The direction in which this file is being sent
@property (copy, readonly) iChatService *service;  // The service on which this file transfer is taking place
@property (copy, readonly) iChatBuddy *buddy;  // The account participating in this file transfer
@property (readonly) BOOL secure;  // Is this file transfer secure?
@property (readonly) NSInteger fileSize;  // The total size in bytes of the completed file transfer
@property (readonly) NSInteger fileProgress;  // The number of bytes that have been transferred
@property (readonly) iChatTransferStatus transferStatus;  // The current status of this file transfer
@property (copy, readonly) NSDate *started;  // The date that this file transfer started

- (void) accept;  // Accepts an incoming text, audio, or video chat invitation, or file transfer
- (void) decline;  // Declines an incoming text, audio, or video chat invitation, or file transfer

@end

