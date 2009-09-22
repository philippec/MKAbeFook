//
//  MKFacebookRequest.h
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

#import <Cocoa/Cocoa.h>
#import "MKFacebook.h"
#import "MKFacebookSession.h"


/*!
 @enum MKFacebookRequestType
 */
enum MKFacebookRequestType
{
	MKPostRequest,
	MKGetRequest
};
typedef int MKFacebookRequestType;






/*!
 @class MKFacebookRequest
 MKFacebookRequest handles all requests to the Facebook API.  It can send requests as either POST or GET and return the results to a specified delegate and selector.  

 To send a request you must provide an instance of MKFacebookRequest with a NSDictionary containing the parameters for your request.  Included in the dictionary must be a key "method" with a value of the full Facebook method being requested, i.e. "facebook.users.getInfo".  Values that are required by all Facebook methods, "v", "api_key", "format", "session_key", "sig", and "call_id", do not need to be in the NSDictionary of parameters you pass in, they will be added automatically.
 
 
 The MKFacebookRequest class is be capable of handling most of the methods available by the Facebook API, including facebook.photos.upload.  To upload a photo using this class include a NSImage object in your NSDictionary of parameters you provide and set the method key value to "facebook.photos.upload".  The name of the key for the NSImage object can be any string.

 This class will post notifications named "MKFacebookRequestActivityStarted" and "MKFacebookRequestActivityEnded" when network activity starts and ends.  You are responsible for adding observers for handling the notifications.
 
 See the MKFacebookRequestQueue class for sending a series of requests that are sent sequentially.
 
 
 Delegate Methods
 
 -(void)facebookResponseReceived:(id)response; <br/>
 &nbsp;&nbsp; Called when Facebook returns a valid response.  Passes XML returned by Facebook.  If you do not assign a selector use this method to handle reponses from Facebook.  If you want the responses sent elsewhere assign the request a selector.
 
 -(void)facebookErrorResponseReceived:(id)errorResponse;<br/>
 &nbsp;&nbsp; Called when an error is returned by Facebook.  Passes XML returned by Facebook.
 
 -(void)facebookRequestFailed:(id)error;<br/>
 &nbsp;&nbsp;  Called when the request could not be made.  Passes error received from NSURLConnection.
 
 See MKFacebookRequestDelegate for additional delegate information.
 
  @version 0.7 and later
 */
@interface MKFacebookRequest : NSObject {
	NSURLConnection *dasConnection; //internal connection used if object is used multiple times.  blame the beer.
	NSTimeInterval connectionTimeoutInterval;
	id _delegate;
	SEL _selector;
	NSMutableData *_responseData;
	BOOL _requestIsDone; //dirty stupid way of trying to prevent crashing when trying to cancel the request when it's not active.  isn't there a better way to do this?
	MKFacebookRequestType _urlRequestType;
	NSMutableDictionary *_parameters;
	NSURL *_requestURL;
	BOOL _displayAPIErrorAlert;
	int _numberOfRequestAttempts;
	int _requestAttemptCount;
	MKFacebookSession *_session;
}
@property NSTimeInterval connectionTimeoutInterval;

#pragma mark init methods
/*! @name Creating and Initializing
 *
 */
//@{

/*!
 @brief Setup new MKFacebookRequest object.
 
 @param aDelegate The object that will receive the information returned by Facebook.  This should implement -(void)facebookResponseReceived:(id)response to handle data returned from Facebook.  Set a selector to have responses sent elsewhere.
 @version 0.9 and later
 */
+ (id)requestWithDelegate:(id)aDelegate;




/*!
 @brief Setup new MKFacebookRequest object.
 
 @param aFacebookConnection A MKFacebook object that has been used to log a user in.  This object must have a valid sessionKey.
 @param aDelegate The object that will receive the response returned by Facebook.
 @param aSelector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument. 
 @version 0.9 and later
 */
+ (id)requestWithDelegate:(id)aDelegate selector:(SEL)aSelector;



- (id)init;



/*!
 @brief Setup new MKFacebookRequest object.
 
 @param aDelegate The object that will receive the information returned by Facebook.
 @param aSelector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument.
  This method returns a new MKFacebookRequest object that can be used to retrieve data from Facebook.
 @version 0.9 and later
 */
- (id)initWithDelegate:(id)aDelegate selector:(SEL)aSelector;




/*!
 @brief Setup new MKFacebookRequest object.
 
 @param parameters NSDictionary containing parameters for requested method.  The dictionary must contain a the key "method" with a value of the full Facebook method being requested, i.e. "facebook.users.getInfo". Values that are required by all Facebook methods, "v", "api_key", "format", "session_key", "sig", and "call_id" do not need to be included in this dictionary.
 @param aDelegate The object that will receive the information returned by Facebook.
 @param aSelector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument.
  This method returns a new MKFacebookRequest object that can be used to retrieve data from Facebook.
  @version 0.9 and later
 */
- (id)initWithParameters:(NSDictionary *)parameters delegate:(id)aDelegate selector:(SEL)aSelector;
//@}

#pragma mark -


#pragma mark Instance Methods

/*! @name Preparing and Sending Requests
 *
 */
//@{

/*!
 @brief Pass in a NSDictionary of parameters for your request.
 
 @param parameters NSDictionary containing parameters for requested method.  The dictionary must contain a the key "method" with a value of the full Facebook method being requested, i.e. "facebook.users.getInfo".  Values that are required by all Facebook methods, "v", "api_key", "format", "session_key", "sig", and "call_id" do not need to be included in this dictionary.
 @version 0.7 and later
 */
- (void)setParameters:(NSDictionary *)parameters;


