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
//  MKAsyncRequest.h
//  MKAbeFook
//
//  Created by Mike on 3/8/07.
//  Copyright 2007 Mike Kinney. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MKFacebook.h"

/*!
 @class MKAsyncRequest
 @discussion Initiates asynchronous requests to Facebook.  As of 0.7 this class is deprecated.  Use MKFacebookRequest instead.
 */

@interface MKAsyncRequest : NSObject {
	NSURLConnection *dasConnection; //internal connection used if object is used multiple times.  blame the beer.
	MKFacebook *facebookConnection;
	id _delegate;
	SEL _selector;
	NSMutableData *responseData;
	BOOL _shouldReleaseWhenFinished; //used internally
	BOOL _requestIsDone; //dirty stupid way of trying to prevent crashing when trying to cancel the request when it's not active.  isn't there a better way to do this?
}

/*!
 @method initWithFacebookConnection:delegate:selector:
 @param aFacebookConnection MKFacebook object that has been used to log in a user.
 @param aDelegate Object to receive returned XML from Facebook.
 @param aSelector Method to have returned XML passed to.  Should accept (id) as parameter.
 */
-(MKAsyncRequest *)initWithFacebookConnection:(MKFacebook *)aFacebookConnection 
									 delegate:(id)aDelegate 
									 selector:(SEL)aSelector;

/*!
 @method fetchFacebookData:parameters:facebookConnection:delegate:selector:
 @param aMethodName Facebook method to be called, i.e. "facebook.users.getInfo".
 @param parameters NSDictionary containing parameters to be passed to Facebook method.
 @param aFacebookConnection MKFacebook object that has been used to log in a user.
 @param aDelegate Object to receive returned XML from Facebook.
 @param aSelector Method to have returned XML passed to.  Should accept (id) as parameter.
 @discussion Creates new MKAsyncRequest object and requests Facebook method with specified parameters.  Releases itself when it's done.
 */
+(void)fetchFacebookData:(NSString *)aMethodName parameters:(NSDictionary *)parameters facebookConnection:aFacebookConnection delegate:(id)aDelegate selector:(SEL)aSelector;

/*!
@method fetchFacebookData:parameters:
 @param aMethodName Facebook method to be called, i.e. "facebook.users.getInfo".
 @param parameters NSDictionary containing parameters to be passed to Facebook method.
 @discussion Requests specified method with parameters.  Response is passed to delegate / selector.
 */
-(void)fetchFacebookData:(NSString *)aMethodName parameters:(NSDictionary *)parameters;

/*!
 @method cancel
 @discussion Cancels request.
 */
-(void)cancel;
@end
