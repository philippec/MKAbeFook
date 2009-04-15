/*
 
 MMKLoginViewController.m
 Mobile MKAbeFook

 Created by Mike on 3/28/08.

 Copyright (c) 2009, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "MMKLoginViewController.h"
#import "MMKFacebookRequest.h"
#import "CXMLDocument.h"


@implementation MMKLoginViewController
-(id)initWithDelegate:(id)aDelegate withSelector:(SEL)aSelector
{
	self = [super init];
	_delegate = aDelegate;
	_selector = aSelector;
	self.title = @"Login";
	_shouldAutoGrantOfflinePermissions = NO;
	return self;
}

-(void)loadView
{

	UIBarButtonItem *leftBarButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:_delegate action:_selector] autorelease];
	
	self.navigationItem.leftBarButtonItem = leftBarButton;
	//[leftButton release];
	
	_activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];

	UIBarButtonItem *activityView = [[[UIBarButtonItem alloc] initWithCustomView:_activityIndicator] autorelease];
	self.navigationItem.rightBarButtonItem = activityView;
	
	_loginWebView = [[UIWebView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	[_loginWebView setDelegate:self];
	[_loginWebView setScalesPageToFit:YES];
	self.view = _loginWebView;
}


-(void)loadURL:(NSURL *)loginURL
{
	[_loginWebView loadRequest:[NSURLRequest requestWithURL:loginURL]];
}


-(void)setAutoGrantOfflinePermissions:(BOOL)aBool
{
	_shouldAutoGrantOfflinePermissions = aBool;
}
-(BOOL)shouldAutoGrantOfflinePermissions
{
	return _shouldAutoGrantOfflinePermissions;
}


-(void)dealloc
{
	[_loginWebView release];
	[super dealloc];
}

#pragma mark WebView Delegate Methods
-(void)webViewDidStartLoad:(UIWebView *)webView
{
	[_activityIndicator startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{

	NSString *urlString = [[webView.request URL] description];
	NSLog(@"current URL: %@", urlString);
	
	//TODO: this stuff...
	//check the current url that comes back.  if it's the one that looks like it means the user logged in successfully then try to send a request to complete the authentication.
	//in this case we KNOW _delegate is the MKFacebook object, but this isn't a good way to do this. compile warning is normal because apiKey is a private method
	
	//this is where the user goes if it is the FIRST time they login and authenticate to an application
	NSString *loginSuccessfulFirstAuthorized = [NSString stringWithFormat:@"http://www.facebook.com/desktopapp.php?api_key=%@&popup", [_delegate apiKey]];
	
	//this is where the user goes if they have already authorized the application
	NSString *loginSuccessfulAlreadyAuthorized = [NSString stringWithFormat:@"https://ssl.facebook.com/desktopapp.php?api_key=%@&popup", [_delegate apiKey]];
	
	if(_shouldAutoGrantOfflinePermissions == YES && ([urlString isEqualToString:loginSuccessfulFirstAuthorized] || [urlString isEqualToString:loginSuccessfulAlreadyAuthorized]))
	{
		
		//send auth token request
		NSLog(@"facebook web login successful");
		MMKFacebookRequest *request = [MMKFacebookRequest requestUsingFacebookConnection:_delegate delegate:self selector:@selector(handleAuthTokenRequest:)];
		NSMutableDictionary *parameters = [[[NSMutableDictionary alloc] init] autorelease];
		[parameters setValue:@"facebook.auth.getSession" forKey:@"method"];
		[parameters setValue:[_delegate authToken] forKey:@"auth_token"];
		[request displayLoadingSheet:NO];
		[request setParameters:parameters];
		
		[request sendRequest];
		
		[_activityIndicator startAnimating];
		return;
	}
	
	[_activityIndicator stopAnimating];
}

#pragma mark MKFacebookRequest Delegate Methods
-(void)handleAppPermissionRequest:(CXMLDocument *)response
{
	NSLog(@"received app permission response %@", [[response rootElement] description]);
	if([[[response rootElement] stringValue] isEqualToString:@"0"])
	{
		//if user has not already granted offline permission display the page to do so
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/authorize.php?api_key=%@&v=%@&ext_perm=offline_access&popup=1", [_delegate apiKey], MMKFacebookAPIVersion]];
		[self loadURL:url];			
	}
	
	[_activityIndicator stopAnimating];
	
}


//we get here immediately after the user logs into facebook successfully
-(void)handleAuthTokenRequest:(id)response
{
	[_activityIndicator stopAnimating];
	//the MKFacebook class is already set up to verify token responses
	[_delegate facebookResponseReceived:response];
	NSLog(@"auto grant : %i", [[NSNumber numberWithBool:_shouldAutoGrantOfflinePermissions] intValue]);
	if([_delegate userLoggedIn] == YES && _shouldAutoGrantOfflinePermissions == YES)
	{
		_authTokenRequired = NO;
		
		//send request to see if user already has granted offline access
		NSLog(@"requesting app permission");
		MMKFacebookRequest *request = [MMKFacebookRequest requestUsingFacebookConnection:_delegate delegate:self selector:@selector(handleAppPermissionRequest:)];
		NSMutableDictionary *parameters = [[[NSMutableDictionary alloc] init] autorelease];
		[parameters setValue:@"facebook.users.hasAppPermission" forKey:@"method"];
		[parameters setValue:[_delegate uid] forKey:@"uid"];
		[parameters setValue:@"offline_access" forKey:@"ext_perm"];
		[request displayLoadingSheet:NO];
		[request setParameters:parameters];
		[request sendRequest];
		[_activityIndicator startAnimating];
	}
	//no token, what should we do?
}


//if the auth token request receives an error from facebook do something ere
-(void)facebookErrorResponseReceived:(id)errorResponse
{
	[_activityIndicator stopAnimating];
	
}

//if the auth token request encounters a network error do something here
-(void)facebookRequestFailed:(id)error
{
	[_activityIndicator stopAnimating];
	
}

@end
