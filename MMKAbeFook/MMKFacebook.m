/*
 
 MMKFacebook.m
 Mobile MKAbeFook

 Created by Mike on 3/28/2008.

 Copyright (c) 2009, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "MMKFacebook.h"
#import "MMKFacebookRequest.h"
#include <CommonCrypto/CommonHMAC.h> //might not be documented but we need this for creating md5 hashes, thanks Spotlight!
#include "CXMLDocument.h"
#include "CXMLDocumentAdditions.h"
#include "CXMLElementAdditions.h"


NSString *MKAPIServerURL = @"http://api.facebook.com/restserver.php";
NSString *MKLoginUrl = @"http://www.facebook.com/login.php"; //it would be nice to use http://m.facebook.com/login.php but it doesn't work on the device?  wtf?
NSString *MMKFacebookAPIVersion = @"1.0";
NSString *MMKFacebookFormat = @"XML";



@interface MMKFacebook (Private)
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
-(void)facebookResponseReceived:(CXMLDocument *)xml;
-(void)returnUserToApplication;
@end


@implementation MMKFacebook

#pragma mark Intialization

+(MMKFacebook *)facebookWithAPIKey:(NSString *)anAPIKey withSecret:(NSString *)aSecret delegate:(id)aDelegate
{
	return [[[MMKFacebook alloc] initUsingAPIKey:anAPIKey usingSecret:aSecret delegate:(id)aDelegate] autorelease];
}


-(MMKFacebook *)initUsingAPIKey:(NSString *)anAPIKey usingSecret:(NSString *)aSecret delegate:(id)aDelegate
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
		_defaultsName = [[NSBundle mainBundle] bundleIdentifier];
		[self setApiKey:anAPIKey];
		[self setSecretKey:aSecret];
		[self setAuthToken:@"none"];
		[self setSessionKey:nil];
		[self setSessionSecret:nil];
		[self setUid:nil];
		[self setConnectionTimeoutInterval:5.0];
		_hasAuthToken = NO;
		_hasSessionKey = NO;
		_hasSessionSecret = NO;
		_hasUid = NO;
		_userHasLoggedInMultipleTimes = NO;
		_delegate = aDelegate;
		_alertMessagesEnabled = YES;
		_shouldUseSynchronousLogin = NO;
	}
	return self;
}



-(void)dealloc
{
	[_apiKey release];
	[_secretKey release];
	[_authToken release];
	[_sessionKey release];
	[_sessionSecret release];
	[_uid release];
	[super dealloc];
}
#pragma mark -

//TODO: use properties!
#pragma mark Setters and Getters
-(void)setSecretKey:(NSString *)aSecretKey
{
	aSecretKey = [aSecretKey copy];
	[_secretKey release];
	_secretKey = aSecretKey;
}

-(NSString *)secretKey
{
	return _secretKey;
}

-(void)setApiKey:(NSString *)anApiKey
{
	anApiKey = [anApiKey copy];
	[_apiKey release];
	_apiKey = anApiKey;
}

-(NSString *)apiKey
{
	return _apiKey;
}

-(void)setSessionKey:(NSString *)aSessionKey
{
	aSessionKey = [aSessionKey copy];
	[_sessionKey release];
	_sessionKey = aSessionKey;
}

-(NSString *)sessionKey
{
	return _sessionKey;
}

-(void)setSessionSecret:(NSString *)aSessionSecret
{
	aSessionSecret = [aSessionSecret copy];
	[_sessionSecret release];
	_sessionSecret = aSessionSecret;
}

-(NSString *)sessionSecret
{
	return _sessionSecret;
}

-(void)setUid:(NSString *)aUid
{
	aUid = [aUid copy];
	[_uid release];
	_uid = aUid;
}

-(NSString *)uid
{
	return _uid;
}

-(void)setAuthToken:(NSString *)aToken
{
	aToken = [aToken copy];
	[_authToken release];
	_authToken = aToken;
	_hasAuthToken = TRUE;
	
}
-(NSString *)authToken
{
	return _authToken;
}

-(id)delegate
{
	return _delegate;
}

-(void)setConnectionTimeoutInterval:(double)aConnectionTimeoutInterval
{
	_connectionTimeoutInterval = aConnectionTimeoutInterval;
}

-(NSTimeInterval)connectionTimeoutInterval
{
	return _connectionTimeoutInterval;
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

#pragma mark Login Stuff

//this method just flips the view and requests an auth token from facebook.  if a valid token is returned to facebookResponseReceived: it loads the login page.
-(void)showFacebookLoginWindow
{
	if(![_delegate respondsToSelector:@selector(applicationView)])
	{
		NSException *exception = [NSException exceptionWithName:@"InvalidDelegate"
														 reason:@"Delegate requires -(UIView *)applicationView method" 
													   userInfo:nil];
		
		[exception raise];
		return;
	}
	
	//tell the login window to call getAuthSession: just as it is flipping back to the application view
	_loginViewController = [[MMKLoginViewController alloc] initWithDelegate:self withSelector:@selector(getAuthSession)];	
	_navigationController = [[UINavigationController alloc] initWithRootViewController:_loginViewController];
	
	[self createAuthToken];
		
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:[_delegate applicationView] cache:NO];
	
	[[_delegate applicationView] addSubview:[_navigationController view]];
	
	[UIView commitAnimations];
	
}

//called when login window is created, if an authToken is passed back to facebookResponseReceived: it will load the login window
-(void)createAuthToken
{
	if(_shouldUseSynchronousLogin == YES)
	{
		CXMLDocument *xml = [self fetchFacebookData:[self generateFacebookURL:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.auth.createToken", @"method", nil]]];
		[self facebookResponseReceived:xml];
	}else
	{
		MMKFacebookRequest *request = [[[MMKFacebookRequest alloc] init] autorelease];
		[request setDelegate:self];
		[request setFacebookConnection:self];
		[request setDisplayAPIErrorAlert:NO];
		
		NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
		[parameters setValue:@"facebook.auth.createToken" forKey:@"method"];
		
		[request setParameters:parameters];
		[request displayLoadingSheet:NO];
		[request sendRequest];
		[parameters release];
	}
}

//called when login window is closed, attempts to create and save a session
-(void)getAuthSession
{
	if(_hasAuthToken)
	{
		if(_shouldUseSynchronousLogin == YES)
		{
			CXMLDocument *xml = [self fetchFacebookData:[self generateFacebookURL:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.auth.getSession", @"method", [self authToken], @"auth_token", nil]]];
			[self facebookResponseReceived:xml];
		}else
		{
			MMKFacebookRequest *request = [[[MMKFacebookRequest alloc] init] autorelease];
			[request setDelegate:self];
			[request setFacebookConnection:self];
			[request setDisplayAPIErrorAlert:NO];
			
			NSMutableDictionary *parameters = [[[NSMutableDictionary alloc] init] autorelease];
			[parameters setValue:@"facebook.auth.getSession" forKey:@"method"];
			[parameters setValue:[self authToken] forKey:@"auth_token"];

			[request displayLoadingSheet:NO];
			[request setParameters:parameters];
			[request sendRequest];
		}
	}else
	{
		[self returnUserToApplication];
	}
}

//originally written by Josh Wiseman (Facebook, Inc.) and distributed with the iPhoto plugin. modifications made by Mike Kinney 
-(BOOL)loadPersistentSession
{
	//_userHasLoggedInMultipleTimes, it's set to TRUE in resetFacebookConnection used to prevent persistent session from loading if a user as logged out but the application hasn't written the NSUserDefaults yet
	if (_userHasLoggedInMultipleTimes) {
		return NO;
	}
	
	NSDictionary *domain = [[NSUserDefaults standardUserDefaults] persistentDomainForName:_defaultsName];
	NSString *key = (NSString *)[domain objectForKey:@"sessionKey"];
	NSString *secret = (NSString *)[domain objectForKey:@"sessionSecret"];
	
	if (!key || [key isEqualToString:@""] || !secret || [secret isEqualToString:@""]) {
		return NO;
	}
	

	[self setSessionKey:key];
	[self setSessionSecret:secret];

	//
	//MMKFacebookRequest *request = [[[MMKFacebookRequest alloc] initWithFacebookConnection:self delegate:self selector:@selector(facebookResponseReceived:)] autorelease];
	//[request setParameters:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.users.getLoggedInUser", @"method", nil]];
	//[request sendRequest];
	
	//0.7 we're leaving loading infinite sessions as a synchronous request for now... 
	CXMLDocument *user = [self fetchFacebookData:[self generateFacebookURL:[NSDictionary dictionaryWithObjectsAndKeys:@"facebook.users.getLoggedInUser", @"method", nil]]];
	//NSLog([user description]);
	//0.6 this method shouldn't return true if there was a problem loading the infinite session.  now it won't.  Thanks Adam.
	if([user validFacebookResponse] == NO)
	{
		[self resetFacebookConnection];
		return NO;
	}
	[self setUid:[[user rootElement] stringValue]];
	_hasUid = YES;
	_hasSessionKey = YES;
	_hasSessionSecret = YES;
	
	// we don't really have a token, but it doesn't matter since we have a session
	_hasAuthToken = YES;
	
	if([_delegate respondsToSelector:@selector(userLoginSuccessful)])
		[_delegate performSelector:@selector(userLoginSuccessful)];
	
	if([_delegate respondsToSelector:@selector(returningUserToApplication)])
		[_delegate performSelector:@selector(returningUserToApplication)];
	
	return YES;
}

#pragma mark -

#pragma mark Misc Helpers

-(void)clearInfiniteSession
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sessionKey"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"secretKey"];
	[[NSUserDefaults standardUserDefaults] synchronize]; //probably not needed
	[self resetFacebookConnection];
}

//TODO: find out if we are actually using this, if not delete it!
//generateFacebookURL, generateTimeStamp, and generateSigForParameters used in MMKFacebook.m, MKAsyncRequest.m and MKPhotoUploader.m to prepare urls that are sent to facebook.com
-(NSURL *)generateFacebookURL:(NSString *)aMethodName parameters:(NSDictionary *)parameters
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
	//these will be here for all requests.  we could make the user supply the method in the parameters but i like it as a string
	[mutableDictionary setValue:aMethodName forKey:@"method"];
	[mutableDictionary setValue:MMKFacebookAPIVersion forKey:@"v"];
	[mutableDictionary setValue:[self apiKey] forKey:@"api_key"];
	[mutableDictionary setValue:MMKFacebookFormat forKey:@"format"];
	
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
		if(![key isEqualToString:@"method"]) //remember we already did this one
			[urlString appendFormat:@"&%@=%@", key, [mutableDictionary valueForKey:key]];
	}			
	[urlString appendFormat:@"&sig=%@", [self generateSigForParameters:mutableDictionary]];
	return [NSURL URLWithString:[[urlString encodeURLLegally] autorelease]];
}

// duh, generates appropriate url
-(NSURL *)generateFacebookURL:(NSDictionary *)parameters
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
	//these will be here for all requests. 
	[mutableDictionary setValue:MMKFacebookAPIVersion forKey:@"v"];
	[mutableDictionary setValue:[self apiKey] forKey:@"api_key"];
	[mutableDictionary setValue:MMKFacebookFormat forKey:@"format"];
	
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
		if([[mutableDictionary objectForKey:key] isKindOfClass:[UIImage class]])
			[mutableDictionary removeObjectForKey:key];
		
		if(![key isEqualToString:@"method"]) //remember we already did this one
			[urlString appendFormat:@"&%@=%@", key, [mutableDictionary valueForKey:key]];
	}			
	[urlString appendFormat:@"&sig=%@", [self generateSigForParameters:mutableDictionary]];
	return [NSURL URLWithString:[[urlString encodeURLLegally] autorelease]];
}

-(NSString *)generateTimeStamp
{
	return [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
}

//sorts parameters keys, creates a string of values, returns md5 hash
- (NSString *)generateSigForParameters:(NSDictionary *)parameters
{
	//sort our dictionary of arguments
	//somehow the first array that comes from the dictionary doesn't get sorted! so we have to sort that array!
	//6.23.07 this problem has been here since the beginning, when are we going to fix it?
	//TODO: FIX THIS! we shouldn't need to sort it twice
	NSArray *sortedParameters1 = [NSArray arrayWithArray:[parameters keysSortedByValueUsingSelector:@selector(caseInsensitiveCompare:)]];
	NSArray *sortedParameters = [NSArray arrayWithArray:[sortedParameters1 sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	//now sortedParameters is finally sorted correctly
	NSMutableString *tempString = [[[NSMutableString alloc] init] autorelease]; 
	NSEnumerator *enumerator =[sortedParameters objectEnumerator];
	NSString *anObject; //keys of sortedParameters
	while(anObject = [enumerator nextObject])
	{
		//prevents attempting to append nil strings.  Thanks Andrei Freeman. 0.4.1
		if((anObject != nil) && ([anObject length] > 0))
		{
			[tempString appendString:anObject];
			[tempString appendString:@"="];
			[tempString appendString:[parameters valueForKey:anObject]];
		}else
		{
			NSArray *objArray = [NSArray arrayWithObjects:parameters, sortedParameters, sortedParameters1, nil];
			NSArray *keyArray = [NSArray arrayWithObjects:@"parameters", @"sortedParameters", @"sortedParameters1", nil];
			NSDictionary *exceptDict = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
			NSException *e = [NSException exceptionWithName:@"genSigForParm" reason:@"Bad Parameter Object" userInfo:exceptDict];
			[e raise];
		}	
	}

	//methods except these require we use the secretKey that was assigned during login, not our original one
	if([[parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || [[parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
	{
		[tempString appendString:[self secretKey]];
	}else
	{
		[tempString appendString:[self sessionSecret]];
	}
	
	return [tempString md5Hash];
}

#pragma mark -

//used for synchronous login requests.  asynchronous requests using MMMKFacebookRequest are better.
-(id)fetchFacebookData:(NSURL *)theURL
{
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:theURL 
												cachePolicy:NSURLRequestReloadIgnoringCacheData
											timeoutInterval:[self connectionTimeoutInterval]];

	//TODO: check response, prompt alert if needed
	//NSHTTPURLResponse *xmlResponse;  //not used right now
	CXMLDocument *returnXML = nil;
	NSError *fetchError;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:urlRequest
												 returningResponse:nil
															 error:&fetchError];

	if(fetchError != nil)
	{
		[self displayGeneralAPIError:nil message:nil buttonTitle:nil];
		return nil;
	}else
	{
		returnXML = [[[CXMLDocument alloc] initWithData:responseData options:0 error:nil] autorelease];
	}
	
	return returnXML;


}

//TODO: allow this to accept title, message, and cancel button title.  use it when we reach a point of no return.
-(void)displayGeneralAPIError:(NSString *)title message:(NSString *)message buttonTitle:(NSString *)buttonTitle
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
	
	UIAlertView *uhOh = [[[UIAlertView alloc] initWithTitle:errorTitle
													message:errorMessage
												   delegate:self 
										  cancelButtonTitle:errorButtonTitle
										  otherButtonTitles:nil] autorelease];
	[uhOh show];
}

-(void)returnUserToApplication
{
	if([_delegate respondsToSelector:@selector(returningUserToApplication)])
		[_delegate performSelector:@selector(returningUserToApplication)];

	//sometimes this doesn't play nicely with the keyboard.  if things crash when the user tries to return to the application while the keyboard is visible comment the next 3 lines out
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:[_delegate applicationView] cache:NO];
	[[_navigationController view] removeFromSuperview];
	[UIView commitAnimations];
	[_navigationController release];
	[_loginViewController release];
	
}

-(void)receivedFacebookXMLErrorResponse:(CXMLDocument *)xml
{
	if([_delegate respondsToSelector:@selector(userLoginFailed)])
		[_delegate performSelector:@selector(userLoginFailed)];
		
	if(_alertMessagesEnabled == YES)
	{			
		[self displayGeneralAPIError:nil message:@"Authentication Error" buttonTitle:nil];
	}
	
	[self returnUserToApplication];
	return;
}

//this is kind of clunky.  here we handle all requests used for login.
//TODO: split this up into multiple methods and assign each request selector appropriately.
-(void)facebookResponseReceived:(CXMLDocument *)xml
{

	//we only get to the following methods if there was no error in the facebook response.  we "shouldn't" need to check for problems in the xml below...
	if([[[xml rootElement] name] isEqualToString:@"auth_createToken_response"])
	{
		[self setAuthToken:[[xml rootElement] stringValue]];
		_hasAuthToken = TRUE;
		NSMutableString *loginString = [[NSMutableString alloc] initWithString:MKLoginUrl];
		[loginString appendString:@"?api_key="];
		[loginString appendString:[self apiKey]];
		[loginString appendString:@"&auth_token="];
		[loginString appendString:[self authToken]];
		[loginString appendString:@"&v="];
		[loginString appendString:MMKFacebookAPIVersion];
		[loginString appendString:@"&popup"];
		[loginString appendString:@"&skipcookie"];
		[_loginViewController loadURL:[NSURL URLWithString:loginString]];
		[loginString release];
		return;
	}
	
	if([[[xml rootElement] name] isEqualToString:@"auth_getSession_response"])
	{
		//NSLog(@"got here");
		NSDictionary *response = [[xml rootElement] dictionaryFromXMLElement];
		//NSLog([response description]);
		BOOL useInfiniteSessions = NO;
		//NSLog([response description]);
		if([response valueForKey:@"session_key"] != @"")
		{
			[self setSessionKey:[response valueForKey:@"session_key"]];
			_hasSessionKey = YES;			
		}
		
		if([response valueForKey:@"secret"] != @"")
		{
			[self setSessionSecret:[response valueForKey:@"secret"]];
			_hasSessionSecret = YES;			
		}
		
		if([response valueForKey:@"uid"] != @"")
		{
			[self setUid:[response valueForKey:@"uid"]];
			_hasUid = YES;						
		}
		
		//this seems to return zero sparatically, did facebook change something or is something broken?
		if([[response valueForKey:@"expires"] intValue] == 0)
			useInfiniteSessions = YES;
		
		//TODO: this isn't all neccesary now because we know that we will only get to this method if facebook returns a valid resposne.  error checking should be moved to facebookErrorResponseReceived
		if([self userLoggedIn])
		{
			if(![_defaultsName isEqualToString:@""] && useInfiniteSessions)
			{
				//NSDictionary *sessionDefaults = [NSDictionary dictionaryWithObjectsAndKeys:[self sessionKey], @"sessionKey", [self sessionSecret], @"sessionSecret", nil];
				//[[NSUserDefaults standardUserDefaults] setPersistentDomain:sessionDefaults forName:_defaultsName];
				
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
				[self displayGeneralAPIError:nil message:@"Something went wrong trying to obtain a session from Facebook." buttonTitle:nil];
			}
			
		}
		
		[self returnUserToApplication];
		
		return;
	
	}
}

-(void)facebookErrorResponseReceived:(id)response
{
	NSLog(@"received error");
	if(_alertMessagesEnabled == YES)
	{
		[self displayGeneralAPIError:nil message:@"Something went wrong during the login..." buttonTitle:nil];
	}
	[self returnUserToApplication];
}

-(BOOL)userLoggedIn
{
	if(_hasAuthToken && _hasSessionKey && _hasSessionSecret && _hasUid) //then it's kinda safe to assume we're logged in.....
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
	_hasAuthToken = NO;
	_hasSessionKey = NO;
	_hasSessionSecret = NO;
	_hasUid = NO;
	_userHasLoggedInMultipleTimes = TRUE; //used to prevent persistent session from loading if a user as logged out but the application hasn't written the NSUserDefaults yet.  this doesn't make sense, we can write the NSUserDefaults to disk anytime we wish, what's the logic behind this? Do we really need this?
}


//TODO: flip application view and display browser that loads appropriate url to modify extended permissions

-(void)grantExtendedPermission:(NSString *)aString
{
	if([self userLoggedIn] == NO)
	{
		if([self alertsEnabled] == YES)
		{
			UIAlertView *uhOh = [[[UIAlertView alloc] initWithTitle:@"No user logged in!" 
															message:@"Permissions cannot be extended if no one is logged in." 
														   delegate:nil 
												  cancelButtonTitle:@"Fine!" 
												  otherButtonTitles:nil] autorelease];
			[uhOh show];
		}
		return;
	}
	
	_loginViewController = [[MMKLoginViewController alloc] initWithDelegate:self withSelector:@selector(returnUserToApplication)];	
	_navigationController = [[UINavigationController alloc] initWithRootViewController:_loginViewController];
	
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:[_delegate applicationView] cache:NO];
	
	[[_delegate applicationView] addSubview:[_navigationController view]];
	
	[UIView commitAnimations];
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/authorize.php?api_key=%@&v=%@&ext_perm=%@", [self apiKey], MMKFacebookAPIVersion, aString]];
	[_loginViewController loadURL:url];
	
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

//borrowed from CocoaCryptoHashing categories
//created by Denis Defreyne released under FreeBSD License
-(NSString *)md5Hash
{
	NSData *tempData = [self dataUsingEncoding:NSUTF8StringEncoding];
	
	unsigned char digest[16];
	char finaldigest[32];
	int i;
	
	CC_MD5([tempData bytes],[tempData length],digest);
	for(i=0;i<16;i++) sprintf(finaldigest+i*2,"%02x",digest[i]);
	
	return [NSString stringWithCString:finaldigest length:32];
}

@end



