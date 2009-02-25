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
#import "MKFacebookRequest.h"

@implementation MKLoginWindow
-(id)initWithDelegate:(id)aDelegate withSelector:(SEL)aSelector
{
	self = [super init];
	_delegate = aDelegate;
	_selector = aSelector;
	_loginWindowIsSheet = NO;
	path = [[NSBundle bundleForClass:[self class]] pathForResource:@"LoginWindow" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	_shouldAutoGrantOfflinePermissions = NO;
	_authTokenRequired = YES;
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
	_shouldAutoGrantOfflinePermissions = NO;
	_authTokenRequired = YES;
	//NSRect frame = [[self window] frame];
	//frame.size.height = 480;
	//[[self window] setFrame:frame display:YES animate:YES];
	//NSRect visibleArea = NSMakeRect(0, 0, 626, 436);
	//[[[loginWebView mainFrame] webView] setFrame:visibleArea];
	return self;
}

-(void)awakeFromNib
{
	//TODO: the window won't load correctly when we try to grant permissions unless we do this... i don't understand why...
	//NSRect frame = [[self window] frame];
	//[[self window] setFrame:frame display:YES animate:YES];
	
	[loginWebView setPolicyDelegate:self];
	[loadingWebViewProgressIndicator bind:@"value" toObject:loginWebView withKeyPath:@"estimatedProgress" options:nil];
}

-(void)displayLoadingWindowIndicator
{
	NSLog(@"got here...");
	[loadingWindowProgressIndicator setHidden:NO];
	[loadingWindowProgressIndicator startAnimation:nil];
}

-(void)hideLoadingWindowIndicator
{
	NSLog(@"then we got here...");
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
	
	NSLog(@"loading url: %@", [loginURL description]);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginURL];
	//[request setMainDocumentURL:[NSURL URLWithString:@"http://www.facebook.com"]];

	//NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	//NSLog(@"cookies: %@", [[cookies cookiesForURL:loginURL] description]);
	
	[[[loginWebView mainFrame] frameView] setAllowsScrolling:NO];	
	[[loginWebView mainFrame] loadRequest:request];
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
	//if auto grant permissions is YES the auth token request SHOULD be handled by webview did finish loading delegate method in this class
	if(_authTokenRequired == YES)
	{
		if(_selector != nil && [_delegate respondsToSelector:_selector])
			[_delegate performSelector:_selector];		
	}

	[self autorelease];
}

-(void)dealloc
{
	[super dealloc];
}


-(void)setAutoGrantOfflinePermissions:(BOOL)aBool
{
	_shouldAutoGrantOfflinePermissions = aBool;
}
-(BOOL)shouldAutoGrantOfflinePermissions
{
	return _shouldAutoGrantOfflinePermissions;
}


#pragma mark WebView Delegate Methods
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[loadingWebViewProgressIndicator setHidden:NO];
}

-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	NSString *urlString = [[[[frame dataSource] mainResource] URL] description];
	NSLog(@"current URL: %@", urlString);

	//TODO: this stuff...
	//check the current url that comes back.  if it's the one that looks like it means the user logged in successfully then try to send a request to complete the authentication.
	//in this case we KNOW _delegate is the MKFacebook object, but this isn't a good way to do this.
	NSString *loginSuccessfulString = [NSString stringWithFormat:@"https://ssl.facebook.com/desktopapp.php?api_key=%@&popup", [_delegate apiKey]];
	if(_shouldAutoGrantOfflinePermissions == YES && [urlString isEqualToString:loginSuccessfulString])
	{
		//send auth token request
		NSLog(@"facebook web login successful");
		MKFacebookRequest *request = [MKFacebookRequest requestUsingFacebookConnection:_delegate delegate:self selector:@selector(handleAuthTokenRequest:)];
		NSMutableDictionary *parameters = [[[NSMutableDictionary alloc] init] autorelease];
		[parameters setValue:@"facebook.auth.getSession" forKey:@"method"];
		[parameters setValue:[_delegate authToken] forKey:@"auth_token"];
		[request setParameters:parameters];
		[request sendRequest];
	}
	
	[loadingWebViewProgressIndicator setHidden:YES];
}

//we get here immediately after the user logs into facebook successfully
-(void)handleAuthTokenRequest:(id)response
{	
	[_delegate facebookResponseReceived:response];
	if([_delegate userLoggedIn] == YES && _shouldAutoGrantOfflinePermissions == YES)
	{
		_authTokenRequired = NO;
		//start process of extending each permission....
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/authorize.php?api_key=%@&v=%@&ext_perm=offline_access&popup=1", [_delegate apiKey], MKFacebookAPIVersion]];
		[self loadURL:url];
	}	
}



- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id < WebPolicyDecisionListener >)listener
{
	if ([[actionInformation objectForKey:WebActionNavigationTypeKey] intValue] != WebNavigationTypeOther) {
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
	else
		[listener use];
}

@end
