//
//  MKFacebookRequestQueue.m
//  MKAbeFook
//
//  Created by Mike Kinney on 12/12/07.
/*
 Copyright (c) 2009, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "MKFacebookRequestQueue.h"

@interface MKFacebookRequestQueue (Private)

- (void)startNextRequest;

- (void)continueQueue;

@end


@implementation MKFacebookRequestQueue

- (id)init
{
	self = [super init];
	if (self != nil) {
		_requestsArray = [[NSMutableArray alloc] init];
		_cancelRequestQueue = NO;
		_currentRequest = 0;
		_timeBetweenRequests = 1.0;
	}
	return self;
}


- (id)initWithRequests:(NSArray *)requests
{
	self = [super init];
	if(self != nil)
	{
		_requestsArray = [[NSMutableArray arrayWithArray:requests] retain];
		_cancelRequestQueue = NO;
		_currentRequest = 0;
		_timeBetweenRequests = 1.0;
	}
	return self;
}


- (void)dealloc
{
	[_requestsArray release];
	[super dealloc];
}


- (void)setRequests:(NSArray *)requests
{
	[_requestsArray release];
	_requestsArray = [[NSMutableArray arrayWithArray:requests] retain];
}


- (void)setDelegate:(id)delegate
{
	_delegate = delegate;
}


- (void)addRequest:(MKFacebookRequest *)request
{
	[_requestsArray addObject:request];
}

- (void)startRequestQueue
{
	 _cancelRequestQueue = NO;
	[self startNextRequest];	
}

#pragma mark Private Methods

- (void)startNextRequest
{
	if(_currentRequest < [_requestsArray count] && _cancelRequestQueue == NO && [_requestsArray count] != 0 )
	{
		if ([_delegate respondsToSelector:@selector(requestQueue:activeRequest:ofRequests:)]) {
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:@selector(requestQueue:activeRequest:ofRequests:)]];
			[invocation setTarget:_delegate];
			[invocation setSelector:@selector(requestQueue:activeRequest:ofRequests:)];
			[invocation setArgument:&self atIndex:2];
			[invocation setArgument:&_currentRequest atIndex:3];
			NSUInteger count = [_requestsArray count];
			[invocation setArgument:&count atIndex:4];
			[invocation invoke];
		}
		
		[[_requestsArray objectAtIndex:_currentRequest] setDelegate:self];
		[[_requestsArray objectAtIndex:_currentRequest] sendRequest];
		DLog(@"request started");
	}
	_currentRequest++;
}

- (void)continueQueue{
	if(_currentRequest < [_requestsArray count] && _cancelRequestQueue == NO && [_requestsArray count] != 0)
	{
		if(_shouldPauseBetweenRequests == YES)
		{
			NSDate *sleepUntilDate = [[NSDate date] addTimeInterval:_timeBetweenRequests];
			[NSThread sleepUntilDate:sleepUntilDate];			
		}
		[self startNextRequest];
	}
	else
	{
		DLog(@"no more requests");
		_currentRequest = 0;
		[_requestsArray removeAllObjects];
		
		if ([_delegate respondsToSelector:@selector(requestQueueDidFinish:)]) {
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:@selector(requestQueueDidFinish:)]];
			[invocation setTarget:_delegate];
			[invocation setSelector:@selector(requestQueueDidFinish:)];
			[invocation setArgument:&self atIndex:2];
			[invocation invoke];
		}
	
	}	
}

#pragma mark -

- (void)setShouldPauseBetweenRequests:(BOOL)aBool
{
	_shouldPauseBetweenRequests = aBool;
}

- (float)timeBetweenRequests
{
	return _timeBetweenRequests;
}

- (void)setTimeBetweenRequests:(float)waitTime
{
	_timeBetweenRequests = waitTime;
}

- (void)cancelRequestQueue
{
	if(_currentRequest < [_requestsArray count])
	{
		[[_requestsArray objectAtIndex:_currentRequest] cancelRequest];
		_cancelRequestQueue = YES;
		[_requestsArray removeAllObjects];
	}
}

#pragma mark MKFacebookRequestDelegate Methods

/*
 The queue needs to know when a requests finishes. It may be successful, contain an error, or fail completely. No matter what it does we'll forward the response back to the delegate and continue the queue.
 */
- (void)facebookRequest:(MKFacebookRequest *)request responseReceived:(id)response{
	
	if ([_delegate respondsToSelector:@selector(facebookRequest:responseReceived:)]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:@selector(facebookRequest:responseReceived:)]];
		[invocation setTarget:_delegate];
		[invocation setSelector:@selector(facebookRequest:responseReceived:)];
		[invocation setArgument:&request atIndex:2];
		[invocation setArgument:&response atIndex:3];
		[invocation invoke];
	}
	
	[self continueQueue];
}

- (void)facebookRequest:(MKFacebookRequest *)request errorReceived:(MKFacebookResponseError *)error{
	if ([_delegate respondsToSelector:@selector(facebookRequest:errorReceived:)]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:@selector(facebookRequest:errorReceived:)]];
		[invocation setTarget:_delegate];
		[invocation setSelector:@selector(facebookRequest:errorReceived:)];
		[invocation setArgument:&request atIndex:2];
		[invocation setArgument:&error atIndex:3];
		[invocation invoke];
	}
	[self continueQueue];
}

- (void)facebookRequest:(MKFacebookRequest *)request failed:(NSError *)error{
	if ([_delegate respondsToSelector:@selector(facebookRequest:failed:)]) {
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[_delegate methodSignatureForSelector:@selector(facebookRequest:failed:)]];
		[invocation setTarget:_delegate];
		[invocation setSelector:@selector(facebookRequest:failed:)];
		[invocation setArgument:&request atIndex:2];
		[invocation setArgument:&error atIndex:3];
		[invocation invoke];
	}
	[self continueQueue];
}

#pragma mark -


@end
