//
//  MKErrorWindow.m
//  MKAbeFook
//
//  Created by Mike Kinney on 7/21/08.
/*
 Copyright (c) 2008, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */
 
#import "MKErrorWindow.h"


@implementation MKErrorWindow

+(MKErrorWindow *)errorWindowWithTitle:(NSString *)title message:(NSString *)message details:(NSString *)details
{
	return [[MKErrorWindow alloc] initWithTitle:title message:message details:details]; 
}

-(MKErrorWindow *)initWithTitle:(NSString *)title message:(NSString *)message details:(NSString *)details
{
	self = [super init];
	NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"ErrorWindow" ofType:@"nib"];
	[super initWithWindowNibPath:path owner:self];
	_errorTitle = [title retain];
	_errorMessage = [message retain];
	
	if(details != nil)
		_errorDetails = [details retain];
	else
		_errorDetails = nil;
	
	
	return self;
}

-(void)awakeFromNib
{
	NSFont *font = [NSFont boldSystemFontOfSize:14.0];
	NSDictionary *attrsDict = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
	NSAttributedString *title = [[[NSAttributedString alloc] initWithString:_errorTitle attributes:attrsDict] autorelease];
	[errorTitle setAttributedStringValue:title];
	[errorMessage setStringValue:_errorMessage];
	[errorImage setImage:[NSApp applicationIconImage]];
	if(_errorDetails != nil)
	{
		[detailsButton setHidden:NO];
	}
}

-(void)dealloc
{
	[super dealloc];
}

-(void)display
{
	[[self window] center];
	[[self window] makeKeyAndOrderFront:nil];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self autorelease];
}

-(IBAction)okButton:(id)sender
{
	//TODO: find a better way to close this
	[[self window] orderOut:nil];
	[self windowWillClose:nil];
}

-(IBAction)detailsButton:(id)sender
{
	[errorDetails setString:_errorDetails];
	int newWindowHeight = 200;
	NSRect currentRect = [[self window] frame];
	NSRect rect = NSMakeRect(currentRect.origin.x, currentRect.origin.y - newWindowHeight, currentRect.size.width, currentRect.size.height + newWindowHeight);
	//[[self window] center];
	[[self window] setFrame:rect display:YES animate:YES];
	[[[errorDetails superview] superview] setHidden:NO];
	[errorDetails setHidden:NO];
	[detailsButton setEnabled:NO];
	[detailsButton setHidden:YES];
}

@end
