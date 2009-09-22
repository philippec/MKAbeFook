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


@implementation MKFacebookRequestQueue

+ (MKFacebookRequestQueue *)newQueue
{
	MKFacebookRequestQueue *queue = [[[MKFacebookRequestQueue alloc] initWithRequests:nil] autorelease];
	return queue;
}


+ (MKFacebookRequestQueue *)newQueueWithRequests:(NSArray *)requests
{
	MKFacebookRequestQueue *queue = [[[MKFacebookRequestQueue alloc] initWithRequests:nil] autorelease];
	return queue;	
}

- (id)init
{
	self = [super init];
	if (self != nil) {
		_requestsArray = nil;
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

- (void)setCurrentlySendingSelector:(SEL)selector
{
	_currentlySendingSelector = selector;
}

- (void)setLastRequestResponseSelector:(SEL)selector
{
	_lastRequestResponseSelector = selector;
}

- (void)setAllRequestsFinishedSelector:(SEL)selector
{
	_allRequestsFinishedSelector = selector;
}

- (void)addRequest:(MKFacebookRequest *)request
{
	[_requestsArray addObject:request];
}

- (void)startRequestQueue
{
	[self startNextRequest];	
}

- (void)startNextRequest
{
	if(_currentRequest <= [_requestsArray count] && _cancelRequestQueue == NO && [_requestsArray count] != 0 )
	{
		NSDictionary *progress = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_currentRequest], @"current", [NSNumber numberWithInt:[_requestsArray count]], @"total", nil];
		
		if([_delegate respondsToSelector:_currentlySendingSelector])
			[_delegate performSelector:_currentlySendingSelector withObject:progress];
		
		[[_requestsArray objectAtIndex:_currentRequest] setDelegate:self];
		[[_requestsArray objectAtIndex:_currentRequest] setSelector:@selector(httpRequestFinished:)];
		[[_requestsArray objectAtIndex:_currentRequest] sendRequest];
		NSLog(@"request started");
	}
	_currentRequest++;
}


- (void)httpRequestFinished:(id)data
{
	NSLog(@"requst completed");
	if([_delegate respondsToSelector:_lastRequestResponseSelector])
		[_delegate performSelector:_lastRequestResponseSelector withObject:data];
	
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
		_currentRequest = 0;
		[_requestsArray removeAllObjects];
		if([_delegate respondsToSelector:_allRequestsFinishedSelector])
			[_delegate performSelector:_allRequestsFinishedSelector];
	}
		
}

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
	}
}

- (void)facebookRequestFailed:(id)data
{	
	/*
	if([_delegate respondsToSelector:@selector(queueRequestFailed:)])
		[_delegate performSelector:@selector(queueRequestFailed:) withObject:data];
	 */
	[self httpRequestFinished:data];
}


@end
