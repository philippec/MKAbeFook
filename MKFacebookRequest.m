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
#import "JSON.h"
#import "NSDictionaryAdditions.h"


NSString *MKFacebookRequestActivityStarted = @"MKFacebookRequestActivityStarted";
NSString *MKFacebookRequestActivityEnded = @"MKFacebookRequestActivityEnded";


@implementation MKFacebookRequest

@synthesize connectionTimeoutInterval;
@synthesize method;
@synthesize responseFormat;
@synthesize rawResponse;

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
		_urlRequestType = MKFacebookRequestTypePOST;
		responseFormat = MKFacebookRequestResponseFormatXML;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayAPIErrorAlert = NO;
		_numberOfRequestAttempts = 5;
		_session = [MKFacebookSession sharedMKFacebookSession];
		self.connectionTimeoutInterval = 30;
		self.method = nil;
		rawResponse = nil;
		
		defaultResponseSelector = @selector(facebookRequest:responseReceived:);
		defaultErrorSelector = @selector(facebookRequest:errorReceived:);
		defaultFailedSelector = @selector(facebookRequest:failed:);
		
		deprecatedResponseSelector = @selector(facebookResponseReceived:);
		deprecatedErrorSelector = @selector(facebookErrorResponseReceived:);
		deprecatedFailedSelector = @selector(facebookRequestFailed:);
		
	}
	return self;
}


