//
//  MKFacebookRequestQueue.m
//  MKAbeFook
//
//  Created by Mike Kinney on 12/12/07.
//  Copyright 2007 Mike Kinney. All rights reserved.
//

#import "MKFacebookRequestQueue.h"


@implementation MKFacebookRequestQueue

-(id)init
{
	self = [super init];
	if(self != nil)
	{
		_requestsArray = [[NSMutableArray alloc] init];
		_cancelRequestQueue = NO;
		_currentRequest = 0;
	}
	return self;
}

-(id)initWithRequests:(NSArray *)requests delegate:(id)aDelegate currentlySendingSelector:(SEL)currentlySendingSelector lastRequestResponseSelector:(SEL)lastRequestResponseSelector allRequestsFinishedSelector:(SEL)allRequestsFinishedSelector;
{
	self = [super init];
	if(self !=nil)
	{
		_delegate = aDelegate;
		_currentlySendingSelector = currentlySendingSelector;
		_lastRequestResponseSelector = lastRequestResponseSelector;
		_allRequestsFinishedSelector = allRequestsFinishedSelector;
		_requestsArray = [[NSMutableArray alloc] init];
		_requestsArray = (NSMutableArray *)requests;
		_currentRequest = 0;
		_cancelRequestQueue = NO;
	}
	return self;
}

-(void)dealloc
{
	[_requestsArray release];
	[super dealloc];
}

-(void)setDelegate:(id)delegate
{
	_delegate = delegate;
}

-(void)setCurrentlySendingSelector:(SEL)selector
{
	_currentlySendingSelector = selector;
}

-(void)setLastRequestResponseSelector:(SEL)selector
{
	_lastRequestResponseSelector = selector;
}

-(void)setAllRequestsFinishedSelector:(SEL)selector
{
	_allRequestsFinishedSelector = selector;
}

-(void)addRequest:(MKFacebookRequest *)request
{
	[_requestsArray addObject:request];
}

-(void)startRequestQueue
{
	[self startNextRequest];	
}

-(void)startNextRequest
{
	if(_currentRequest < [_requestsArray count] && _cancelRequestQueue == NO && [_requestsArray count] != 0 )
	{
		NSDictionary *progress = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:_currentRequest], @"current", [NSNumber numberWithInt:[_requestsArray count]], @"total", nil];
		
		if([_delegate respondsToSelector:_currentlySendingSelector])
			[_delegate performSelector:_currentlySendingSelector withObject:progress];
		
		[[_requestsArray objectAtIndex:_currentRequest] setDelegate:self];
		[[_requestsArray objectAtIndex:_currentRequest] setSelector:@selector(httpRequestFinished:)];
		[[_requestsArray objectAtIndex:_currentRequest] sendRequest];
	}
	_currentRequest++;
}

-(void)httpRequestFinished:(id)data
{
	if([_delegate respondsToSelector:_lastRequestResponseSelector])
		[_delegate performSelector:_lastRequestResponseSelector withObject:data];

	if(_currentRequest < [_requestsArray count] && _cancelRequestQueue == NO && [_requestsArray count] != 0)
	{
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

-(void)cancelRequestQueue
{
	if(_currentRequest < [_requestsArray count])
	{
		[[_requestsArray objectAtIndex:_currentRequest] cancelRequest];
		_cancelRequestQueue = YES;
	}
}

-(void)facebookRequestFailed:(id)data
{	
	if([_delegate respondsToSelector:@selector(queueRequestFailed:)])
		[_delegate performSelector:@selector(queueRequestFailed:) withObject:data];
}


@end
