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


@implementation MMKLoginViewController
-(id)initWithDelegate:(id)aDelegate withSelector:(SEL)aSelector
{
	self = [super init];
	_delegate = aDelegate;
	_selector = aSelector;
	self.title = @"Login";

	return self;
}

-(void)loadView
{
	/*
	UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[leftButton setTitle:@"Back To App" forState:UIControlStateNormal];
	[leftButton addTarget:_delegate action:@selector(getAuthSession) forControlEvents:UIControlEventTouchUpInside];
	 */
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


-(void)dealloc
{
	[_loginWebView release];
	[super dealloc];
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
	[_activityIndicator startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
	[_activityIndicator stopAnimating];
}


@end
