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
//#import "MKParsingExtras.h"
#import "NSXMLElementAdditions.h"
#import "NSXMLDocumentAdditions.h"
#import "MKErrorWindow.h"
#import "MKFacebookSession.h"
#import "MKFacebookRequest.h"

NSString *MKAPIServerURL = @"http://api.facebook.com/restserver.php";
NSString *MKLoginUrl = @"http://www.facebook.com/login.php";
NSString *MKFacebookAPIVersion = @"1.0";
NSString *MKFacebookResponseFormat = @"XML";

#define GRANT_PERMISSIONS_WINDOW_WIDTH 970
#define GRANT_PERMISSIONS_WINDOW_HEIGHT 600

@interface MKFacebook (Private)
-(void)setApiKey:(NSString *)anApiKey;
-(void)setSecretKey:(NSString *)aSecretKey;
-(NSString *)secretKey;				
-(void)setSessionKey:(NSString *)aSessionKey;
-(void)setSessionSecret:(NSString *)aSessionSecret;
-(NSString *)sessionSecret;
-(void)setUid:(NSString *)aUid;
-(NSTimeInterval)timeoutInterval;
-(void)facebookRequestFailed:(NSError *)error;
-(void)facebookResponseReceived:(NSXMLDocument *)xml;
- (NSURL *)prepareLoginURLWithExtendedPermissions:(NSArray *)extendedPermissions;
@end


@implementation MKFacebook
#pragma mark Intialization
+(MKFacebook *)facebookWithAPIKey:(NSString *)anAPIKey withSecret:(NSString *)aSecret delegate:(id)aDelegate
{
	return [[[MKFacebook alloc] initUsingAPIKey:anAPIKey usingSecret:aSecret delegate:(id)aDelegate] autorelease];
}


-(MKFacebook *)initUsingAPIKey:(NSString *)anAPIKey usingSecret:(NSString *)aSecret delegate:(id)aDelegate
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
		//defaultsName = [aDefaultsName copy];
		defaultsName = [[NSBundle mainBundle] bundleIdentifier];
		[[MKFacebookSession sharedMKFacebookSession] setApiKey:anAPIKey];
		[[MKFacebookSession sharedMKFacebookSession] setSecretKey:aSecret];
	
		[self setSessionKey:nil];
		[self setSessionSecret:nil];
		[self setUid:nil];


		hasSessionKey = FALSE;
		hasSessionSecret = FALSE;
		hasUid = FALSE;

		_delegate = aDelegate;
		_shouldUseSynchronousLogin = NO;
		_displayLoginAlerts = YES;


	}
	return self;
}


+(MKFacebook *)facebookWithAPIKey:(NSString *)anAPIKey withSecret:(NSString *)aSecret delegate:(id)aDelegate withDefaultsName:(NSString *)aDefaultsName
{
	return [[[MKFacebook alloc] initUsingAPIKey:anAPIKey usingSecret:aSecret delegate:(id)aDelegate withDefaultsName:aDefaultsName] autorelease];
}

-(MKFacebook *)initUsingAPIKey:(NSString *)anApiKey usingSecret:(NSString *)aSecretKey delegate:(id)aDelegate withDefaultsName:(NSString *)aDefaultsName
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
		defaultsName = [aDefaultsName copy];
		[[MKFacebookSession sharedMKFacebookSession] setApiKey:anApiKey];
		[[MKFacebookSession sharedMKFacebookSession] setSecretKey:aSecretKey];


		[self setSessionKey:nil];
		[self setSessionSecret:nil];
		[self setUid:nil];

		hasSessionKey = FALSE;
		hasSessionSecret = FALSE;
		hasUid = FALSE;

		_delegate = aDelegate;
		_shouldUseSynchronousLogin = NO;
		_displayLoginAlerts = YES;


	}
	return self;
}

-(void)dealloc
{
	[sessionKey release];
	[sessionSecret release];
	[uid release];
	[super dealloc];
}
#pragma mark -

#pragma mark Accessors and Mutators


-(void)setSessionKey:(NSString *)aSessionKey
{
	aSessionKey = [aSessionKey copy];
	[sessionKey release];
	sessionKey = aSessionKey;
}

-(NSString *)sessionKey
{
	return sessionKey;
}

-(void)setSessionSecret:(NSString *)aSessionSecret
{
	aSessionSecret = [aSessionSecret copy];
	[sessionSecret release];
	sessionSecret = aSessionSecret;
}

-(NSString *)sessionSecret
{
	return sessionSecret;
}

-(void)setUid:(NSString *)aUid
{
	aUid = [aUid copy];
	[uid release];
	uid = aUid;
}

-(NSString *)uid
{
	return uid;
}



-(void)setShouldUseSynchronousLogin:(BOOL)aBool
{
	_shouldUseSynchronousLogin = aBool;
}

-(BOOL)shouldUseSychronousLogin
{
	return _shouldUseSynchronousLogin;
}

#pragma mark -

#pragma mark Workers


