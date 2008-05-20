/*
 
 LoginWindow.m
 MKAbeFook

 Created by Mike on 10/11/06.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import "MKLoginWindow.h"


@implementation MKLoginWindow
-(id)initWithDelegate:(id)aDelegate withSelector:(SEL)aSelector
{
	self = [super init];
	_delegate = aDelegate;
	_selector = aSelector;
	
	path = [[NSBundle bundleForClass:[self class]] pathForResource:@"LoginWindow" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	NSRect visibleArea =  NSMakeRect(0, 0, 626, 426);
	[[[loginWebView mainFrame] webView] setFrame:visibleArea];
	
	return self;
}

-(id)initForSheetWithDelegate:(id)aDelegate withSelector:(SEL)aSelector
{
	_delegate = aDelegate;
	_selector = aSelector;
	path = [[NSBundle bundleForClass:[self class]] pathForResource:@"LoginWindow" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	NSRect frame = [[self window] frame];
	frame.size.height = 480;
	[[self window] setFrame:frame display:YES animate:YES];
	[closeSheetButton setHidden:NO];
	
	NSRect visibleArea = NSMakeRect(0, 0, 626, 436);
	[[[loginWebView mainFrame] webView] setFrame:visibleArea];
	return self;
}
-(void)loadURL:(NSURL *)loginURL
{
	[loginWebView setMaintainsBackForwardList:NO];
	[loginWebView setFrameLoadDelegate:self];
	/*
	NSRect visibleArea;
	//make the view smaller so the close sheet button fits better
	if(webViewForSheet)
	{
		visibleArea = NSMakeRect(0, 0, 626, 426);

	}else
	{
		visibleArea = NSMakeRect(0, 0, 626, 436);	
	}
	[[[loginWebView mainFrame] webView] setFrame:visibleArea];
	*/
	
	NSLog(@"loading url: %@", [loginURL description]);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginURL];
	[request setMainDocumentURL:[NSURL URLWithString:@"http://www.facebook.com"]];

	NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSLog(@"cookies: %@", [[cookies cookiesForURL:loginURL] description]);
	
	[[[loginWebView mainFrame] frameView] setAllowsScrolling:NO];	
	[[loginWebView mainFrame] loadRequest:request];
	[[loginWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:loginURL]];
}


-(IBAction)closeSheet:(id)sender 
{
	[[self window] orderOut:sender];
	[NSApp endSheet:[self window] returnCode:1];
	//[[self window] performClose:sender];
	[self windowWillClose:nil];
}

-(void)setWindowSize:(NSSize)windowSize
{

	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect rect = NSMakeRect(screenRect.size.width * .25, screenRect.size.height * .25, windowSize.width, windowSize.height);
	//[[[loginWebView mainFrame] webView] setFrame:rect];
	//[[[loginWebView mainFrame] webView] setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[[self window] center];
	[[self window] setFrame:rect display:YES animate:YES];
}


- (void)windowWillClose:(NSNotification *)aNotification
{
	if(_selector != nil && [_delegate respondsToSelector:_selector])
		[_delegate performSelector:_selector];

	[self autorelease];
}

-(void)dealloc
{
	[super dealloc];
}


-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	NSLog([[[loginWebView mainFrame] DOMDocument] description]);
	NSLog(@"source: %@", [[[[loginWebView mainFrame] dataSource] representation] documentSource]);
}

@end
