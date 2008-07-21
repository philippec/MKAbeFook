//
//  MKErrorWindow.m
//  MKAbeFook
//
//  Created by Mike Kinney on 7/21/08.
//

#import "MKErrorWindow.h"


@implementation MKErrorWindow

+(MKErrorWindow *)errorWindowWithTitle:(NSString *)title message:(NSString *)message details:(NSString *)details
{
	return [[MKErrorWindow alloc] initWithTitle:title message:message details:details]; 
}

-(MKErrorWindow *)initWithTitle:(NSString *)title message:(NSString *)message details:(NSString *)details
{
	self = [super init];
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"ErrorWindow" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	_errorTitle = [title retain];
	_errorMessage = [message retain];
	
	if(details != nil)
		_errorDetails = [details retain];
	else
		_errorDetails = nil;
	
	
	return self;
}

-(void)awakeFromNib
{
	NSFont *font = [NSFont boldSystemFontOfSize:14.0];
	NSDictionary *attrsDict = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	NSAttributedString *title = [[[NSAttributedString alloc] initWithString:_errorTitle attributes:attrsDict] autorelease];
	[errorTitle setAttributedStringValue:title];
	[errorMessage setStringValue:_errorMessage];
	[errorImage setImage:[NSApp applicationIconImage]];
	if(_errorDetails != nil)
	{
		[detailsButton setHidden:NO];
	}
}

-(void)dealloc
{
	[super dealloc];
}

-(void)display
{
	[[self window] center];
	[[self window] makeKeyAndOrderFront:nil];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self autorelease];
}

-(IBAction)okButton:(id)sender
{
	//TODO: find a better way to close this
	[[self window] orderOut:nil];
	[self windowWillClose:nil];
}

-(IBAction)detailsButton:(id)sender
{
	[errorDetails setString:_errorDetails];
	int newWindowHeight = 200;
	NSRect currentRect = [[self window] frame];
	NSRect rect = NSMakeRect(currentRect.origin.x, currentRect.origin.y - newWindowHeight, currentRect.size.width, currentRect.size.height + newWindowHeight);
	//[[self window] center];
	[[self window] setFrame:rect display:YES animate:YES];
	[[[errorDetails superview] superview] setHidden:NO];
	[errorDetails setHidden:NO];
	[detailsButton setEnabled:NO];
	[detailsButton setHidden:YES];
}

@end
