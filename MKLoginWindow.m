/*
 Copyright (c) 2007, Mike Kinney
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
 following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the 
 following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the 
 following disclaimer in the documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */
//
//  LoginWindow.m
//  MKAbeFook
//
//  Created by Mike on 10/11/06.
//  Copyright 2006 Mike Kinney. All rights reserved.
//

#import "MKLoginWindow.h"


@implementation MKLoginWindow
-(id)initWithDelegate:(id)aDelegate
{
	self = [super init];
	_delegate = aDelegate;
	path = [[NSBundle bundleForClass:[self class]] pathForResource:@"LoginWindow" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	NSRect visibleArea =  NSMakeRect(0, 0, 626, 426);
	[[[loginWebView mainFrame] webView] setFrame:visibleArea];
	return self;
}

-(id)initForSheetWithDelegate:(id)aDelegate
{
	_delegate = aDelegate;
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
	
	[[[loginWebView mainFrame] frameView] setAllowsScrolling:NO];	
	[[loginWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:loginURL]];
}


-(IBAction)closeSheet:(id)sender 
{
	[[self window] orderOut:sender];
	[NSApp endSheet:[self window] returnCode:1];
	//[[self window] performClose:sender];
	[self windowWillClose:nil];
}



- (void)windowWillClose:(NSNotification *)aNotification
{
	[_delegate performSelector:@selector(getAuthSession)];

	[self autorelease];
}

-(void)dealloc
{
	[super dealloc];
}



@end
