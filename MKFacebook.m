// 
//  MKFacebook.m
//  MKAbeFook
//
//  Created by Mike on 10/11/06.
/*
 Copyright (c) 2008, Mike Kinney
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

NSString *MKAPIServerURL = @"http://api.facebook.com/restserver.php";
NSString *MKLoginUrl = @"http://www.facebook.com/login.php";
NSString *MKFacebookAPIVersion = @"1.0";
NSString *MKFacebookFormat = @"XML";

@interface MKFacebook (Private)
-(void)setApiKey:(NSString *)anApiKey;
-(void)setSecretKey:(NSString *)aSecretKey;
-(NSString *)secretKey;				
-(void)setSessionKey:(NSString *)aSessionKey;
-(void)setSessionSecret:(NSString *)aSessionSecret;
-(NSString *)sessionSecret;
-(void)setUid:(NSString *)aUid;
-(void)setAuthToken:(NSString *)aToken;
-(NSString *)authToken;
-(void)createAuthToken;
-(NSTimeInterval)timeoutInterval;
-(void)facebookRequestFailed:(NSError *)error;
-(void)facebookResponseReceived:(NSXMLDocument *)xml;
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
		[self setAuthToken:nil];
		[self setSessionKey:nil];
		[self setSessionSecret:nil];
		[self setUid:nil];
		[self setConnectionTimeoutInterval:5.0];
		hasAuthToken = FALSE;
		hasSessionKey = FALSE;
		hasSessionSecret = FALSE;
		hasUid = FALSE;
		userHasLoggedInMultipleTimes = FALSE;
		_delegate = aDelegate;
		_alertMessagesEnabled = YES;
		_shouldUseSynchronousLogin = NO;
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
		[self setAuthToken:nil];
		[self setSessionKey:nil];
		[self setSessionSecret:nil];
		[self setUid:nil];
		[self setConnectionTimeoutInterval:5.0];
		hasAuthToken = FALSE;
		hasSessionKey = FALSE;
		hasSessionSecret = FALSE;
		hasUid = FALSE;
		userHasLoggedInMultipleTimes = FALSE;
		_delegate = aDelegate;
		_alertMessagesEnabled = YES;
		_shouldUseSynchronousLogin = NO;
	}
	return self;
}

-(void)dealloc
{
	[apiKey release];
	[secretKey release];
	[authToken release];
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

-(void)setAuthToken:(NSString *)aToken
{
	aToken = [aToken copy];
	[authToken release];
	authToken = aToken;
	hasAuthToken = TRUE;
	
}
-(NSString *)authToken
{
	return authToken;
}

-(void)setConnectionTimeoutInterval:(double)aConnectionTimeoutInterval
{
	connectionTimeoutInterval = aConnectionTimeoutInterval;
}
-(NSTimeInterval)connectionTimeoutInterval
{
	return connectionTimeoutInterval;
}

-(void)setAlertsEnabled:(BOOL)aBool
{
	_alertMessagesEnabled = aBool;
}

-(BOOL)alertsEnabled
{
	return _alertMessagesEnabled;
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

-(void)showFacebookLoginWindow
{
	loginWindow = [[MKLoginWindow alloc] initWithDelegate:self withSelector:@selector(getAuthSession)]; //will be released when closed			
	[[loginWindow window] center];
	[loginWindow showWindow:self];
	[self createAuthToken];
}

-(NSWindow *)showFacebookLoginWindowForSheet
{
	loginWindow = [[MKLoginWindow alloc] initForSheetWithDelegate:self withSelector:@selector(getAuthSession)]; //will be released when closed 				
	[self createAuthToken];
	return [loginWindow window];
}

//called when login window is created, if an authToken is generated the login window will display
-(void)createAuthToken
{
	if(_shouldUseSynchronousLogin == YES)
	{
		NSXMLDocument *xml = [self fetchFacebookData:[self generateFacebookURL:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.auth.createToken", @"method", nil]]];
		[self facebookResponseReceived:xml];
	}else
	{
		[loginWindow displayLoadingWindowIndicator];
		MKFacebookRequest *request = [[[MKFacebookRequest alloc] init] autorelease];
		[request setDelegate:self];
		[request setFacebookConnection:self];
		[request setSelector:@selector(facebookResponseReceived:)];
		
		NSMutableDictionary *parameters = [[[NSMutableDictionary alloc] init] autorelease];
		[parameters setValue:@"facebook.auth.createToken" forKey:@"method"];
		[request setParameters:parameters];
		[request sendRequest];
	}

}

//called when login window is closed, attempts create and save a session
-(void)getAuthSession
{
	if(hasAuthToken)
	{
		if(_shouldUseSynchronousLogin == YES)
		{
			NSXMLDocument *xml = [self fetchFacebookData:[self generateFacebookURL:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.auth.getSession", @"method", [self authToken], @"auth_token", nil]]];
			[self facebookResponseReceived:xml];
		}else
		{
			MKFacebookRequest *request = [[[MKFacebookRequest alloc] init] autorelease];
			[request setDelegate:self];
			[request setFacebookConnection:self];
			[request setSelector:@selector(facebookResponseReceived:)];
			
			NSMutableDictionary *parameters = [[[NSMutableDictionary alloc] init] autorelease];
			[parameters setValue:@"facebook.auth.getSession" forKey:@"method"];
			[parameters setValue:[self authToken] forKey:@"auth_token"];
			
			[request setParameters:parameters];
			[request sendRequest];
		}
	}
}

//originally written by Josh Wiseman (Facebook, Inc.) and distributed with the iPhoto plugin. modifications made by Mike Kinney 
-(BOOL)loadPersistentSession
{
	//userHasLoggedInMultipleTimes, it's set to TRUE in resetFacebookConnection used to prevent persistent session from loading if a user as logged out but the application hasn't written the NSUserDefaults yet
	if (userHasLoggedInMultipleTimes) {
		return NO;
	}
	
	NSDictionary *domain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:defaultsName];
	NSString *key = (NSString *)[domain objectForKey:@"sessionKey"];
	NSString *secret = (NSString *)[domain objectForKey:@"sessionSecret"];
	
	if (!key || [key isEqualTo:@""] || !secret || [secret isEqualTo:@""]) {
		return NO;
	}
	

	[self setSessionKey:key];
	[self setSessionSecret:secret];

	//
	//MKFacebookRequest *request = [[[MKFacebookRequest alloc] initWithFacebookConnection:self delegate:self selector:@selector(facebookResponseReceived:)] autorelease];
	//[request setParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.users.getLoggedInUser", @"method", nil]];
	//[request sendRequest];
	
	//0.7 we're leaving loading infinite sessions as a synchronous request for now... 
	NSXMLDocument *user = [self fetchFacebookData:[self generateFacebookURL:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.users.getLoggedInUser", @"method", nil]]];
	//NSLog([user description]);
	//0.6 this method shouldn't return true if there was a problem loading the infinite session.  now it won't.  Thanks Adam.
	if([user validFacebookResponse] == NO)
	{
		[self resetFacebookConnection];
		return NO;
	}
	[self setUid:[[user rootElement] stringValue]];
	hasUid = YES;
	hasSessionKey = YES;
	hasSessionSecret = YES;
	
	// we don't really have a token, but it doesn't matter since we have a session
	hasAuthToken = YES;
	
	if([_delegate respondsToSelector:@selector(userLoginSuccessful)])
		[_delegate performSelector:@selector(userLoginSuccessful)];
	
	return YES;
}

-(void)clearInfiniteSession
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sessionKey"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"secretKey"];
	[[NSUserDefaults standardUserDefaults] synchronize];
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
	[mutableDictionary setValue:MKFacebookFormat forKey:@"format"];
	
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
	[mutableDictionary setValue:MKFacebookFormat forKey:@"format"];
	
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


- (NSString *)generateSigForParameters:(NSDictionary *)parameters
{
	//sort our dictionary of arguments
	//somehow the first array that comes from the dictionary doesn't get sorted! so we have to sort that array!
	//6.23.07 this problem has been here since the beginning, when are we going to fix it?
	NSArray *sortedParameters1 = [NSArray arrayWithArray:[parameters keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)]];
	NSArray *sortedParameters = [NSArray arrayWithArray:[sortedParameters1 sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	//now sortedParameters is finally sorted correctly
	NSMutableString *tempString = [[[NSMutableString alloc] init] autorelease]; 
	NSEnumerator *enumerator =[sortedParameters objectEnumerator];
	id anObject; //keys of sortedParameters
	while(anObject = [enumerator nextObject])
	{
		[tempString appendString:anObject];
		[tempString appendString:@"="];
		[tempString appendString:[parameters valueForKey:anObject]];
	}
	//NSLog(tempString);
	//methods except these require we use the secretKey that was assigned during login, not our original one
	if([[parameters valueForKey:@"method"] isEqualTo:@"facebook.auth.getSession"] || [[parameters valueForKey:@"method"] isEqualTo:@"facebook.auth.createToken"])
	{
		[tempString appendString:[self secretKey]];
	}else
	{
		[tempString appendString:[self sessionSecret]];
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
	NSError *fetchError;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:urlRequest
												 returningResponse:&xmlResponse
															 error:&fetchError];

	if(fetchError != nil)
	{
		if(_alertMessagesEnabled == YES)
			[self displayGeneralAPIError:@"Network Problems?" message:@"I can't seem to talk to Facebook.com right now.  This is a problem." buttonTitle:@"Fine!" details:nil];
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
	//NSLog([xml description]);
	//NSDictionary *xmlResponse = [[xml rootElement] dictionaryFromXMLElement];
	
	if([xml validFacebookResponse] == NO)
	{
		
		if([_delegate respondsToSelector:@selector(userLoginFailed)])
			[_delegate performSelector:@selector(userLoginFailed)];
		
		if([_delegate respondsToSelector:@selector(facebookAuthenticationError:)])
			[_delegate performSelector:@selector(facebookAuthenticationError:) withObject:[[xml rootElement] dictionaryFromXMLElement]];
		
		
		if(_alertMessagesEnabled == YES)
		{
			[self displayGeneralAPIError:@"API Problems?" message:@"Facebook didn't give us the token we needed.  You can try again if you want but consider this login attempt defeated." buttonTitle:@"Fine!" details:nil];
		}
		return;
	}
	
	//we only get to the following methods if there was no error in the facebook response.  we "shouldn't" need to check for problems in the xml below...
	if([[[xml rootElement] name] isEqualTo:@"auth_createToken_response"])
	{
		[self setAuthToken:[[xml rootElement] stringValue]];
		hasAuthToken = TRUE;
		NSMutableString *loginString = [[NSMutableString alloc] initWithString:MKLoginUrl];
		[loginString appendString:@"?api_key="];
		[loginString appendString:[self apiKey]];
		[loginString appendString:@"&auth_token="];
		[loginString appendString:[self authToken]];
		[loginString appendString:@"&v="];
		[loginString appendString:MKFacebookAPIVersion];
		[loginString appendString:@"&popup"];
		[loginString appendString:@"&skipcookie"];
		[loginWindow hideLoadingWindowIndicator];
		[loginWindow loadURL:[NSURL URLWithString:loginString]];
		[loginString release];
		return;
	}
	
	if([[[xml rootElement] name] isEqualTo:@"auth_getSession_response"])
	{
		
		NSDictionary *response = [[xml rootElement] dictionaryFromXMLElement];
		
		BOOL useInfiniteSessions = NO;
		//NSLog([response description]);
		if([response valueForKey:@"session_key"] != @"")
		{
			[self setSessionKey:[response valueForKey:@"session_key"]];
			hasSessionKey = YES;			
		}
		
		if([response valueForKey:@"secret"] != @"")
		{
			[self setSessionSecret:[response valueForKey:@"secret"]];
			hasSessionSecret = YES;			
		}
		
		if([response valueForKey:@"uid"] != @"")
		{
			[self setUid:[response valueForKey:@"uid"]];
			hasUid = YES;						
		}
		
		//this seems to return zero sparatically, did facebook change something or is something broken?
		if([[response valueForKey:@"expires"] intValue] == 0)
			useInfiniteSessions = YES;
		
		if([self userLoggedIn])
		{
			if([defaultsName isNotEqualTo:@""] && useInfiniteSessions)
			{
				//NSDictionary *sessionDefaults = [NSDictionary dictionaryWithObjectsAndKeys:[self sessionKey], @"sessionKey", [self sessionSecret], @"sessionSecret", nil];
				//[[NSUserDefaults standardUserDefaults] setPersistentDomain:sessionDefaults forName:defaultsName];
				
				//this is safer than setpersistentDomain which can screw up other things.  0.7.4.
				[[NSUserDefaults standardUserDefaults] setObject:[self sessionKey] forKey:@"sessionKey"];
				[[NSUserDefaults standardUserDefaults] setObject:[self sessionSecret] forKey:@"sessionSecret"];
			}
			
			if([_delegate respondsToSelector:@selector(userLoginSuccessful)])
				[_delegate performSelector:@selector(userLoginSuccessful)];
			
		}
		else
		{
			
			[self resetFacebookConnection];
			
			if([_delegate respondsToSelector:@selector(userLoginFailed)])
				[_delegate performSelector:@selector(userLoginFailed)];
			
			if(_alertMessagesEnabled == YES)
			{
				[self displayGeneralAPIError:@"Whoa there, what happened?" message:@"Something went wrong trying to obtain a session from Facebook.  You will need to try to login again." buttonTitle:@"Fine!" details:nil];
			}
			
		}
		return;
	
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
	if(hasAuthToken && hasSessionKey && hasSessionSecret && hasUid) //then it's kinda safe to assume we're logged in.....
	{
		return TRUE;
	}else
	{
		return FALSE;
	}
	
}

-(void)resetFacebookConnection
{
	[self setAuthToken:nil];
	[self setSessionKey:nil];
	[self setSessionSecret:nil];
	[self setUid:nil];
	hasAuthToken = FALSE;
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
		if([self alertsEnabled] == YES)
		{
			[self displayGeneralAPIError:@"No user logged in!" message:@"Permissions cannnot be extended if no one is logged in." buttonTitle:@"OK Fine!" details:nil];			
		}
		return;
	}
	
	loginWindow = [[MKLoginWindow alloc] initWithDelegate:self withSelector:nil]; //will be released when closed			
	[loginWindow showWindow:self];
	[loginWindow setWindowSize:NSMakeSize(800, 600)];
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/authorize.php?api_key=%@&v=%@&ext_perm=%@", [self apiKey], MKFacebookAPIVersion, aString]];
	[loginWindow loadURL:url];
	
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



