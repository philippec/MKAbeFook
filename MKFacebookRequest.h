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
//  MKFacebookRequest.h
//  MKAbeFook
//
//  Created by Mike on 12/15/07.
//  Copyright 2007 Mike Kinney. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MKFacebook.h"

enum
{
	MKPostRequest = 0,
	MKGetRequest = 1 << 0
};

typedef int MKFacebookRequestType;

/*!
 @class MKFacebookRequest
 @discussion MKFacebookRequest handles all requests to the Facebook API.  It can send requests as either POST or GET and return the results to the specified delegate / selector.  This object requires a NSDictionary of parameters that contains the parameters for a request to the Facebook API.  Included in the dictionary must be a key "method" with a value of the full Facebook method being requested, i.e. "facebook.users.getInfo".  Values that are required by all Facebook methods, "v", "api_key", "format", "session_key", "sig", and "call_id", do not need to be in the NSDictionary of parameters you pass into the object, they will be inserted automatically.
 
 
 The MKFacebookRequest class is be capable of handling most of the methods available by the Facebook API, including facebook.photos.upload.  To upload a photo using this class include a NSImage object in your NSDictionary of parameters you set and set the method key value to "facebook.photos.upload".  The name of the key for the NSImage object can be any string.
 
 See the MKFacebookRequestQueue class for sending a series of requests that are sent incrementally after the previous request has been completed.
 
 Available Delegate Methods
 
 -(void)receivedFacebookXMLErrorResponse:(id)failedResponse;<br/>
 &nbsp;&nbsp; Called when an error is returned by Facebook.  Passes XML returned by Facebook.
 
 -(void)facebookRequestFailed:(id)error;<br/>
 &nbsp;&nbsp;  Called when the request could not be made.  Passes error received from NSURLConnection.
 
  @version 0.7 and later
 */
@interface MKFacebookRequest : NSObject {
	NSURLConnection *dasConnection; //internal connection used if object is used multiple times.  blame the beer.
	MKFacebook *facebookConnection;
	id _delegate;
	SEL _selector;
	NSMutableData *_responseData;
	BOOL _requestIsDone; //dirty stupid way of trying to prevent crashing when trying to cancel the request when it's not active.  isn't there a better way to do this?
	MKFacebookRequestType _urlRequestType;
	NSMutableDictionary *_parameters;
	NSURL *_requestURL;
}

-(MKFacebookRequest *)init;

/*!
 @method initWithFacebookConnection:delegate:selector:
 @param aFacebookConnection A MKFacebook object that has been used to log in a user.  This object must have a valid sessionKey. 
 @param delegate The object that will receive the information returned by Facebook.
 @param selector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument.
 @discussion This method returns a new MKFacebookRequest object that can be used to retrieve data from Facebook.
 @version 0.7 and later
 */
-(MKFacebookRequest *)initWithFacebookConnection:(MKFacebook *)aFacebookConnection delegate:(id)aDelegate selector:(SEL)aSelector;

/*!
 @method initWithFacebookConnection:parameters:delegate:selector:
 @param aFacebookConnection A MKFacebook object that has been used to log in a user.
 @param parameters NSDictionary containing parameters for requested method.  The dictionary must contain a the key "method" with a value of the full Facebook method being requested, i.e. "facebook.users.getInfo". Values that are required by all Facebook methods, "v", "api_key", "format", "session_key", "sig", and "call_id" do not need to be included in this dictionary.
 @param delegate The object that will receive the information returned by Facebook.
 @param selector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument.
 @discussion This method returns a new MKFacebookRequest object that can be used to retrieve data from Facebook.
  @version 0.7 and later
 */
-(MKFacebookRequest *)initWithFacebookConnection:(MKFacebook *)aFacebookConnection parameters:(NSDictionary *)parameters delegate:(id)aDelegate selector:(SEL)aSelector;

/*!
@method setFacebookConnection:
@param aFacebookConnection A MKFacebook object that has been used to log in a user.  This object must have a valid sessionKey.
  @version 0.7 and later
 */
-(void)setFacebookConnection:(MKFacebook *)aFacebookConnection;

/*!
 @method setDelegate:
 @param delegate The object that will receive the inforamtion returned by Facebook.
  @version 0.7 and later
 */
-(void)setDelegate:(id)delegate;

/*!
@method setSelector:
 @param selector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument.
  @version 0.7 and later
 */
-(void)setSelector:(SEL)selector;

/*!
 @method setParameters:
 @param parameters NSDictionary containing parameters for requested method.  The dictionary must contain a the key "method" with a value of the full Facebook method being requested, i.e. "facebook.users.getInfo".  Values that are required by all Facebook methods, "v", "api_key", "format", "session_key", "sig", and "call_id" do not need to be included in this dictionary.
  @version 0.7 and later
 */
-(void)setParameters:(NSDictionary *)parameters;

/*!
 @method setURLRequestType:
 @param urlRequestType Accepts MKPostRequest or MKGetRequest to specify request type.
  @version 0.7 and later
 */
-(void)setURLRequestType:(MKFacebookRequestType)urlRequestType;

/*!
 @method sendRequest
 @discussion Sends request to Facebook.  The result will be passed to the delegate / selector that were assigned to this object.
  @version 0.7 and later
 */
-(void)sendRequest;

/*!
@method cancelRequest
 @discussion Cancels the current request if one is in progress.
  @version 0.7 and later
 */
-(void)cancelRequest;
 
@end
