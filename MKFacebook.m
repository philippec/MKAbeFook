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
#import "MKParsingExtras.h"
#import "NSXMLElementAdditions.h"
#import "MKErrorWindow.h"
#import "MKFacebookSession.h"

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
		[self setApiKey:anAPIKey];
		[self setSecretKey:aSecret];
		[self setSessionKey:nil];
		[self setSessionSecret:nil];
		[self setUid:nil];
		[self setConnectionTimeoutInterval:5.0];

		hasSessionKey = FALSE;
		hasSessionSecret = FALSE;
		hasUid = FALSE;
		userHasLoggedInMultipleTimes = FALSE;
		_delegate = aDelegate;
		_shouldUseSynchronousLogin = NO;
		_displayLoginAlerts = YES;
		_hasPersistentSession = NO;
		_useStandardDefaultsSessionStorage = YES;
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
		[self setApiKey:anApiKey];
		[self setSecretKey:aSecretKey];

		[self setSessionKey:nil];
		[self setSessionSecret:nil];
		[self setUid:nil];
		[self setConnectionTimeoutInterval:5.0];

		hasSessionKey = FALSE;
		hasSessionSecret = FALSE;
		hasUid = FALSE;
		userHasLoggedInMultipleTimes = FALSE;
		_delegate = aDelegate;
		_shouldUseSynchronousLogin = NO;
		_displayLoginAlerts = YES;
		_hasPersistentSession = NO;
		_useStandardDefaultsSessionStorage = YES;
	}
	return self;
}

-(void)dealloc
{
	[apiKey release];
	[secretKey release];
	[sessionKey release];
	[sessionSecret release];
	[uid release];
	[super dealloc];
}
#pragma mark -

#pragma mark Accessors and Mutators
-(void)setSecretKey:(NSString *)aSecretKey
{
	aSecretKey = [aSecretKey copy];
	[secretKey release];
	secretKey = aSecretKey;
}

-(NSString *)secretKey
{
	return secretKey;
}

-(void)setApiKey:(NSString *)anApiKey
{
	anApiKey = [anApiKey copy];
	[apiKey release];
	apiKey = anApiKey;
}

-(NSString *)apiKey
{
	return apiKey;
}

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


-(void)setConnectionTimeoutInterval:(NSTimeInterval)aConnectionTimeoutInterval
{
	connectionTimeoutInterval = aConnectionTimeoutInterval;
}
-(NSTimeInterval)connectionTimeoutInterval
{
	return connectionTimeoutInterval;
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
	[loginString appendString:[self apiKey]];
	[loginString appendString:@"&v="];
	[loginString appendString:MKFacebookAPIVersion];
	
	[loginString appendString:@"&connect_display=popup"];
	
	[loginString appendString:@"&next=http://www.facebook.com/connect/login_success.html"];
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
	[self setSessionSecret:[session secret]];

	[self setUid:[NSString stringWithFormat:@"%@", [session uid]]];
	DLog(@"user id %@", [self uid]);
	hasUid = YES;
	hasSessionKey = YES;
	hasSessionSecret = YES;
	// we don't really have a token, but it doesn't matter since we have a session
	
	_hasPersistentSession = YES;
	if([_delegate respondsToSelector:@selector(userLoginSuccessful)])
		[_delegate performSelector:@selector(userLoginSuccessful)];
	
}

