//
//  LoginWindow.m
//  MKAbeFook
//
//  Created by Mike on 10/11/06.
/*
 Copyright (c) 2009, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "MKLoginWindow.h"


@implementation MKLoginWindow
-(id)initWithDelegate:(id)aDelegate withSelector:(SEL)aSelector
{
	self = [super init];
	_delegate = aDelegate;
	_selector = aSelector;
	_loginWindowIsSheet = NO;
	path = [[NSBundle bundleForClass:[self class]] pathForResource:@"LoginWindow" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	//NSRect visibleArea =  NSMakeRect(0, 0, 626, 426);
	//[[[loginWebView mainFrame] webView] setFrame:visibleArea];
	return self;
}


-(id)initForSheetWithDelegate:(id)aDelegate withSelector:(SEL)aSelector
{
	_delegate = aDelegate;
	_selector = aSelector;
	_loginWindowIsSheet = YES;
	path = [[NSBundle bundleForClass:[self class]] pathForResource:@"LoginWindow" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	//NSRect frame = [[self window] frame];
	//frame.size.height = 480;
	//[[self window] setFrame:frame display:YES animate:YES];
	//NSRect visibleArea = NSMakeRect(0, 0, 626, 436);
	//[[[loginWebView mainFrame] webView] setFrame:visibleArea];
	return self;
}

-(void)awakeFromNib
{
	[loadingWebViewProgressIndicator bind:@"value" toObject:loginWebView withKeyPath:@"estimatedProgress" options:nil];
}

-(void)displayLoadingWindowIndicator
{
	[loadingWindowProgressIndicator setHidden:NO];
	[loadingWindowProgressIndicator startAnimation:nil];
}

-(void)hideLoadingWindowIndicator
{
	[loadingWindowProgressIndicator stopAnimation:nil];
	[loadingWindowProgressIndicator setHidden:YES];
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
	
	//NSLog(@"loading url: %@", [loginURL description]);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginURL];
	//[request setMainDocumentURL:[NSURL URLWithString:@"http://www.facebook.com"]];

	//NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	//NSLog(@"cookies: %@", [[cookies cookiesForURL:loginURL] description]);
	
	[[[loginWebView mainFrame] frameView] setAllowsScrolling:NO];	
	[[loginWebView mainFrame] loadRequest:request];
	[[loginWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:loginURL]];
}


-(IBAction)closeWindow:(id)sender 
{
	if(_loginWindowIsSheet == YES)
	{
		[[self window] orderOut:sender];
		[NSApp endSheet:[self window] returnCode:1];
		[self windowWillClose:nil];		
	}else
	{
		[[self window] performClose:sender];
	}
}

-(void)setWindowSize:(NSSize)windowSize
{

	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect rect = NSMakeRect(screenRect.size.width * .15, screenRect.size.height * .15, windowSize.width, windowSize.height);
	//[[[loginWebView mainFrame] webView] setFrame:rect];
	//[[[loginWebView mainFrame] webView] setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	//[[self window] center];
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

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[loadingWebViewProgressIndicator setHidden:NO];
}

-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	//NSLog([[[loginWebView mainFrame] DOMDocument] description]);
	//NSLog(@"source: %@", [[[[loginWebView mainFrame] dataSource] representation] documentSource]);
	[loadingWebViewProgressIndicator setHidden:YES];
}

@end
