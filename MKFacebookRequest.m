// 
//  MKFacebookRequest.m
//  MKAbeFook
//
//  Created by Mike on 12/15/07.
/*
 Copyright (c) 2009, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "MKFacebookRequest.h"
#import "NSStringExtras.h"
#import "NSXMLDocumentAdditions.h"
#import "NSXMLElementAdditions.h"
#import "MKErrorWindow.h"
#import "CocoaCryptoHashing.h"

NSString *MKFacebookRequestActivityStarted = @"MKFacebookRequestActivityStarted";
NSString *MKFacebookRequestActivityEnded = @"MKFacebookRequestActivityEnded";

@implementation MKFacebookRequest

@synthesize connectionTimeoutInterval;

#pragma mark init methods
+ (id)requestWithDelegate:(id)aDelegate
{
	MKFacebookRequest *theRequest = [[[MKFacebookRequest alloc] initWithDelegate:aDelegate selector:nil] autorelease];
	return theRequest;	
}


+ (id)requestWithDelegate:(id)aDelegate selector:(SEL)aSelector
{
	MKFacebookRequest *theRequest = [[[MKFacebookRequest alloc] initWithDelegate:aDelegate selector:aSelector] autorelease];
	return theRequest;
}


- (id)init
{
	self = [super init];
	if(self != nil)
	{
		_delegate = nil;
		_selector = nil;
		
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary alloc] init];
		_urlRequestType = MKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayAPIErrorAlert = NO;
		_numberOfRequestAttempts = 5;
		_session = [MKFacebookSession sharedMKFacebookSession];
		self.connectionTimeoutInterval = 5;
		
	}
	return self;
}


- (id)initWithDelegate:(id)aDelegate selector:(SEL)aSelector
{

	self = [self init];
	if(self != nil)
	{
		[self setDelegate:aDelegate];
		if(aSelector == nil)
			[self setSelector:@selector(facebookResponseReceived:)];
		else
			[self setSelector:aSelector];
	}
	return self;
}


- (id)initWithParameters:(NSDictionary *)parameters delegate:(id)aDelegate selector:(SEL)aSelector{
	
	self = [self initWithDelegate:aDelegate selector:aSelector];
	if(self != nil)
	{
		
	}
	return self;
}


-(void)dealloc
{
	[_requestURL release];
	[_parameters release];
	[_responseData release];
	[super dealloc];
}
#pragma mark -


#pragma mark Instance Methods
- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}


- (id)delegate
{
	return _delegate;
}


- (void)setSelector:(SEL)selector
{
	_selector = selector;
}


- (void)setParameters:(NSDictionary *)parameters
{
	[_parameters addEntriesFromDictionary:parameters]; //fixes memory leak 0.7.4 - mike
}


- (void)setURLRequestType:(MKFacebookRequestType)urlRequestType
{
	_urlRequestType = urlRequestType;
}


- (MKFacebookRequestType)urlRequestType
{
	return _urlRequestType;
}


- (void)sendRequest
{
	//if no user is logged in and they're trying to send a request OTHER than something required for logging in a user abort the request
	if(!_session.validSession && (![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] && ![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"]))
	{
		
		if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		{
			NSError *error = [NSError errorWithDomain:@"MKAbeFook" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"No user is logged in.", @"Error", nil]];
			[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
		}
		
		if (_displayAPIErrorAlert == YES) {
			MKErrorWindow *errorWindow = [MKErrorWindow errorWindowWithTitle:@"Invalid Session" message:@"A request could not be completed because no user is logged in" details:[NSString stringWithFormat:@"Request Details: \n\n%@", [_parameters description]]];
			[errorWindow display];
		}

		
		NSException *exception = [NSException exceptionWithName:@"Invalid Facebook Connection"
														 reason:@"MKFacebookRequest could not continue because no user is logged in.  Request has been aborted."
													   userInfo:nil];
		
		[exception raise];
		
		
		return;
	}
	
	
	//NSLog(@"sending request to: %@", [_requestURL description]);
	
	if([_parameters count] == 0)
	{
		if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		{
			NSError *error = [NSError errorWithDomain:@"MKAbeFook" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"No Parameters Specified", @"Error", nil]];
			[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
		}
		
		return;
	}
		
	NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	NSString *applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *userAgent;
	if(applicationName != nil && applicationVersion != nil)
		userAgent = [NSString stringWithFormat:@"%@ %@", applicationName, applicationVersion];
	else
		userAgent = @"MKAbeFook";
	
	
	_requestIsDone = NO;
	if(_urlRequestType == MKPostRequest)
	{
		//NSLog([_facebookConnection description]);
		NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:_requestURL 
																	 cachePolicy:NSURLRequestReloadIgnoringCacheData 
																 timeoutInterval:[self connectionTimeoutInterval]];
		
		[postRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		
		NSMutableData *postBody = [NSMutableData data];
		NSString *stringBoundary = [NSString stringWithString:@"xXxiFyOuTyPeThIsThEwOrLdWiLlExPlOdExXx"];
		NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary]; //make this here so we only have to do it once and not during every loop
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
		[postRequest setHTTPMethod:@"POST"];
		[postRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
		[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

		//add items that are required by all requests to _parameters dictionary so they are added to the postRequest and we can easily make a sig from them
		[_parameters setValue:MKFacebookAPIVersion forKey:@"v"];
		[_parameters setValue:[_session apiKey] forKey:@"api_key"];
		[_parameters setValue:MKFacebookResponseFormat forKey:@"format"];
		
		
		//all other methods require call_id and session_key.
		if(![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || ![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
		{
			[_parameters setValue:[_session sessionKey] forKey:@"session_key"];
			[_parameters setValue:[self generateTimeStamp] forKey:@"call_id"];
		}

		
		
		NSEnumerator *e = [_parameters keyEnumerator];
		id key;
		NSString *imageKey = nil; //apparently G4s don't like it when you don't at least set this to = nil.  0.7.3 fix.
		while(key = [e nextObject])
		{
			
			if([[_parameters objectForKey:key] isKindOfClass:[NSImage class]])
			{
				NSData *resizedTIFFData = [[_parameters objectForKey:key] TIFFRepresentation];
				NSBitmapImageRep *resizedImageRep = [NSBitmapImageRep imageRepWithData: resizedTIFFData];
				NSDictionary *imageProperties = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat: 1.0] forKey:NSImageCompressionFactor];
				NSData *imageData = [resizedImageRep representationUsingType: NSJPEGFileType properties: imageProperties];
				
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"something\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];	
				[postBody appendData: imageData];
				[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
				
				//we need to remove this the image object from the dictionary so we can generate a correct sig from the other values, but we can't do it here or leopard will complain.  so we'll do it OUTSIDE the while loop.
				//[_parameters removeObjectForKey:key];
				imageKey = [NSString stringWithString:key];

			}else
			{
			 
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[_parameters valueForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];				
			}
			 
		}
		//0.7.1 fix.  we can't remove this during the while loop so we'll do it here
		if(imageKey != nil)
			[_parameters removeObjectForKey:imageKey];
		
		[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"sig\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[self generateSigForParameters:_parameters] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
		
		[postRequest setHTTPBody:postBody];
		dasConnection = [NSURLConnection connectionWithRequest:postRequest delegate:self];
	}
	
	if(_urlRequestType == MKGetRequest)
	{
		NSLog(@"using get request");
		NSURL *theURL = [self generateFacebookURL:_parameters];
		
		NSMutableURLRequest *getRequest = [NSMutableURLRequest requestWithURL:theURL 
																  cachePolicy:NSURLRequestReloadIgnoringCacheData 
															  timeoutInterval:[self connectionTimeoutInterval]];
		[getRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		
		dasConnection = [NSURLConnection connectionWithRequest:getRequest delegate:self];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"MKFacebookRequestActivityStarted" object:nil];
	 
}


- (void)cancelRequest
{
	if(_requestIsDone == NO)
	{
		//NSLog(@"cancelling request...");
		[dasConnection cancel];
		_requestIsDone = YES;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MKFacebookRequestActivityEnded" object:nil];
}


- (void)setDisplayAPIErrorAlert:(BOOL)aBool
{
	_displayAPIErrorAlert = aBool;
}


- (BOOL)displayAPIErrorAlert
{
	return _displayAPIErrorAlert;
}


- (void)setNumberOfRequestAttempts:(int)requestAttempts
{
	_numberOfRequestAttempts = requestAttempts;
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
		if([_session secretKey] != nil)
			[tempString appendString:[_session secretKey]];
		else
		{			
			NSException *e = [NSException exceptionWithName:@"genSigForParm" reason:@"nil secret key, is your application type set to Desktop?" userInfo:nil];
			[e raise];
		}
	}else
	{
		//DLog(@"sessionSecret");
		if([_session sessionSecret] != nil && [[_session sessionSecret] length] > 0)
			[tempString appendString:[_session sessionSecret]];
		else
		{
			NSException *e = [NSException exceptionWithName:@"genSigForParm" reason:@"nil session secret, is your application type set to Desktop?" userInfo:nil];
			[e raise];
			
		}
	}
	
	return [tempString md5HexHash];
}


- (NSString *)generateTimeStamp
{
	return [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
}


- (NSURL *)generateFacebookURL:(NSString *)aMethodName parameters:(NSDictionary *)parameters
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
	//these will be here for all requests.  we could make the user supply the method in the parameters but i like it as a string
	[mutableDictionary setValue:aMethodName forKey:@"method"];
	[mutableDictionary setValue:MKFacebookAPIVersion forKey:@"v"];
	[mutableDictionary setValue:[_session apiKey] forKey:@"api_key"];
	[mutableDictionary setValue:MKFacebookResponseFormat forKey:@"format"];
	
	//all other methods require call_id and session_key
	if(![aMethodName isEqualToString:@"facebook.auth.getSession"] || ![aMethodName isEqualToString:@"facebook.auth.createToken"])
	{
		[mutableDictionary setValue:[_session sessionKey] forKey:@"session_key"];
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


- (NSURL *)generateFacebookURL:(NSDictionary *)parameters
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
	//these will be here for all requests. 
	[mutableDictionary setValue:MKFacebookAPIVersion forKey:@"v"];
	[mutableDictionary setValue:[_session apiKey] forKey:@"api_key"];
	[mutableDictionary setValue:MKFacebookResponseFormat forKey:@"format"];
	
	//all other methods require call_id and session_key
	if(![[mutableDictionary valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || ![[mutableDictionary valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
	{
		[mutableDictionary setValue:[_session sessionKey] forKey:@"session_key"];
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


- (id)fetchFacebookData:(NSURL *)theURL
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
		if(_displayAPIErrorAlert == YES)
		{
			MKErrorWindow *errorWindow = [MKErrorWindow errorWindowWithTitle:@"Network Problems?" message:@"I can't seem to talk to Facebook.com right now." details:[fetchError description]];
			[errorWindow display];
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
#pragma mark -


#pragma mark NSURLConnection Delegate Methods
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_responseData appendData:data];
}

//responses are ONLY passed back if they do not contain any errors
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MKFacebookRequestActivityEnded" object:nil];
	
	NSError *error;
	NSXMLDocument *returnXML = [[[NSXMLDocument alloc] initWithData:_responseData
															options:0
															  error:&error] autorelease];
	if(error != nil)
	{
		MKErrorWindow *errorWindow = [MKErrorWindow errorWindowWithTitle:@"API Error" message:@"Facebook returned puke, the API might be down." details:[[error userInfo] description]];
		[errorWindow display];
	}else if([returnXML validFacebookResponse] == NO)
	{
		NSDictionary *errorDictionary = [[returnXML rootElement] dictionaryFromXMLElement];
		//4 is a magic number that represents "The application has reached the maximum number of requests allowed. More requests are allowed once the time window has completed."
		//luckily for us Facebook doesn't define "the time window".  fuckers.
		//we will also try the request again if we see a 1 (unknown) or 2 (service unavailable) error
		int errorInt = [[errorDictionary valueForKey:@"error_code"] intValue];
		if((errorInt == 4 || errorInt == 1 || errorInt == 2 ) && _numberOfRequestAttempts <= _requestAttemptCount)
		{
			NSDate *sleepUntilDate = [[NSDate date] addTimeInterval:2.0];
			[NSThread sleepUntilDate:sleepUntilDate];
			[_responseData setData:[NSData data]];
			_requestAttemptCount++;
			NSLog(@"Too many requests, waiting just a moment....%@", [self description]);
			[self sendRequest];
			return;
		}
		NSLog(@"I GAVE UP!!! throw it away...");
		//we've tried the request a few times, now we're giving up.
		if([_delegate respondsToSelector:@selector(facebookErrorResponseReceived:)])
			[_delegate performSelector:@selector(facebookErrorResponseReceived:) withObject:returnXML];
		
		NSString *errorTitle = [NSString stringWithFormat:@"Error: %@", [errorDictionary valueForKey:@"error_code"]];
		if([self displayAPIErrorAlert])
		{
			MKErrorWindow *errorWindow = [MKErrorWindow errorWindowWithTitle:errorTitle message:[errorDictionary valueForKey:@"error_msg"] details:[errorDictionary description]];
			[errorWindow display];
		}
	}else
	{
		if([_delegate respondsToSelector:_selector])
			[_delegate performSelector:_selector withObject:returnXML];		
	}
	
	
	
	[_responseData setData:[NSData data]];
	_requestIsDone = YES;
	
}

//0.6 suggestion to pass connection error.  Thanks Adam.
-  (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{	
	
	if([self displayAPIErrorAlert])
	{
		MKErrorWindow *errorWindow = [MKErrorWindow errorWindowWithTitle:@"Connection Error" message:@"Are you connected to the internet?" details:[[error userInfo] description]];
		[errorWindow display];
	}
	
	if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MKFacebookRequestActivityEnded" object:self];
}
#pragma mark -


@end