/*!
 @brief Set the number of times to attempt a request before giving up.
 
 Sets how many times the request should be attempted before giving up.  Note: the delegate will not receive notification of a failed attempt unless all attempts fail.  Default is 5.
 @version 0.8 and later
 */
- (void)setNumberOfRequestAttempts:(int)requestAttempts;



/*!
 @brief Set the type of request (POST or GET).  POST is default.
 
 @param urlRequestType Accepts MKPostRequest or MKGetRequest to specify request type.  If no request type is set MKPostRequest will be used.
 @version 0.7 and later
 */
- (void)setURLRequestType:(MKFacebookRequestType)urlRequestType;

//returns type of request that will be made
- (MKFacebookRequestType)urlRequestType;



/*!
 @brief Generates the appropriate URL and signature based on parameters for request.  Sends request to Facebook.
 
 Sends request to Facebook.  The result will be passed to the delegate / selector that were assigned to this object.
 @version 0.7 and later
 */
- (void)sendRequest;



//creates a signature string based on the parameters for the request
- (NSString *)generateSigForParameters:(NSDictionary *)parameters;


//returns a unix timestamp as a string
- (NSString *)generateTimeStamp;



/*!
 @brief Generates a full URL including a signature for the method name and parameters passed in.  
 
 @param aMethodName Full Facebook method name to be called.  Example: facebook.users.getInfo
 @param parameters NSDictionary containing parameters and values for the method being called.  They keys are the parameter names and the values are the arguments.
 
 This method will automatically include all parameters required by every Facebook method.  Parameters you do not need to include are "v", "api_key", "format", "session_key", and "call_id".  See official Facebook documentation for all other parameters available depending on the method you are calling.  As of 0.7 this method is considered deprecated, use generateFacebookURL: instead.
 
 @result Returns complete NSURL ready to be sent to the Facebook API.
 */
- (NSURL *)generateFacebookURL:(NSString *)aMethodName parameters:(NSDictionary *)parameters;




/*!
 @brief Generates a full URL including a signature for the parameters passed in.   
 
 @param parameters NSDictionary containing parameters and values for a desired method.  The dictionary must include a key "method" that has the value of the desired method to be called, i.e. "facebook.users.getInfo".  They keys are the parameter names and the values are the arguments.
 
 This method will automatically include all parameters required by every Facebook method.  Parameters you do not need to include are "v", "api_key", "format", "session_key", "sig", and "call_id".  See official Facebook documentation for all other parameters available depending on the method you are calling.
 @result Returns complete NSURL ready to be sent to the Facebook API.
 */
- (NSURL *)generateFacebookURL:(NSDictionary *)parameters;
//@}



/*! @name Synchronous Requests
 *
 */
//@{

/*!
 @brief Performs a synchronous request using URL generated by generateFacebookURL:parameters: or generateFacebookURL:
 
 @param theURL URL generated by generateFacebokURL:parameters: or generateFacebookURL:
 
 Initiates a synchronous request to Facebook.
 
 @result Returns NSXMLDocument that was returned from Facebook.  Returns nil if a network error was encountered.
 @version 0.7 and later
 */
- (id)fetchFacebookData:(NSURL *)theURL;
//@}


/*! @name Canceling a Request
 *
 */
//@{
/*!
 @brief Cancels a request if in progress.
 
 Cancels the current asynchronous request if one is in progress.  Synchronous requests cannot be cancelled.
 @version 0.7 and later
 */
- (void)cancelRequest;
//@}



/*!
 @brief Set the delegate to recieve request results.
 
 @param delegate The object that will receive the inforamtion returned by Facebook.
 @version 0.7 and later
 */
- (void)setDelegate:(id)delegate;


- (id)delegate;


/*!
 @brief Set the selector to receive the request results.
 
 @param selector Method in delegate object to be called and passed the response from Facebook.  This method should accept an (id) as an argument.
 @version 0.7 and later
 */
- (void)setSelector:(SEL)selector;




/*!
 @brief Set to optionally automatically display error window when an error is encountered during a request.
 
 @param aBool Automatically display errorr windows or not.
 
 Sets whether or not instance should automatically display error windows when network connection or xml parsing errors are encountered.  Default is yes.
 
 @version 0.8 and later
 */
- (void)setDisplayAPIErrorAlert:(BOOL)aBool;



/*!
 @brief Returns TRUE if error windows will be displayed.
 
 @result Returns boolean indicating whether or not instance will automatically display error windows or not.
 @version 0.8 and later
 */
- (BOOL)displayAPIErrorAlert;






#pragma mark -


@end



//meh, some random thoughts for request subclasses.  needs some more thought.  subclassing needs structure.
@protocol MKFacebookRequestProtocol
//+(id)requestUsingFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate;
//-(id)initWithFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate;
////response handling
//-(void)receivedFacebookResponse:(NSXMLDocument *)xmlResponse;
@end




/*!
 @version 0.8 and later
 */
@protocol MKFacebookRequestDelegate


/*! @name Receive Valid Response
 *
 */
//@{


/*!
 Called when Facebook returns a valid response.  Passes XML returned by Facebook.  If you do not assign a selector use this method to handle reponses from Facebook.  If you want the responses sent elsewhere assign the request a selector.

 @version 0.8 and later
 */
- (void)facebookResponseReceived:(id)response;
//@}



/*! @name Reveive Error Responses
 *
 */
//@{


/*!
Called when an error is returned by Facebook.  Passes XML returned by Facebook.
 
 @version 0.8 and later
 */
- (void)facebookErrorResponseReceived:(id)errorResponse;



/*!
 Called when the request could not be made.  Passes NSError containing information about why it failed (usually due to NSURLConnection problem).
 
 @version 0.8 and later
 */
- (void)facebookRequestFailed:(id)error;
//@}


@end


