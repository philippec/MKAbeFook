// 
//  MKFacebookRequest.m
//  MKAbeFook
//
//  Created by Mike on 12/15/07.
/*
 Copyright (c) 2008, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "MKFacebookRequest.h"
#import "MKFacebook.h"
#import "NSXMLDocumentAdditions.h"
#import "NSXMLElementAdditions.h"

@implementation MKFacebookRequest

-(MKFacebookRequest *)init
{
	self = [super init];
	
	if(self != nil)
	{
		//NSLog(@"initiated1");
		
		_facebookConnection = nil;
		_delegate = nil;
		_selector = nil;
		
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary alloc] init];
		_urlRequestType = MKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayGeneralErrors = YES;
		
	}
	return self;
}

-(MKFacebookRequest *)initWithFacebookConnection:(MKFacebook *)aFacebookConnection 
					   delegate:(id)aDelegate 
					   selector:(SEL)aSelector
{
	//if(![aFacebookConnection userLoggedIn])
	//{
		//hmm what should we do here?
	//}

	self = [super init];
	if(self != nil)
	{
		//NSLog(@"initiated2");
		_facebookConnection = [aFacebookConnection retain];
		_delegate = aDelegate;
		_selector = aSelector;
		
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary alloc] init];
		_urlRequestType = MKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayGeneralErrors = YES;
	}
	return self;
}


-(MKFacebookRequest *)initWithFacebookConnection:(MKFacebook *)aFacebookConnection
									  parameters:(NSDictionary *)parameters
										delegate:(id)aDelegate 
										selector:(SEL)aSelector
{
	//if(![aFacebookConnection userLoggedIn])
	//{
	//hmm what should we do here?
	//}
	
	self = [super init];
	if(self != nil)
	{
		_facebookConnection = [aFacebookConnection retain];
		_delegate = aDelegate;
		_selector = aSelector;
		
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary dictionaryWithDictionary:parameters] retain];
		_urlRequestType = MKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayGeneralErrors = YES;
	}
	return self;
}

-(void)setFacebookConnection:(MKFacebook *)aFacebookConnection
{
	_facebookConnection = aFacebookConnection;
}

-(void)setDelegate:(id)delegate
{
	_delegate = delegate;
}

-(void)setSelector:(SEL)selector
{
	_selector = selector;
}

-(void)setURLRequestType:(MKFacebookRequestType)urlRequestType
{
	_urlRequestType = urlRequestType;
}

-(int)urlRequestType
{
	return _urlRequestType;
}

-(void)setParameters:(NSDictionary *)parameters
{
	[_parameters addEntriesFromDictionary:parameters]; //fixes memory leak 0.7.4 - mike
}

-(BOOL)displayGeneralErrors
{
	return _displayGeneralErrors;
}

-(void)setDisplayGeneralErrors:(BOOL)aBool
{
	_displayGeneralErrors = aBool;
}


-(void)dealloc
{
	[_requestURL release];
	[_parameters release];
	[_responseData release];
	[super dealloc];
}

-(void)sendRequest
{
	
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
																 timeoutInterval:[_facebookConnection connectionTimeoutInterval]];
		
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
		[_parameters setValue:[_facebookConnection apiKey] forKey:@"api_key"];
		[_parameters setValue:MKFacebookFormat forKey:@"format"];
		
		//all other methods require call_id and session_key
		if(![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || ![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
		{
			[_parameters setValue:[_facebookConnection sessionKey] forKey:@"session_key"];
			[_parameters setValue:[_facebookConnection generateTimeStamp] forKey:@"call_id"];
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
		[postBody appendData:[[_facebookConnection generateSigForParameters:_parameters] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
		
		[postRequest setHTTPBody:postBody];
		dasConnection = [NSURLConnection connectionWithRequest:postRequest delegate:self];
	}
	
	if(_urlRequestType == MKGetRequest)
	{
		NSURL *theURL = [_facebookConnection generateFacebookURL:_parameters];
		
		NSMutableURLRequest *getRequest = [NSMutableURLRequest requestWithURL:theURL 
																  cachePolicy:NSURLRequestReloadIgnoringCacheData 
															  timeoutInterval:[_facebookConnection connectionTimeoutInterval]];
		[getRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		
		dasConnection = [NSURLConnection connectionWithRequest:getRequest delegate:self];
	}

	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"MKFacebookRequestActivityStarted" object:nil];
	 
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSError *error;
	NSXMLDocument *returnXML = [[[NSXMLDocument alloc] initWithData:_responseData
														   options:0
															 error:&error] autorelease];
	if(error != nil)
	{
		[_facebookConnection displayGeneralAPIError:@"API Error" message:@"Facebook returned puke, the API might be down." buttonTitle:@"OK" details:[[error userInfo] description]];
	}
	else if([returnXML validFacebookResponse] == NO)
	{
		if([_delegate respondsToSelector:@selector(receivedFacebookXMLErrorResponse:)])
			[_delegate performSelector:@selector(receivedFacebookXMLErrorResponse:) withObject:returnXML];
		
		
		//NSLog(@"error: %@", [returnXML description]);
		NSDictionary *errorDictionary = [[returnXML rootElement] dictionaryFromXMLElement];
		NSString *errorTitle = [NSString stringWithFormat:@"Error: %@", [errorDictionary valueForKey:@"error_code"]];
		if([self displayGeneralErrors])
		{
			[_facebookConnection displayGeneralAPIError:errorTitle message:[errorDictionary valueForKey:@"error_msg"] buttonTitle:@"OK" details:[errorDictionary description]];			
		}
	}else
	{
		//finally we can assume it's a successful request and pass it back
		if([_delegate respondsToSelector:_selector])
			[_delegate performSelector:_selector withObject:returnXML];		
	}
	
	[_responseData setData:[NSData data]];
	_requestIsDone = YES;
	
	
}

-(void)cancelRequest
{
	if(_requestIsDone == NO)
	{
		//NSLog(@"cancelling request...");
		[dasConnection cancel];
		_requestIsDone = YES;
	}
}

//0.6 suggestion to pass connection error.  Thanks Adam.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{	
	
	if([self displayGeneralErrors])
	{
		[_facebookConnection displayGeneralAPIError:@"Connection Error" message:@"Are you connected to the interwebs?" buttonTitle:@"OK" details:[[error userInfo] description]];
	}
	
	if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
}


@end
