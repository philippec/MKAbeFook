//
//  MKEventsRequest.h
//  MKAbeFook
//
//  Created by Mike Kinney on 10/18/08.
//  Copyright 2008 Mike Kinney. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MKFacebook.h"
#import "MKFacebookRequest.h"


typedef enum {
	MKEventRSVPStatusAttending,
	MKEventRSVPStatusUnsure,
	MKEventRSVPStatusDeclined,
	MKEventRSVPStatusNotReplied
} MKEventRSVPStatus;


typedef enum{
	MKEventsFacebookMethodEventsGet,
	MKEventsFacebookMethodEventsGetMembers
} MKEventsFacebookMethod;


/*!
 @brief Convenience class for event related requests.
 
 @class MKEventsRequest
 This class is mostly untested.
 
 @version 0.8
 */
@interface MKEventsRequest : MKFacebookRequest <MKFacebookRequestProtocol> {
	id __delegate;
	MKEventsFacebookMethod _methodRequest;
	BOOL _returnXML;
}

#pragma mark MKFacebookProtocol Requirements
/*!
 
 @version 0.8 and later
 */
+(id)requestUsingFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate;

/*!
 
 @version 0.8 and later
 */
-(id)initWithFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate;


#pragma mark Supported Methods
/*!
 
 @version 0.8 and later
 */
-(void)eventsGet;

/*!
 
 @version 0.8 and later
 */
-(void)eventsGet:(NSString *)uid eids:(NSArray *)eids startTime:(NSDate *)startTime endTime:(NSDate *)endTime rsvp_status:(MKEventRSVPStatus)rsvp_status;

/*!
 
 @version 0.8 and later
 */
-(void)eventsGetMembers:(NSString *)eid;


#pragma mark Should be private
//response handling
-(void)setReturnXML:(BOOL)aBool;
-(void)receivedFacebookResponse:(NSXMLDocument *)xmlResponse;
@end


@protocol MKEventsRequestDelegate
-(void)eventsRequest:(MKEventsRequest *)eventsRequest events:(id)events;
-(void)eventsRequest:(MKEventsRequest *)eventsRequest eventMembers:(id)eventMembers;
@end
