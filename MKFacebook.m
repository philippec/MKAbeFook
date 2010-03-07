// 
//  MKFacebook.m
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

#import "MKFacebook.h"
#import "MKLoginWindow.h"
#import "CocoaCryptoHashing.h"
#import "NSXMLElementAdditions.h"
#import "NSXMLDocumentAdditions.h"
#import "MKErrorWindow.h"
#import "MKFacebookSession.h"
#import "MKFacebookRequest.h"

NSString *MKAPIServerURL = @"http://api.facebook.com/restserver.php";
NSString *MKLoginUrl = @"http://www.facebook.com/login.php";
NSString *MKExtendPermissionsURL = @"http://www.facebook.com/connect/prompt_permissions.php";
NSString *MKFacebookAPIVersion = @"1.0";
NSString *MKFacebookDefaultResponseFormat = @"XML";


@interface MKFacebook (Private)
- (void)setApiKey:(NSString *)anApiKey;
- (NSURL *)prepareLoginURLWithExtendedPermissions:(NSArray *)extendedPermissions;
@end


@implementation MKFacebook

#pragma mark Properties

@synthesize useModalLogin;

#pragma mark -

#pragma mark init methods
+ (MKFacebook *)facebookWithAPIKey:(NSString *)anAPIKey delegate:(id)aDelegate
{
	return [[[MKFacebook alloc] initUsingAPIKey:anAPIKey delegate:(id)aDelegate] autorelease];
}


- (MKFacebook *)initUsingAPIKey:(NSString *)anAPIKey delegate:(id)aDelegate
{
	if(![aDelegate respondsToSelector:@selector(userLoginSuccessful)])
	{
		NSException *exception = [NSException exceptionWithName:@"InvalidDelegate"
														 reason:@"Delegate requires -(void)userLoginSuccessful method" 
													   userInfo:nil];
		
		[exception raise];
		return nil;
	}
		
	self = [super init];
	if(self != nil)
	{
		[[MKFacebookSession sharedMKFacebookSession] setApiKey:anAPIKey];

		_delegate = aDelegate;
		_displayLoginAlerts = YES;
		self.useModalLogin = NO;

	}
	return self;
}


- (void)dealloc
{
	[super dealloc];
}
#pragma mark -


#pragma mark Instance Methods

- (void)login
{
	[self loginWithPermissions:nil forSheet:NO];
}

- (void)loginUsingModalWindow{
	self.useModalLogin = YES;
	[self loginWithPermissions:nil forSheet:NO];
}

- (NSWindow *)loginWithPermissions:(NSArray *)permissions forSheet:(BOOL)sheet
{
	//try to use existing session
	if ([[MKFacebookSession sharedMKFacebookSession] loadSession] == YES)
	{
		[self userLoginSuccessful];
		return nil;
	}else
	{
		//prepare loginwindow
		loginWindow = [[MKLoginWindow alloc] init]; //will be released when closed			
		[[loginWindow window] setTitle:@"Login"];
		
		loginWindow._delegate = self; //loginWindow needs to know where to call userLoginSuccessful
		
		//prepare login url
		NSURL *loginURL = [self prepareLoginURLWithExtendedPermissions:permissions];
		
		//begin loading login url
		[loginWindow loadURL:loginURL];
		
		//if window will not be used for a sheet simply load the window
		if(sheet == NO)
		{
			[[loginWindow window] center];
			if (self.useModalLogin == YES) {
				DLog(@"display modal login");
				loginWindow.runModally = YES;
				//borrowed from - http://www.dejal.com/blog/2007/01/cocoa-topics-case-modal-webview
				//and - http://www.mail-archive.com/cocoa-dev@lists.apple.com/msg05398.html
				//and - NSApp runModalSession: documentation
				NSModalSession session = [NSApp beginModalSessionForWindow:[loginWindow window]];
				for(;;)
				{
					// Run the window modally until there are no events to process:
					if ([NSApp runModalSession:session] != NSRunContinuesResponse)
						break;

					// Give the main loop some time:
					[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate: [NSDate distantFuture]];
				}
				[NSApp endModalSession:session];
				DLog(@"modal session should be done now!");
			}else {
				[loginWindow showWindow:nil];
			}
			return nil;
		}
		
		if(sheet == YES)
		{
			loginWindow._loginWindowIsSheet = YES;
			return [loginWindow window];
		}
	}
	return nil;
}



