/*
Copyright (c) 2007, Mike Kinney
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the 
following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the 
following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/
//
//  MKAsyncRequest.m
//  MKAbeFook
//
//  Created by Mike on 3/8/07.
//  Copyright 2007 Mike Kinney. All rights reserved.
//

#import "MKAsyncRequest.h"


@implementation MKAsyncRequest

-(MKAsyncRequest *)initWithFacebookConnection:(MKFacebook *)aFacebookConnection 
					   delegate:(id)aDelegate 
					   selector:(SEL)aSelector
{
	//if(![aFacebookConnection userLoggedIn])
	//{
		//hmm what should we do here?
	//}

	self = [super init];
	facebookConnection = aFacebookConnection;
	_delegate = aDelegate;
	_selector = aSelector;
	_shouldReleaseWhenFinished = YES;
	responseData = [[NSMutableData alloc] init];
	return self;
}

-(void)dealloc
{
	[responseData release];
	[super dealloc];
}

+(void)fetchFacebookData:(NSString *)aMethodName parameters:(NSDictionary *)parameters facebookConnection:aFacebookConnection delegate:(id)aDelegate selector:(SEL)aSelector
{
	self = [[MKAsyncRequest alloc] initWithFacebookConnection:aFacebookConnection
													 delegate:aDelegate
													 selector:aSelector];
	
	NSURL *theURL = [aFacebookConnection generateFacebookURL:aMethodName parameters:parameters];
	

	//0.6 now uses connectionTimeoutInterval from aFacebookConnection.  Thanks Adam.
	NSURLRequest *request = [NSURLRequest requestWithURL:theURL 
											 cachePolicy:NSURLRequestReloadIgnoringCacheData 
										 timeoutInterval:[aFacebookConnection connectionTimeoutInterval]];
	
	[NSURLConnection connectionWithRequest:request
								  delegate:self];
}

-(void)fetchFacebookData:(NSString *)aMethodName parameters:(NSDictionary *)parameters
{
	_shouldReleaseWhenFinished = NO;
	_requestIsDone = NO;
	NSURL *theURL = [facebookConnection generateFacebookURL:aMethodName parameters:parameters];
	NSURLRequest *request = [NSURLRequest requestWithURL:theURL
											 cachePolicy:NSURLRequestReloadIgnoringCacheData
											 timeoutInterval:[facebookConnection connectionTimeoutInterval]];
	dasConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSXMLDocument *returnXML = [[[NSXMLDocument alloc] initWithData:responseData
														   options:nil
															 error:nil] autorelease];
	/*	
	if(![facebookConnection validXMLResponse:returnXML])
	{
		if([_delegate respondsToSelector:@selector(receivedFacebookXMLErrorResponse:)])
			[_delegate performSelector:@selector(receivedFacebookXMLErrorResponse:) withObject:returnXML];
	}
	*/
	
	if([_delegate respondsToSelector:_selector])
		[_delegate performSelector:_selector withObject:returnXML];
	
	 
	//if we're just doing one request we release ourself when we're done
	if(_shouldReleaseWhenFinished == YES)
	{
		[self release];
	}else //otherwise we need to keep ourself around and clean up our data instance variable
	{
		[responseData setData:[NSData data]];
		_requestIsDone = YES;
	}
}

-(void)cancel
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
	/* i like this better.  we'll switch to this eventually
	if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
	 */
	
	if([_delegate respondsToSelector:@selector(asyncRequestFailed:)])
		[_delegate performSelector:@selector(asyncRequestFailed:) withObject:error];
}


@end
