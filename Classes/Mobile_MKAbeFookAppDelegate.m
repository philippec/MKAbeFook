//
//  Mobile_MKAbeFookAppDelegate.m
//  Mobile MKAbeFook
//
//  Created by Mike Kinney on 3/28/08.
//  Copyright Mike Kinney 2008. All rights reserved.
//

#import "Mobile_MKAbeFookAppDelegate.h"
#import "MyView.h"

@implementation Mobile_MKAbeFookAppDelegate

@synthesize window;
@synthesize contentView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {	
	// Create window
	self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    // Set up content view
	self.contentView = [[[MyView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	[window addSubview:contentView];
    
	// Show window
	[window makeKeyAndVisible];
}

- (void)dealloc {
	[contentView release];
	[window release];
	[super dealloc];
}

@end
