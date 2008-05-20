/*
 
 MMKFacebook.m
 Mobile MKAbeFook

 Created by Mike on 3/28/2008.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import "MMKFacebook.h"
#import "MMKFacebookRequest.h"
#include <CommonCrypto/CommonHMAC.h>
#include "CXMLDocument.h"
#include "CXMLDocumentAdditions.h"
#include "CXMLElementAdditions.h"


NSString *MKAPIServerURL = @"http://api.facebook.com/restserver.php";
NSString *MKLoginUrl = @"http://www.facebook.com/login.php";
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
-(void)facebookRequestFailed:(NSError *)error;
-(void)facebookResponseReceived:(CXMLDocument *)xml;
-(void)displayGeneralAPIError;
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
		[self setAuthToken:nil];
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


//this doesn't actually show the login window.  it just starts the process.  see facebookResponseReceived to see the window being displayed.
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
	
	_loginViewController = [[MMKLoginViewController alloc] initWithDelegate:self withSelector:@selector(getAuthSession:)];	
	_navigationController = [[UINavigationController alloc] initWithRootViewController:_loginViewController];
	[self createAuthToken];
		
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:[_delegate applicationView] cache:NO];
	
	[[_delegate applicationView] addSubview:[_navigationController view]];
	
	[UIView commitAnimations];
	
}

//called when login window is created, if an authToken is generated the login window will display
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
		[request setSelector:@selector(facebookResponseReceived:)];
		
		NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
		[parameters setValue:@"facebook.auth.createToken" forKey:@"method"];
		[request setParameters:parameters];
		[request sendRequest];
		[parameters release];
	}

}

//called when login window is closed, attempts create and save a session
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
			[request setSelector:@selector(facebookResponseReceived:)];
			
			NSMutableDictionary *parameters = [[[NSMutableDictionary alloc] init] autorelease];
			[parameters setValue:@"facebook.auth.getSession" forKey:@"method"];
			[parameters setValue:[self authToken] forKey:@"auth_token"];
			
			[request setParameters:parameters];
			[request sendRequest];
		}
	}else
	{
		//[self displayGeneralAPIError];
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
	
	if (!key || [key isEqualTo:@""] || !secret || [secret isEqualTo:@""]) {
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
	
	return YES;
}

-(void)clearInfiniteSession
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"sessionKey"];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"secretKey"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self resetFacebookConnection];
}

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
	
	
	return [tempString md5Hash];
}

-(id)fetchFacebookData:(NSURL *)theURL
{
	NSURLRequest *urlRequest = [NSURLRequest requestWithURL:theURL 
												cachePolicy:NSURLRequestReloadIgnoringCacheData
											timeoutInterval:[self connectionTimeoutInterval]];
	NSHTTPURLResponse *xmlResponse;  //not used right now
	CXMLDocument *returnXML = nil;
	NSError *fetchError;
	NSData *responseData = [NSURLConnection sendSynchronousRequest:urlRequest
												 returningResponse:&xmlResponse
															 error:&fetchError];

	if(fetchError != nil)
	{
		[self facebookRequestFailed:nil];		   
		return nil;
	}else
	{
		returnXML = [[[CXMLDocument alloc] initWithData:responseData options:0 error:nil] autorelease];
	}
	
	return returnXML;


}

-(void)displayGeneralAPIError
{
	UIAlertView *uhOh = [[[UIAlertView alloc] initWithTitle:@"API Problems?" 
													message:@"Facebook didn't give us the token we needed.  You can try again if you want but consider this login attempt defeated." 
												   delegate:self 
										  cancelButtonTitle:@"Fine!" 
										  otherButtonTitles:nil] autorelease];
	[uhOh show];
}

-(void)returnUserToApplication
{
	//return user to application
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1.0];
	[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:[_delegate applicationView] cache:NO];
	
	
	[[_navigationController view] removeFromSuperview];
	[_navigationController release];
	[_loginViewController release];
	
	[UIView commitAnimations];
}

-(void)facebookResponseReceived:(CXMLDocument *)xml
{
	//NSLog([xml description]);
	//NSDictionary *xmlResponse = [[xml rootElement] dictionaryFromXMLElement];
	
	//NSLog([xmlResponse description]);
	
	//NSLog(@"incoming xml retainCount : %i", [xml retainCount]);
	
	if([xml validFacebookResponse] == NO)
	{
		
		if([_delegate respondsToSelector:@selector(userLoginFailed)])
			[_delegate performSelector:@selector(userLoginFailed)];
		
		if([_delegate respondsToSelector:@selector(facebookAuthenticationError:)])
			[_delegate performSelector:@selector(facebookAuthenticationError:) withObject:[[xml rootElement] dictionaryFromXMLElement]];
		
		
		if(_alertMessagesEnabled == YES)
		{			
			[self displayGeneralAPIError];
		}
		[self returnUserToApplication];
		return;
	}
	
	//we only get to the following methods if there was no error in the facebook response.  we "shouldn't" need to check for problems in the xml below...
	if([[[xml rootElement] name] isEqualTo:@"auth_createToken_response"])
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
	
	if([[[xml rootElement] name] isEqualTo:@"auth_getSession_response"])
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
		
		if([self userLoggedIn])
		{
			if([_defaultsName isNotEqualTo:@""] && useInfiniteSessions)
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
				
				UIAlertView *uhOh = [[[UIAlertView alloc] initWithTitle:@"Whoah there, what happened?" 
																message:@"Something went wrong trying to obtain a session from Facebook.  Try again." 
															   delegate:nil 
													  cancelButtonTitle:@"Fine!" 
													  otherButtonTitles:nil] autorelease];
				[uhOh show];
			}
			
		}
		
		[self returnUserToApplication];
		
		return;
	
	}
}

//this will be called if asynchronous requests fail. or if fetchFacebookData: encounters a network connection problem
-(void)facebookRequestFailed:(NSError *)error
{
	if(_alertMessagesEnabled == YES)
	{
		UIAlertView *uhOh = [[[UIAlertView alloc] initWithTitle:@"Network Problems?" 
														message:@"I can't seem to talk to Facebook.com right now." 
													   delegate:nil 
											  cancelButtonTitle:@"Fine!" 
											  otherButtonTitles:nil] autorelease];
		[uhOh show];
	}
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
/*
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
	
	_loginViewController = [[MKLoginWindow alloc] initWithDelegate:self withSelector:nil]; //will be released when closed			
	[_loginViewController showWindow:self];
	[_loginViewController setWindowSize:NSMakeSize(800, 600)];
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/authorize.php?api_key=%@&v=%@&ext_perm=%@", [self apiKey], MMKFacebookAPIVersion, aString]];
	[_loginViewController loadURL:url];
	
}
 */

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



