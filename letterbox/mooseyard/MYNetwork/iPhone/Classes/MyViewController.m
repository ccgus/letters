
#import "MyViewController.h"
#import "BLIP.h"


@implementation MyViewController

@synthesize textField;
@synthesize label;
@synthesize string;

- (void)viewDidLoad {
    // When the user starts typing, show the clear button in the text field.
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    
    label.text = @"Opening listener socket...";

    _listener = [[BLIPListener alloc] initWithPort: 12345];
    _listener.delegate = self;
    _listener.pickAvailablePort = YES;
    _listener.bonjourServiceType = @"_blipecho._tcp";
    [_listener open];
}


- (void)updateString {
	
	// Store the text of the text field in the 'string' instance variable.
	self.string = textField.text;
    // Set the text of the label to the value of the 'string' instance variable.
	label.text = self.string;
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	// When the user presses return, take focus away from the text field so that the keyboard is dismissed.
	if (theTextField == textField) {
		[textField resignFirstResponder];
        // Invoke the method that changes the greeting.
        [self updateString];
	}
	return YES;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Dismiss the keyboard when the view outside the text field is touched.
    [textField resignFirstResponder];
    // Revert the text field to the previous value.
    [super touchesBegan:touches withEvent:event];
}


- (void)dealloc {
	[textField release];
	[label release];
    
    [_listener close];
    [_listener release];

	[super dealloc];
}


#pragma mark BLIP Listener Delegate:


- (void) listenerDidOpen: (TCPListener*)listener
{
    label.text = [NSString stringWithFormat: @"Listening on port %i",listener.port];
}

- (void) listener: (TCPListener*)listener failedToOpen: (NSError*)error
{
    label.text = [NSString stringWithFormat: @"Failed to open listener on port %i: %@",
                  listener.port,error];
}

- (void) listener: (TCPListener*)listener didAcceptConnection: (TCPConnection*)connection
{
    label.text = [NSString stringWithFormat: @"Accepted connection from %@",
                  connection.address];
    connection.delegate = self;
}

- (void) connection: (TCPConnection*)connection failedToOpen: (NSError*)error
{
    label.text = [NSString stringWithFormat: @"Failed to open connection from %@: %@",
                  connection.address,error];
}

- (void) connection: (BLIPConnection*)connection receivedRequest: (BLIPRequest*)request
{
    NSString *message = [[NSString alloc] initWithData: request.body encoding: NSUTF8StringEncoding];
    label.text = [NSString stringWithFormat: @"Echoed:\n“%@”",message];
    [request respondWithData: request.body contentType: request.contentType];
	[message release];
}

- (void) connectionDidClose: (TCPConnection*)connection;
{
    label.text = [NSString stringWithFormat: @"Connection closed from %@",
                  connection.address];
}


@end