- (NSWindow *)loginWithPermissions:(NSArray *)permissions forSheet:(BOOL)sheet{
	//try to use existing session
	if ([self loadPersistentSession] == NO) {
		
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
			[loginWindow showWindow:self];
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


- (NSURL *)prepareLoginURLWithExtendedPermissions:(NSArray *)extendedPermissions{
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

- (void)logout{
	//TODO: implement logout
}


- (void)userLoginSuccessful{
	
	MKFacebookSession *session = [MKFacebookSession sharedMKFacebookSession];

	[self setSessionKey:[session sessionKey]];
	[self setSessionSecret:[session sessionSecret]];

	[self setUid:[NSString stringWithFormat:@"%@", [session uid]]];
	DLog(@"user id %@", [self uid]);
	hasUid = YES;
	hasSessionKey = YES;
	hasSessionSecret = YES;
	// we don't really have a token, but it doesn't matter since we have a session
	

	if([_delegate respondsToSelector:@selector(userLoginSuccessful)])
		[_delegate performSelector:@selector(userLoginSuccessful)];
	
}

-(BOOL)loadPersistentSession
{
	//load any existing sessions
	MKFacebookSession *session = [MKFacebookSession sharedMKFacebookSession];
	if ([session loadSession]) {
		
		[self setSessionKey:[session sessionKey]];
		[self setSessionSecret:[session sessionSecret]];
		
		MKFacebookRequest *request = [[MKFacebookRequest alloc] init];
		
		//TODO: use MKFacebookRequest
		NSXMLDocument *user = [request fetchFacebookData:[request generateFacebookURL:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.users.getLoggedInUser", @"method", nil]]];
		[request release];
		if([user validFacebookResponse] == NO)
		{
			DLog(@"persistent login failed, here's why...");
			DLog(@"%@", [user description]);
			[self resetFacebookConnection];
			return NO;
		}
		
		//check to see if the uid returned is the same as our existing session
		if ([[[user rootElement] stringValue] isEqualToString:[session uid]] ) {
			[self userLoginSuccessful];
			return YES;
		}
		
	}
	return NO;
}

-(void)clearInfiniteSession
{
	[[MKFacebookSession sharedMKFacebookSession] destroySession];
	[self resetFacebookConnection];
}



-(void)facebookResponseReceived:(NSXMLDocument *)xml
{
	//DLog([xml description]);
	NSDictionary *xmlResponse = [[xml rootElement] dictionaryFromXMLElement];
	DLog(@"received response: %@", [xmlResponse description]);
}

-(void)facebookErrorResponseReceived:(NSXMLDocument *)xml
{
	if([_delegate respondsToSelector:@selector(userLoginFailed)])
		[_delegate performSelector:@selector(userLoginFailed)];
	
	if([_delegate respondsToSelector:@selector(facebookAuthenticationError:)])
		[_delegate performSelector:@selector(facebookAuthenticationError:) withObject:[[xml rootElement] dictionaryFromXMLElement]];
		
}

//this will be called if asynchronous requests fail.
//all asynchronous requests this class is a delegate of are related to logging in so it's safe to put the stuff needed to clean up the login window here
-(void)facebookRequestFailed:(NSError *)error
{
	if(loginWindow != nil)
	{
		[loginWindow hideLoadingWindowIndicator];
	}
}

#pragma mark Misc
-(BOOL)userLoggedIn
{
	if(hasSessionKey && hasSessionSecret && hasUid) //then it's kinda safe to assume we're logged in.....
	{
		return TRUE;
	}else
	{
		return FALSE;
	}
	
}

-(void)resetFacebookConnection
{
	[self setSessionKey:nil];
	[self setSessionSecret:nil];
	[self setUid:nil];
	hasSessionKey = FALSE;
	hasSessionSecret = FALSE;
	hasUid = FALSE;

}
#pragma mark -

-(void)grantExtendedPermission:(NSString *)aString
{
	if([self userLoggedIn] == NO)
	{
		if(_displayLoginAlerts == YES)
		{
			MKErrorWindow *errorWindow = [MKErrorWindow errorWindowWithTitle:@"No user logged in!" message:@"Permissions cannot be extended if no one is logged in." details:nil];
			[errorWindow display];
		}
		return;
	}
	
	loginWindow = [[MKLoginWindow alloc] init]; //will be released when closed			
	[[loginWindow window] setTitle:@"Extended Permissions"];
	[loginWindow showWindow:self];
	//[loginWindow setWindowSize:NSMakeSize(GRANT_PERMISSIONS_WINDOW_WIDTH, GRANT_PERMISSIONS_WINDOW_HEIGHT)];
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/authorize.php?api_key=%@&v=%@&ext_perm=%@&popup", [[MKFacebookSession sharedMKFacebookSession] apiKey], MKFacebookAPIVersion, aString]];
	[loginWindow loadURL:url];
	
}

-(NSWindow *)grandExtendedPermissionForSheet:(NSString *)aString
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
	loginWindow._loginWindowIsSheet = YES;
	//[loginWindow setWindowSize:NSMakeSize(GRANT_PERMISSIONS_WINDOW_WIDTH, GRANT_PERMISSIONS_WINDOW_HEIGHT)];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/authorize.php?api_key=%@&v=%@&ext_perm=%@&popup", [[MKFacebookSession sharedMKFacebookSession] apiKey], MKFacebookAPIVersion, aString]];
	[[loginWindow window] setTitle:@"Extended Permissions"];
	[loginWindow loadURL:url];

	return [loginWindow window];
	
}


-(void)setDisplayLoginAlerts:(BOOL)aBool
{
	_displayLoginAlerts = aBool;
}

-(BOOL)displayLoginAlerts
{
	return _displayLoginAlerts;
}


@end



@implementation NSString(NSStringExtras)
/*
	Encode a string legally so it can be turned into an NSURL
	Original Source: <http://cocoa.karelia.com/Foundation_Categories/NSString/Encode_a_string_leg.m>
	(See copyright notice at <http://cocoa.karelia.com>)
	 */

/*"	Fix a URL-encoded string that may have some characters that makes NSURL barf.
It basicaly re-encodes the string, but ignores escape characters + and %, and also #.
"*/
- (NSString *) encodeURLLegally
{
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(
																			NULL, (CFStringRef) self, (CFStringRef) @"%+#", NULL,
																			CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
	return result;
}
@end