-(BOOL)loadPersistentSession
{
	//load any existing sessions
	MKFacebookSession *session = [MKFacebookSession sharedMKFacebookSession];
	if ([session loadSession]) {
		
		[self setSessionKey:[session sessionKey]];
		[self setSessionSecret:[session secret]];
		
		NSXMLDocument *user = [self fetchFacebookData:[self generateFacebookURL:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.users.getLoggedInUser", @"method", nil]]];

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


//generateFacebookURL, generateTimeStamp, and generateSigForParameters used in MKFacebook.m, MKAsyncRequest.m and MKPhotoUploader.m to prepare urls that are sent to facebook.com
-(NSURL *)generateFacebookURL:(NSString *)aMethodName parameters:(NSDictionary *)parameters
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
	//these will be here for all requests.  we could make the user supply the method in the parameters but i like it as a string
	[mutableDictionary setValue:aMethodName forKey:@"method"];
	[mutableDictionary setValue:MKFacebookAPIVersion forKey:@"v"];
	[mutableDictionary setValue:[self apiKey] forKey:@"api_key"];
	[mutableDictionary setValue:MKFacebookResponseFormat forKey:@"format"];
	
	//all other methods require call_id and session_key
	if(![aMethodName isEqualToString:@"facebook.auth.getSession"] || ![aMethodName isEqualToString:@"facebook.auth.createToken"])
	{
		[mutableDictionary setValue:[self sessionKey] forKey:@"session_key"];
		[mutableDictionary setValue:[self generateTimeStamp] forKey:@"call_id"];
	}
	
	NSMutableString *urlString = [[NSMutableString alloc] initWithString:MKAPIServerURL];
	[urlString appendFormat:@"?method=%@", aMethodName]; 	//we'll do one outside the loop because we need to start with a ? anyway.  method is a good one to start with
	NSEnumerator *enumerator = [mutableDictionary keyEnumerator];
	id key;
	while ((key = [enumerator nextObject])) {
		if([key isNotEqualTo:@"method"]) //remember we already did this one
			[urlString appendFormat:@"&%@=%@", key, [mutableDictionary valueForKey:key]];
	}			
	[urlString appendFormat:@"&sig=%@", [self generateSigForParameters:mutableDictionary]];
	return [NSURL URLWithString:[[urlString encodeURLLegally] autorelease]];
}



-(NSURL *)generateFacebookURL:(NSDictionary *)parameters
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
	//these will be here for all requests. 
	[mutableDictionary setValue:MKFacebookAPIVersion forKey:@"v"];
	[mutableDictionary setValue:[self apiKey] forKey:@"api_key"];
	[mutableDictionary setValue:MKFacebookResponseFormat forKey:@"format"];
	
	//all other methods require call_id and session_key
	if(![[mutableDictionary valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || ![[mutableDictionary valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
	{
		[mutableDictionary setValue:[self sessionKey] forKey:@"session_key"];
		[mutableDictionary setValue:[self generateTimeStamp] forKey:@"call_id"];
	}
	
	NSMutableString *urlString = [[NSMutableString alloc] initWithString:MKAPIServerURL];
	[urlString appendFormat:@"?method=%@", [mutableDictionary valueForKey:@"method"]]; 	//we'll do one outside the loop because we need to start with a ? anyway.  method is a good one to start with
	NSEnumerator *enumerator = [mutableDictionary keyEnumerator];
	id key;
	while ((key = [enumerator nextObject])) {
		
		//just in case someone tries to upload a photo via GET we'll trow away the image and they'll get the error back from facebook
		if([[mutableDictionary objectForKey:key] isKindOfClass:[NSImage class]])
			[mutableDictionary removeObjectForKey:key];
		
		if([key isNotEqualTo:@"method"]) //remember we already did this one
			[urlString appendFormat:@"&%@=%@", key, [mutableDictionary valueForKey:key]];
	}			
	[urlString appendFormat:@"&sig=%@", [self generateSigForParameters:mutableDictionary]];
	return [NSURL URLWithString:[[urlString encodeURLLegally] autorelease]];
}


-(NSString *)generateTimeStamp
{
	return [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
}


//sorts parameters keys, creates a string of values, returns md5 hash (cleaned up by Patrick Jayet 0.8.2)
- (NSString *)generateSigForParameters:(NSDictionary *)parameters
{
	// pat: fixed signature issue
	// 1. get a sorted array with the keys
	NSArray* sortedKeyArray = [[parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	// 2. construct the concatenated string
	NSMutableString* tempString = [[[NSMutableString alloc] init] autorelease];
	NSEnumerator *enumerator =[sortedKeyArray objectEnumerator];
	NSString *key; //keys of sortedParameters
	while(key = [enumerator nextObject])
	{
		//prevents attempting to append nil strings.  Thanks Andrei Freeman. 0.8.1
		if((key != nil) && ([key length] > 0))
		{
			[tempString appendFormat:@"%@=%@", key, [parameters objectForKey:key]];
		}else
		{
			NSException *e = [NSException exceptionWithName:@"genSigForParm" reason:@"Bad Parameter Object" userInfo:parameters];
			[e raise];
		}
	}
	
	//methods except these require we use the secretKey that was assigned during login, not our original one
	if([[parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || [[parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
	{
		//DLog(@"secretKey");
		if([self secretKey] != nil)
			[tempString appendString:[self secretKey]];
		else
		{			
			NSException *e = [NSException exceptionWithName:@"genSigForParm" reason:@"nil secret key, is your application type set to Desktop?" userInfo:nil];
			[e raise];
		}
	}else
	{
		//DLog(@"sessionSecret");
		if([self sessionSecret] != nil && [[self sessionSecret] length] > 0)
			[tempString appendString:[self sessionSecret]];
		else
		{
			NSException *e = [NSException exceptionWithName:@"genSigForParm" reason:@"nil session secret, is your application type set to Desktop?" userInfo:nil];
			[e raise];
			
		}
	}
	
	return [tempString md5HexHash];
}
-(id)fetchFacebookData:(NSURL *)theURL
{
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:theURL 
												cachePolicy:NSURLRequestReloadIgnoringCacheData
											timeoutInterval:[self connectionTimeoutInterval]];
	NSHTTPURLResponse *xmlResponse;  //not used right now
	NSXMLDocument *returnXML = nil;
	NSError *fetchError = nil;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:urlRequest
												 returningResponse:&xmlResponse
															 error:&fetchError];

	if(fetchError != nil)
	{
		if(_displayLoginAlerts == YES)
		{
			[self displayGeneralAPIError:@"Network Problems?" 
								 message:@"I can't seem to talk to Facebook.com right now.  This is a problem." 
							 buttonTitle:@"Fine!" details:[fetchError description]];
			DLog(@"synchronous fetch error %@", [fetchError description]);
		}
			
		return nil;
	}else
	{
		returnXML = [[[NSXMLDocument alloc] initWithData:responseData
												options:0
												  error:nil] autorelease];
	}
	
	return returnXML;


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
	
	
	if(_displayLoginAlerts == YES)
	{
		//DLog(@"got here");
		[self displayGeneralAPIError:@"API Problems?" message:@"Facebook didn't give us the token we needed.  You can try again if you want but consider this login attempt defeated." buttonTitle:@"Fine!" details:nil];
	}	
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
	userHasLoggedInMultipleTimes = TRUE; //used to prevent persistent session from loading if a user as logged out but the application hasn't written the NSUserDefaults yet.  this doesn't make sense, we can write the NSUserDefaults to disk anytime we wish, what's the logic behind this?  TODO: review logic behind the purpose of this.
}
#pragma mark -

-(void)grantExtendedPermission:(NSString *)aString
{
	if([self userLoggedIn] == NO)
	{
		if(_displayLoginAlerts == YES)
		{
			[self displayGeneralAPIError:@"No user logged in!" message:@"Permissions cannnot be extended if no one is logged in." buttonTitle:@"OK Fine!" details:nil];			
		}
		return;
	}
	
	loginWindow = [[MKLoginWindow alloc] init]; //will be released when closed			
	[[loginWindow window] setTitle:@"Extended Permissions"];
	[loginWindow showWindow:self];
	//[loginWindow setWindowSize:NSMakeSize(GRANT_PERMISSIONS_WINDOW_WIDTH, GRANT_PERMISSIONS_WINDOW_HEIGHT)];
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/authorize.php?api_key=%@&v=%@&ext_perm=%@&popup", [self apiKey], MKFacebookAPIVersion, aString]];
	[loginWindow loadURL:url];
	
}

-(NSWindow *)grandExtendedPermissionForSheet:(NSString *)aString
{
	if([self userLoggedIn] == NO)
	{
		if(_displayLoginAlerts == YES)
		{
			[self displayGeneralAPIError:@"No user logged in!" message:@"Permissions cannnot be extended if no one is logged in." buttonTitle:@"OK Fine!" details:nil];			
		}
		return nil;
	}
	
	loginWindow = [[MKLoginWindow alloc] init];
	loginWindow._loginWindowIsSheet = YES;
	//[loginWindow setWindowSize:NSMakeSize(GRANT_PERMISSIONS_WINDOW_WIDTH, GRANT_PERMISSIONS_WINDOW_HEIGHT)];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/authorize.php?api_key=%@&v=%@&ext_perm=%@&popup", [self apiKey], MKFacebookAPIVersion, aString]];
	[[loginWindow window] setTitle:@"Extended Permissions"];
	[loginWindow loadURL:url];

	return [loginWindow window];
	
}

-(void)displayGeneralAPIError:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle details:(NSString *)details
{
	NSString *errorTitle;
	NSString *errorMessage;
	NSString *errorButtonTitle;
	
	if(!title)
		errorTitle = @"API Error";
	else
		errorTitle = [NSString stringWithString:title];
	
	if(!message)
		errorMessage = @"Something done gone exploded.";
	else
		errorMessage = [NSString stringWithString:message];
	
	if(!buttonTitle)
		errorButtonTitle = @"Fine!";
	else
		errorButtonTitle = [NSString stringWithString:buttonTitle];
	
	MKErrorWindow *error = [MKErrorWindow errorWindowWithTitle:errorTitle message:errorMessage details:details];
	[error display];
}

-(void)setDisplayLoginAlerts:(BOOL)aBool
{
	_displayLoginAlerts = aBool;
}

-(BOOL)displayLoginAlerts
{
	return _displayLoginAlerts;
}




-(void)setUseStandardDefaultsSessionStorage:(BOOL)aBool
{
	_useStandardDefaultsSessionStorage = aBool;
}

-(BOOL)useStandardDefaultsSessionStorage
{
	return _useStandardDefaultsSessionStorage;
}

-(BOOL)hasPersistentSession
{
	return _hasPersistentSession;
}

-(NSDictionary *)savePersistentSession
{
	//
	if([self hasPersistentSession] && [self sessionKey] != nil && [self sessionSecret] != nil)
	{
		NSDictionary *dictionary = [[NSDictionary alloc] initWithObjectsAndKeys:[self sessionKey], @"sessionKey", [self sessionSecret], @"sessionSecret", nil];
		
		return [dictionary autorelease];
	}
	DLog(@"persistent session requested, but incorrect storage type, session key, or session secret missing");
	return nil;
}

-(BOOL)restorePersistentSession:(NSDictionary *)persistentSession
{
	if([persistentSession objectForKey:@"sessionSecret"] == nil || [persistentSession objectForKey:@"sessionKey"] == nil)
	{
		DLog(@"restore failed: %@", [persistentSession description]);
		return NO;
	}
		
	//TODO: validaate values
	[self setSessionSecret:[persistentSession valueForKey:@"sessionSecret"]];
	[self setSessionKey:[persistentSession valueForKey:@"sessionKey"]];

	return [self loadPersistentSession];
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



