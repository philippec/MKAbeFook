//
//  MKEventsRequest.m
//  MKAbeFook
//
//  Created by Mike Kinney on 10/18/08.
/*
 Copyright (c) 2009, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "MKEventsRequest.h"
#import "NSXMLElementAdditions.h"


@implementation MKEventsRequest

#pragma mark MKFacebookRequestProtocol Requirements
+(id)requestUsingFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate
{
	return [[[MKEventsRequest alloc] initWithFacebookConnection:facebookConnection delegate:delegate] autorelease];
}

-(id)initWithFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate
{
	if(self = [super init])
	{
		[self setFacebookConnection:facebookConnection];
		[self setDelegate:self];
		[self setSelector:@selector(facebookResponseReceived:)];
		__delegate = delegate;
		_returnXML = NO;
	}
	return self;
	
}
#pragma mark -

#pragma mark Supported Methods
-(void)eventsGet
{
	_methodRequest = MKEventsFacebookMethodEventsGet;
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	[parameters setValue:@"events.get" forKey:@"method"];
	[self setParameters:parameters];
	[self sendRequest];
	[parameters release];
}


//should these be ints or strings?
-(void)eventsGet:(NSString *)uid eids:(NSArray *)eids startTime:(NSDate *)startTime endTime:(NSDate *)endTime rsvp_status:(MKEventRSVPStatus)rsvp_status;
{
	_methodRequest = MKEventsFacebookMethodEventsGet;
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	[parameters setValue:@"events.get" forKey:@"method"];
	
	if(uid != nil)
		[parameters setValue:uid forKey:@"uid"];

	if(eids != nil)
		[parameters setValue:[eids componentsJoinedByString:@","] forKey:@"eids"];

	if(startTime != nil)
		[parameters setValue:[NSString stringWithFormat:@"%f", [startTime timeIntervalSince1970]] forKey:@"start_time"];
	
	if(endTime != nil)
		[parameters setValue:[NSString stringWithFormat:@"%f", [endTime timeIntervalSince1970]] forKey:@"end_time"];
	
	NSString *rsvpStatus;
	switch (rsvp_status) {
		case MKEventRSVPStatusAttending:
			rsvpStatus = @"attending";
			break;
		case MKEventRSVPStatusUnsure:
			rsvpStatus = @"unsure";
			break;
		case MKEventRSVPStatusDeclined:
			rsvpStatus = @"declined";
			break;
		case MKEventRSVPStatusNotReplied:
			rsvpStatus = @"not_replied";
			break;
		default:
			rsvpStatus = @"";
			break;
	}
	[parameters setValue:rsvpStatus forKey:@"rsvp_status"];
	
	[self setParameters:parameters];
	[self sendRequest];
	[parameters release];
}

-(void)eventsGetMembers:(NSString *)eid
{
	_methodRequest = MKEventsFacebookMethodEventsGetMembers;
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	[parameters setValue:@"events.getMembers" forKey:@"method"];
	[parameters setValue:eid forKey:@"eid"];
	[self setParameters:parameters];
	[self sendRequest];
	[parameters release];
	
}
#pragma mark -

#pragma mark Response Handling
-(void)setReturnXML:(BOOL)aBool
{
	_returnXML = aBool;
}

-(void)receivedFacebookResponse:(NSXMLDocument *)xmlResponse
{
	SEL selectorToPerform;
	switch (_methodRequest) {
		case MKEventsFacebookMethodEventsGet:
			if([__delegate respondsToSelector:@selector(eventsRequest:events:)])
			{
				selectorToPerform = @selector(eventsRequest:events:);
			}else
			{
				DLog(@"MKEventsRequest delegate does not respond to -(void)eventsRequest:(MKEventsRequest *)eventsRequest events:(id)events");
			}
			break;
		case MKEventsFacebookMethodEventsGetMembers:
			if([__delegate respondsToSelector:@selector(eventsRequest:eventMembers:)])
			{
				selectorToPerform = @selector(eventsRequest:eventMembers:);
			}else
			{
				DLog(@"MKEventsRequest delegate does not respond to -(void)eventsRequest:(MKEventsRequest *)eventsRequest eventMembers:(id)eventMembers");
			}			
			break;
		default:
			DLog(@"There should be no way in hell you are seeing this message, WTF DID YOU DO!?!?!!");
			break;
	}
	
	if(_returnXML == YES)
	{
		[__delegate performSelector:selectorToPerform withObject:self withObject:xmlResponse];	
	}else
	{
		//this is the default.  user will have to setReturnXML:YES to have raw xml returned to them
		[__delegate performSelector:selectorToPerform withObject:self withObject:[[xmlResponse rootElement] arrayFromXMLElement]];
	}
	
	
}

@end
