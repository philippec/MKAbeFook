/*
 
 MMKLoginViewController.m
 Mobile MKAbeFook

 Created by Mike on 3/28/08.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
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
	UIBarButtonItem *leftBarButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:_delegate action:@selector(getAuthSession)] autorelease];
	
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


-(id)webView
{
	return _loginWebView;
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
