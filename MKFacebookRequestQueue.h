// 
//  MKFacebookRequestQueue.h
//  MKAbeFook
//
//  Created by Mike Kinney on 12/12/07.
/*
 Copyright (c) 2008, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */
//IMPORTANT NOTE: As of this writing this object will release itself when it's done with the queue.  Do not try to autorelease or release this object manually.

#import <Cocoa/Cocoa.h>
#import "MKFacebookRequest.h"
/*!
 @brief Sends series of requests to Facebook
 
 @class MKFacebookRequestQueue
  This class is used to send a series of requests to the Facebook API.  Requests are sent incrementally and do not begin until the previous request has been completed.  This class is useful for sending multiple photo uploads or when you need to ensure you have information from one request before processing another.
 
 Optional selectors can be specified to receive information regarding the progress of the uploads in the queue.  The currentlySendingSelector will pass a NSDictionary object containing a "current" key and a "total" key indicating the current index of the request being sent out of the total number of requests.  The lastRequestResponseSelector passes the last NSXMLDocument response from Facebook.  Finally the allRequestsFinishedSelector is called when all the requests in the queue have been sent and their responses have been received.
 
 Note: All MKFacebookRequests added to the queue will have their delegate and selector set to the MKFaceBookRequestQueue and pass the responses they receive back to the MKFacebookRequestQueue which will then pass the response accordingly via the lastRequestResponseSelector.
 
 Available Delegate Methods
 
 -(void)queueRequestFailed:(id)error;<br/>
 &nbsp;&nbsp; Called when a request in the queue could not be made.  Passes the NSURLConnection error from the failed request attempt.
 
  @version 0.7 and later
 */
@interface MKFacebookRequestQueue : NSObject {
	NSMutableArray *_requestsArray;
	id _delegate;
	SEL _currentlySendingSelector;
	SEL _lastRequestResponseSelector;
	SEL _allRequestsFinishedSelector;
	int _currentRequest;
	BOOL _cancelRequestQueue;
	float _timeBetweenRequests;
}


/*!
  Creates a new MKFacebookRequestQueue object.  You will also need to set the set the delegate and selectors.
  @version 0.7 and later
 */
-(id)init;

/*!
 @param requests NSArray of MKFacebookRequest objects ready to be requested.
 @param aDelegate Delegate object that implements selectors.
 @param currentlySendingSelector Method to be called and passed information about request currently being sent.
 @param lastRequestResponseSelector Method to be called and passed last response received. Should accept (id) as argument.
 @param allRequestsFinishedSelector Method to be called when all requests have been completed.
  Creates a new MKFacebookRequestQueue object that is ready to start requesting items in the queue.
  @version 0.7 and later
 */
-(id)initWithRequests:(NSArray *)requests delegate:(id)aDelegate currentlySendingSelector:(SEL)currentlySendingSelector lastRequestResponseSelector:(SEL)lastRequestResponseSelector allRequestsFinishedSelector:(SEL)allRequestsFinishedSelector;

/*!
 @param delegate
  Set delegate object.
  @version 0.7 and later
 */
-(void)setDelegate:(id)delegate;

/*!
 @param selector Method to be called and passed information about request currently being sent. 
  @version 0.7 and later
 */
-(void)setCurrentlySendingSelector:(SEL)selector;

/*!
 @param selector Method to be called and passed last response received. Should accept (NSDictionary *) as argument.  NSDictionary will contain two keys, "current" and "total".
  @version 0.7 and later
 */
-(void)setLastRequestResponseSelector:(SEL)selector;

/*!
 @param selector Method to be called when all requests have been completed.
  @version 0.7 and later
 */
-(void)setAllRequestsFinishedSelector:(SEL)selector;

/*!
 @param request MKFacebookRequest object that is ready to be sent.
  @version 0.7 and later
 */
-(void)addRequest:(MKFacebookRequest *)request;

/*!
  Starts processing the request queue.
  @version 0.7 and later
 */
-(void)startRequestQueue;

/*!
 Time in seconds between requests.
 @version 0.8 and later
 */
-(float)timeBetweenRequests;

/*!
 @param waitTime Number of seconds to wait between requests. Default is 1.0
 @version 0.8 and later
 */
-(void)setTimeBetweenRequests:(float)waitTime;

/*!
  Attempts to stop the current request being processed and prevents any further requests from starting.
  @version 0.7 and later
 */
-(void)cancelRequestQueue;

-(void)startNextRequest;

-(void)httpRequestFinished:(id)data;

@end
