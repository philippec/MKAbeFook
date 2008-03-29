//
//  Mobile_MKAbeFookAppDelegate.m
//  Mobile MKAbeFook
//
//  Created by Mike Kinney on 3/28/08.
//  Copyright Mike Kinney 2008. All rights reserved.
//

#import "Mobile_MKAbeFookAppDelegate.h"
@implementation Mobile_MKAbeFookAppDelegate

@synthesize window;


- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	// Create window
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
	_frontView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	_text = [[UILabel alloc] initWithFrame:CGRectMake(50, 50, 300, 20)];
	_text.text = @"Hello MMKAbeFook";
	[_frontView addSubview:_text];

	
	
	
	_loginButton = [UIButton buttonWithType:UIButtonTypeNavigation];
	[_loginButton setTitle:@"Login" forStates:UIControlStateNormal];
	[_loginButton addTarget:self action:@selector(showLogin) forControlEvents:UIControlEventTouchUpInside];
	_loginButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	_loginButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	_loginButton.center = CGPointMake([[UIScreen mainScreen] bounds].size.width / 2, [[UIScreen mainScreen] bounds].size.height /2 - 100);
	[_frontView addSubview:_loginButton];

	[self.window addSubview:_frontView];
	
	// Show window
	[window makeKeyAndVisible];
	
	_facebookConnection = [[MMKFacebook facebookWithAPIKey:@"2c05304285010949050742956e95db9a" 
												withSecret:@"c656ff9157b2d9d93c2c72cf9607044b" 
												  delegate:self] retain];
	//_facebookConnection = [[MMKFacebook facebookWithAPIKey:@"2c1db9a" withSecret:@"1" delegate:self] retain];
	
	
}

-(void)showLogin
{
	[_facebookConnection showFacebookLoginWindow];
}

-(void)userLoginSuccessful
{
	[_loginButton removeFromSuperview];
	_text.text = @"Mobile MKAbeFook is ready for use. :)";
}

-(UIView *)frontView
{
	return _frontView;
}





- (void)dealloc {

	[window release];
	[super dealloc];
}

@end
