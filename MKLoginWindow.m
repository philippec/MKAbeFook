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
#import "NSXMLElementAdditions.h"

#import "SBJSON.h"
#import "NSString+SBJSON.h"
#import "MKFacebookSession.h"

@implementation MKLoginWindow
@synthesize _loginWindowIsSheet;
@synthesize _delegate;

-(id)init
{
	self = [super init];
	self._loginWindowIsSheet = NO;
	self._delegate = nil;
	path = [[NSBundle bundleForClass:[self class]] pathForResource:@"LoginWindow" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	return self;
}



-(void)awakeFromNib
{
	//TODO: the window won't load correctly when we try to grant permissions unless we do this... i don't understand why...
	//NSRect frame = [[self window] frame];
	//[[self window] setFrame:frame display:YES animate:YES];
	
	[loginWebView setPolicyDelegate:self];
	[loadingWebViewProgressIndicator bind:@"value" toObject:loginWebView withKeyPath:@"estimatedProgress" options:nil];
	[self displayLoadingWindowIndicator];
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
	
	DLog(@"loading url: %@", [loginURL description]);
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginURL];
	
	//[[[loginWebView mainFrame] frameView] setAllowsScrolling:NO];	
	[[loginWebView mainFrame] loadRequest:request];
	//[self hideLoadingWindowIndicator];
}


-(IBAction)closeWindow:(id)sender 
{
	if(self._loginWindowIsSheet == YES)
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
	[[self window] setFrame:rect display:YES animate:YES];
}


- (void)windowWillClose:(NSNotification *)aNotification
{
	DLog(@"windowWillClose: was called");

	[self autorelease];
}

-(void)dealloc
{
	[_delegate release];
	[loginWebView stopLoading:nil];
	[loadingWebViewProgressIndicator unbind:@"value"];
	[super dealloc];
}



#pragma mark WebView Delegate Methods
- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[loadingWebViewProgressIndicator setHidden:NO];
}

-(void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[self hideLoadingWindowIndicator];
	NSURL *url = [[[frame dataSource] mainResource] URL];
	NSString *urlString = [url description];
	DLog(@"current URL: %@", urlString);
	
	//we need to do some extra things when a user logs in successfully
	if([urlString hasPrefix:@"http://www.facebook.com/connect/login_success.html"])
	{
		//display a custom successful login message that doesn't require an external host
		//TODO: let developers provide their own local success html file without modifying the framework default
		NSString *fwp = [[NSBundle mainBundle] privateFrameworksPath];
		NSString *next = [NSString stringWithFormat:@"%@/MKAbeFook.framework/Resources/login_success.html", fwp];
		[self loadURL:[NSURL URLWithString:next]];
		
		DLog(@"user was successfully logged in");
		//unfortunately we can't call parametersString on the url that facebook returns for us to load (not sure why...)
		//instead we'll break up the string at the = and load everything after the = as the JSON object
		NSArray *array = [urlString componentsSeparatedByString:@"="];
		if([array objectAtIndex:1] != nil)
		{
			NSString *decodedParameters = [[array objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			DLog(@"parameters: %@", decodedParameters);
			id sessionInfo = [decodedParameters JSONValue];
			DLog(@"session info: %@", [sessionInfo description]);
			[[MKFacebookSession sharedMKFacebookSession] saveSession:sessionInfo];
		}else {
			DLog(@"failed to save session info returned by facebook....");
			
		}
		
		//finally call userLoginSuccessful
		if([self._delegate respondsToSelector:@selector(userLoginSuccessful)])
			[self._delegate performSelector:@selector(userLoginSuccessful)];
	}
	
	
	
	if([urlString hasPrefix:@"http://www.facebook.com/connect/login_failure.html"])
	{
		//display a custom failed login message that doesn't require an external host
		//TODO: let developers provide their own local success html file without modifying the framework default
		NSString *fwp = [[NSBundle mainBundle] privateFrameworksPath];
		NSString *next = [NSString stringWithFormat:@"%@/MKAbeFook.framework/Resources/login_failed.html", fwp];
		[self loadURL:[NSURL URLWithString:next]];
		
	}
	
	[loadingWebViewProgressIndicator setHidden:YES];
}

//allow external links to open in the default browser
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