- (id)initWithDelegate:(id)aDelegate selector:(SEL)aSelector
{

	self = [self init];
	if(self != nil)
	{
		[self setDelegate:aDelegate];
		if(aSelector != nil)
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
	[method release];
	[rawResponse release];
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
	[_parameters addEntriesFromDictionary:parameters];
}


- (void)setURLRequestType:(MKFacebookRequestType)urlRequestType
{
	_urlRequestType = urlRequestType;
}


- (MKFacebookRequestType)urlRequestType
{
	return _urlRequestType;
}


-(void)setRequestFormat:(MKFacebookRequestResponseFormat)requestFormat
{
	responseFormat = requestFormat;
}


- (void)sendRequest:(NSString *)aMethod withParameters:(NSDictionary *)parameters{
	self.method = aMethod;
	[self setParameters:parameters];
	[self sendRequest];
}

- (void)sendRequestWithParameters:(NSDictionary *)parameters{
	[self setParameters:parameters];
	[self sendRequest];
}

- (void)sendRequest
{	
	//all requests require a method of some sort
	if (self.method == nil && [_parameters valueForKey:@"method"] == nil) {
		NSException *exception = [NSException exceptionWithName:@"Missing Method" reason:@"No method was found. Set the property or include a 'method' key in the parameters dictionary." userInfo:nil];
		[exception raise];
		return;
	}

	//prefer to use the property if possible
	if (self.method != nil) {
		[_parameters setValue:self.method forKey:@"method"];
	}
	
	//set the method property so it can easily be retrieved by delegates
	if (self.method == nil) {
		self.method = [_parameters valueForKey:@"method"];
	}

	
	//if no user is logged in and they're trying to send a request OTHER than something required for logging in a user abort the request
	if(!_session.validSession && (![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] && ![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"]))
	{
		
		NSError *error = [NSError errorWithDomain:@"MKAbeFook" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"No user is logged in.", @"Error", nil]];
		if([_delegate respondsToSelector:defaultFailedSelector])
		{
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:defaultFailedSelector]];
			[invocation setTarget:_delegate];
			[invocation setSelector:defaultFailedSelector];
			[invocation setArgument:&self atIndex:2];
			[invocation setArgument:&error atIndex:3];
			[invocation invoke];
		}else if ([_delegate respondsToSelector:deprecatedFailedSelector]) {
			[_delegate performSelector:deprecatedFailedSelector withObject:error];
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
	
	NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	NSString *applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *userAgent;
	if(applicationName != nil && applicationVersion != nil)
		userAgent = [NSString stringWithFormat:@"%@ %@", applicationName, applicationVersion];
	else
		userAgent = @"MKAbeFook";
	
	
	_requestIsDone = NO;
	if(_urlRequestType == MKFacebookRequestTypePOST)
	{
		//NSLog([_facebookConnection description]);
		NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:_requestURL 
																	 cachePolicy:NSURLRequestReloadIgnoringCacheData 
																 timeoutInterval:[self connectionTimeoutInterval]];
		
		[postRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		
		NSMutableData *postBody = [NSMutableData data];
		NSString *stringBoundary = [NSString stringWithString:@"xXxiFyOuTyPeThIsThEwOrLdWiLlExPlOdExXx"];
		NSData *endLineData = [[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding];
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
		[postRequest setHTTPMethod:@"POST"];
		[postRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
		[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];

		//add items that are required by all requests to _parameters dictionary so they are added to the postRequest and we can easily make a sig from them
		[_parameters setValue:MKFacebookAPIVersion forKey:@"v"];
		[_parameters setValue:[_session apiKey] forKey:@"api_key"];

		switch (self.responseFormat) {
			case MKFacebookRequestResponseFormatXML:
				[_parameters setValue:@"XML" forKey:@"format"];
				break;
			case MKFacebookRequestResponseFormatJSON:
				[_parameters setValue:@"JSON" forKey:@"format"];
				break;
			default:
				[_parameters setValue:@"XML" forKey:@"format"];
				break;
		}
		
		
		
		//all other methods require call_id and session_key.
		if(![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || ![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
		{
			[_parameters setValue:[_session sessionKey] forKey:@"session_key"];
			[_parameters setValue:[self generateTimeStamp] forKey:@"call_id"];
		}

		
		
		//if parameters contains a NSImage or NSData object we need store the key so it can be removed from the _parameters dictionary before a signature is generated for the request
		NSString *imageKey = nil;
		NSString *dataKey = nil;

		//in order to allow NSArrays containing strings instead of @"one,two,three" string lists - we will grab the original _parameters key and put they key=>newly generated string from the array in the arrayKeysAndValues dictionary so we can create a valid signature later
		NSMutableDictionary *arrayKeysAndValues = [[[NSMutableDictionary alloc] init] autorelease];
		
		for(id key in [_parameters allKeys])
		{
			
			if([[_parameters objectForKey:key] isKindOfClass:[NSImage class]])
			{
				NSData *resizedTIFFData = [[_parameters objectForKey:key] TIFFRepresentation];
				NSBitmapImageRep *resizedImageRep = [NSBitmapImageRep imageRepWithData: resizedTIFFData];
				NSDictionary *imageProperties = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat: 1.0] forKey:NSImageCompressionFactor];
				NSData *imageData = [resizedImageRep representationUsingType: NSJPEGFileType properties: imageProperties];
				
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"image\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];	
				[postBody appendData: imageData];
				[postBody appendData:endLineData];
				
				//we need to remove this the image object from the dictionary so we can generate a correct sig from the other values, but we can't do it here or leopard will complain.  so we'll do it outside the loop.
				//[_parameters removeObjectForKey:key];
				imageKey = [NSString stringWithString:key];

			}
			else if( [[_parameters objectForKey:key] isKindOfClass:[NSData class]] ){
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"data\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[NSString stringWithString:@"Content-Type: content/unknown\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];	
				[postBody appendData:(NSData *)[_parameters objectForKey:key]];
				[postBody appendData:endLineData];
				dataKey = [NSString stringWithString:key];
				
			}
			else if ([[_parameters objectForKey:key] isKindOfClass:[NSArray class]])
			{
				NSString *stringFromArray = [[_parameters objectForKey:key] componentsJoinedByString:@","];
				//items we find in the array must go back into the _parameters dictionary so a valid signature can be generated. we'll put it in a temporary dictionary for now and swap them when we're done looping through _parameters
				if(stringFromArray != nil)
				{
					DLog(@"setting %@ for key: %@", stringFromArray, key);
					[arrayKeysAndValues setObject:stringFromArray forKey:key];
				}
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[stringFromArray dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:endLineData];
			}
			else
			{
			 
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[_parameters valueForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:endLineData];
			}
			 
		}
		//0.7.1 fix.  we can't remove this during the while loop so we'll do it here
		if(imageKey != nil)
			[_parameters removeObjectForKey:imageKey];
		
		if (dataKey != nil)
			[_parameters removeObjectForKey:dataKey];
		
		//if a NSArray was passed in instead of a @"one,two,three" list we need to swap the value in _parameters with the componentsSeparatedByString value we created in the while loop above so a valid signature can be generated
		if([arrayKeysAndValues count] > 0)
		{
			for(id arrayKey in [arrayKeysAndValues allKeys])
			{
				DLog(@"resetting %@ for key %@", [arrayKeysAndValues valueForKey:arrayKey], arrayKey);
				[_parameters setObject:[arrayKeysAndValues valueForKey:arrayKey] forKey:arrayKey];
			}
		}
			
		
		[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"sig\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[self generateSigForParameters:_parameters] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:endLineData];
		
		[postRequest setHTTPBody:postBody];
		theConnection = [NSURLConnection connectionWithRequest:postRequest delegate:self];
	}
	
	if(_urlRequestType == MKFacebookRequestTypeGET)
	{
		DLog(@"using get request");
		NSURL *theURL = [self generateFacebookURL:_parameters];
		
		NSMutableURLRequest *getRequest = [NSMutableURLRequest requestWithURL:theURL 
																  cachePolicy:NSURLRequestReloadIgnoringCacheData 
															  timeoutInterval:[self connectionTimeoutInterval]];
		[getRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		
		theConnection = [NSURLConnection connectionWithRequest:getRequest delegate:self];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"MKFacebookRequestActivityStarted" object:nil];
	 
}


- (void)cancelRequest
{
	if(_requestIsDone == NO)
	{
		//NSLog(@"cancelling request...");
		[theConnection cancel];
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
	DLog(@"generating sig for parameters: %@", [parameters description]);
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
	NSMutableDictionary *newParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
	if(aMethodName == nil)
	{
		aMethodName = @"";
	}
	[newParams setValue:aMethodName forKey:@"method"];
	return [self generateFacebookURL:newParams];
}


- (NSURL *)generateFacebookURL:(NSDictionary *)parameters
{
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:parameters];
	//these will be here for all requests. 
	[mutableDictionary setValue:MKFacebookAPIVersion forKey:@"v"];
	[mutableDictionary setValue:[_session apiKey] forKey:@"api_key"];
	[mutableDictionary setValue:MKFacebookDefaultResponseFormat forKey:@"format"];
	
	//all other methods require call_id and session_key
	if(![[mutableDictionary valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || ![[mutableDictionary valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
	{
		[mutableDictionary setValue:[_session sessionKey] forKey:@"session_key"];
		[mutableDictionary setValue:[self generateTimeStamp] forKey:@"call_id"];
	}
	
	NSMutableString *urlString = [[[NSMutableString alloc] initWithString:MKAPIServerURL] autorelease];
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
	
	
	NSError *error = nil;
	//assume the response is not valid until we can verify it is good
	BOOL validResponse = NO;

	
	//turn the response into a string so we can parse it if it's JSON or turn it into NSXML if we're expecting XML
	NSString *responseString = [[[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding] autorelease];

	
	if (responseString != nil && [responseString length] > 0) {
		validResponse = YES;
		rawResponse = [responseString copy];
	}else {
		rawResponse = nil;
	}


	
	if (self.responseFormat == MKFacebookRequestResponseFormatXML && validResponse == YES) {
		
		NSXMLDocument *returnXML = [[[NSXMLDocument alloc] initWithXMLString:responseString options:0 error:&error] autorelease];
		
		if (error != nil) {
			validResponse = NO;
		}
		
		
		//facebook has returned an error of some kind. evaluate the error and try resending the request if possible
		if([returnXML validFacebookResponse] == NO)
		{
			NSDictionary *errorDictionary = [[returnXML rootElement] dictionaryFromXMLElement];
			//4 is a magic number that represents "The application has reached the maximum number of requests allowed. More requests are allowed once the time window has completed."
			//luckily for us Facebook doesn't define "the time window".
			//we will also try the request again if we see a 1 (unknown) or 2 (service unavailable) error
			int errorInt = [[errorDictionary valueForKey:@"error_code"] intValue];
			if((errorInt == 4 || errorInt == 1 || errorInt == 2 ) && _numberOfRequestAttempts <= _requestAttemptCount)
			{
				NSDate *sleepUntilDate = [[NSDate date] addTimeInterval:2.0];
				[NSThread sleepUntilDate:sleepUntilDate];
				[_responseData setData:[NSData data]];
				_requestAttemptCount++;
				DLog(@"Too many requests, waiting just a moment....%@", [self description]);
				[self sendRequest];
				return;
			}
			//DLog(@"I give up, the request has been attempted %i times but it just won't work. Here is the failed request: %@", _requestAttemptCount, [_parameters description]);
			//we've tried the request a few times, now we're giving up.
			validResponse = NO;
		}else
		{
			//the response we have received from facebook is valid, pass it back to the delegate.
			if([_delegate respondsToSelector:_selector]){
				[_delegate performSelector:_selector withObject:returnXML];
			}else if ([_delegate respondsToSelector:defaultResponseSelector]) {
				NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:defaultResponseSelector]];
				[invocation setTarget:_delegate];
				[invocation setSelector:defaultResponseSelector];
				[invocation setArgument:&self atIndex:2];
				[invocation setArgument:&returnXML atIndex:3];
				[invocation invoke];
			}else if ([_delegate respondsToSelector:deprecatedResponseSelector]) {
				[_delegate performSelector:deprecatedResponseSelector withObject:returnXML];
			}
		}	
		
	}
	
	

	
	
	if (self.responseFormat == MKFacebookRequestResponseFormatJSON && validResponse == YES) {
		id returnJSON = [responseString JSONValue];

		if ([returnJSON isKindOfClass:[NSDictionary class]] || [returnJSON isKindOfClass:[NSArray class]]) {

			//JSON returning a NSDictionary can be good or bad because errors are turned into dictionaries.
			if ([returnJSON isKindOfClass:[NSDictionary class]])
			{
				//DLog(@"JSON response parsed to dictionary");
				if ([returnJSON validFacebookResponse] == YES) {
					validResponse = YES;
				}else{
					//DLog(@"invalid facebook response received");
					validResponse = NO;
					//exactly like the XML part, check for error 4, 1, or 2 (defined above in the XML handling part)
					int errorInt = [[returnJSON valueForKey:@"error_code"] intValue];
					if((errorInt == 4 || errorInt == 1 || errorInt == 2 ) && _numberOfRequestAttempts <= _requestAttemptCount)
					{
						NSDate *sleepUntilDate = [[NSDate date] addTimeInterval:2.0];
						[NSThread sleepUntilDate:sleepUntilDate];
						[_responseData setData:[NSData data]];
						_requestAttemptCount++;
						DLog(@"Too many requests, waiting just a moment....%@", [self description]);
						[self sendRequest];
						return;
					}
					//DLog(@"I give up, the request has been attempted %i times but it just won't work. Here is the failed request: %@", _requestAttemptCount, [_parameters description]);

				} //end checking / handling a NSDictionary for a valid or failed response
				
			}else if ([returnJSON isKindOfClass:[NSArray class]]) {
				//if the JSON parses out to an array i think it can only mean it's valid...
				validResponse = YES;
			}
			
			//response appears to be valid, return it to the delegate either via a specified selector or the default selector
			if (validResponse == YES) {
				//DLog(@"JSON looks good, trying to pass back to the delegate");
				if ([_delegate respondsToSelector:_selector]) {
					[_delegate performSelector:_selector withObject:returnJSON];
				}else if ([_delegate respondsToSelector:defaultResponseSelector]) {
					NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:defaultResponseSelector]];
					[invocation setTarget:_delegate];
					[invocation setSelector:defaultResponseSelector];
					[invocation setArgument:&self atIndex:2];
					[invocation setArgument:&returnJSON atIndex:3];
					[invocation invoke];
				}else if ([_delegate respondsToSelector:deprecatedResponseSelector]) {
					[_delegate performSelector:deprecatedResponseSelector withObject:returnJSON];
				}		
			}
			
			//DLog(@"returnJSON class: %@", [returnJSON className]);
			//DLog(@"parsed JSON: %@", [returnJSON description]);
		}
	}
	
	

	
	if (validResponse == NO) {
		
		MKFacebookResponseError *responseError = [MKFacebookResponseError errorFromRequest:self];
		DLog(@"Facebook Error Code: %i", responseError.errorCode);
		DLog(@"Facebook Error Message: %@", responseError.errorMessage);
		DLog(@"Facebook Error Arguments: %@", [responseError.requestArgs description]);
		
		if ([self displayAPIErrorAlert] == YES) {
			NSString *errorString = @"Unknown Error";
			
			if (self.rawResponse == nil) {
				errorString = [NSString stringWithString:@"Facebook did not return any data that could be interpreted as JSON or XML. Services may be unavailable."];				
			}else {
				errorString = [NSString stringWithString:@"Facebook returned an error."];
			}

			MKErrorWindow *errorWindow = [MKErrorWindow errorWindowWithTitle:@"API Error" 
																	 message:errorString 
																	 details:rawResponse];
			[errorWindow display];
		}

		
		//pass the error back to the delegate
		if([_delegate respondsToSelector:defaultErrorSelector])
		{
			
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:defaultErrorSelector]];
			[invocation setTarget:_delegate];
			[invocation setSelector:defaultErrorSelector];
			[invocation setArgument:&self atIndex:2];
			[invocation setArgument:&responseError atIndex:3];
			[invocation invoke];
		}else if ([_delegate respondsToSelector:deprecatedErrorSelector]) {
			[_delegate performSelector:deprecatedErrorSelector withObject:rawResponse];
		}
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
	
	if([_delegate respondsToSelector:defaultFailedSelector])
	{
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:defaultFailedSelector]];
		[invocation setTarget:_delegate];
		[invocation setSelector:defaultFailedSelector];
		[invocation setArgument:&self atIndex:2];
		[invocation setArgument:&error atIndex:3];
		[invocation invoke];
	}else if ([_delegate respondsToSelector:deprecatedFailedSelector]) {
		[_delegate performSelector:deprecatedFailedSelector withObject:error];
	}
		
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MKFacebookRequestActivityEnded" object:self];
}


//only works in 10.6
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten 
											   totalBytesWritten:(NSInteger)totalBytesWritten 
									   totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
	SEL forwardSelector = @selector(facebookRequest:bytesWritten:totalBytesWritten:totalBytesExpectedToWrite:);
	if ([_delegate respondsToSelector:forwardSelector]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:forwardSelector]];
		[invocation setTarget:_delegate];
		[invocation setSelector:forwardSelector];
		[invocation setArgument:&self atIndex:2];
		[invocation setArgument:&bytesWritten atIndex:3];
		[invocation setArgument:&totalBytesWritten atIndex:4];
		[invocation setArgument:&totalBytesExpectedToWrite atIndex:5];
		[invocation invoke];
	}
}

#pragma mark -


@end