- (BOOL)userLoggedIn
{
	return [[MKFacebookSession sharedMKFacebookSession] validSession];
	
}


- (NSNumber *)uid
{
	return [[MKFacebookSession sharedMKFacebookSession] uid];
}



- (void)logout
{
	//TODO: implement logout
	[[MKFacebookSession sharedMKFacebookSession] destroySession];
}


- (void)userLoginSuccessful
{
	
	if([_delegate respondsToSelector:@selector(userLoginSuccessful)])
		[_delegate performSelector:@selector(userLoginSuccessful)];
	
}


- (void)grantExtendedPermission:(NSString *)aString
{
//	if([self userLoggedIn] == NO)
//	{
//		if(_displayLoginAlerts == YES)
//		{
//			MKErrorWindow *errorWindow = [MKErrorWindow errorWindowWithTitle:@"No user logged in!" message:@"Permissions cannot be extended if no one is logged in." details:nil];
//			[errorWindow display];
//		}
//		return;
//	}
//	
//	loginWindow = [[MKLoginWindow alloc] init]; //will be released when closed			
//	[[loginWindow window] setTitle:@"Extended Permissions"];
//	[loginWindow showWindow:self];
//	//[loginWindow setWindowSize:NSMakeSize(GRANT_PERMISSIONS_WINDOW_WIDTH, GRANT_PERMISSIONS_WINDOW_HEIGHT)];
//	
//	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?api_key=%@&v=%@&ext_perm=%@&popup", MKExtendPermissionsURL, [[MKFacebookSession sharedMKFacebookSession] apiKey], MKFacebookAPIVersion, aString]];
//	[loginWindow loadURL:url];
	
	
	[self grantExtendedPermission:aString forSheet:NO];
	
	
}


- (NSWindow *)grantExtendedPermission:(NSString *)aString forSheet:(BOOL)forSheet
{
	if([self userLoggedIn] == NO)
	{
		if(_displayLoginAlerts == YES)
		{
			MKErrorWindow *errorWindow = [MKErrorWindow errorWindowWithTitle:@"No user logged in!" message:@"Permissions cannot be extended if no one is logged in." details:nil];
			[errorWindow display];
		}
		return nil;
	}
	
	loginWindow = [[MKLoginWindow alloc] init];
	[[loginWindow window] setTitle:@"Extended Permissions"];
	loginWindow._loginWindowIsSheet = forSheet;
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?api_key=%@&v=%@&ext_perm=%@&display=popup&fbconnect=true&http://www.facebook.com/connect/login_success.html?xxRESULTTOKENxx", MKExtendPermissionsURL, [[MKFacebookSession sharedMKFacebookSession] apiKey], MKFacebookAPIVersion, aString]];
	

	[loginWindow loadURL:url];
	
	if (forSheet == YES) {
		
		return [loginWindow window];
	}else {
		[[loginWindow window] center];
		[loginWindow showWindow:self];
		return nil;
	}

	return nil;
}


- (void)setDisplayLoginAlerts:(BOOL)aBool
{
	_displayLoginAlerts = aBool;
}


- (BOOL)displayLoginAlerts
{
	return _displayLoginAlerts;
}



//private
- (NSURL *)prepareLoginURLWithExtendedPermissions:(NSArray *)extendedPermissions
{
	NSMutableString *loginString = [[[NSMutableString alloc] initWithString:MKLoginUrl] autorelease];
	[loginString appendString:@"?api_key="];
	[loginString appendString:[[MKFacebookSession sharedMKFacebookSession] apiKey]];
	[loginString appendString:@"&v="];
	[loginString appendString:MKFacebookAPIVersion];
	
	[loginString appendString:@"&connect_display=popup"];
	
	[loginString appendString:@"&next=http://www.facebook.com/connect/login_success.html"];
	//[loginString appendString:@"&cancel_url=http://www.facebook.com/connect/login_failure.html"];
	
	[loginString appendString:@"&fbconnect=true"];
	[loginString appendString:@"&return_session=true"];

	if(extendedPermissions != nil)
	{
		[loginString appendFormat:@"&req_perms=%@",[extendedPermissions componentsJoinedByString:@","]];
	}

	[loginString appendString:@"&skipcookie"];

	return [NSURL URLWithString:loginString];
	
}


@end
