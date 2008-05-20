/*
 
 MKFacebookRequestQueue.h
 MKAbeFook

 Created by Mike Kinney on 12/12/07.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
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
 @param selector Method to be called when all requests have been completed.  Should accept (NSXMLDocument *) as argument.  NSXMLDocument will be the response from Facebook.
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
  Attempts to stop the current request being processed and prevents any further requests from starting.
  @version 0.7 and later
 */
-(void)cancelRequestQueue;

-(void)startNextRequest;


@end
