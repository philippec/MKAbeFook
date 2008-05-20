/*

 MKAsyncRequest.h
 MKAbeFook

 Created by Mike on 3/8/07.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import <Cocoa/Cocoa.h>
#import "MKFacebook.h"

/*!
 @brief Asynchronous Facebook requests (Deprecated in 0.7)
 
 @class MKAsyncRequest
  Initiates asynchronous requests to Facebook.  As of 0.7 this class is deprecated.  Use MKFacebookRequest instead.
 @deprecated Deprecated as of version 0.7
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
 @param aFacebookConnection MKFacebook object that has been used to log in a user.
 @param aDelegate Object to receive returned XML from Facebook.
 @param aSelector Method to have returned XML passed to.  Should accept (id) as parameter.
@deprecated Deprecated as of version 0.7
 */
-(MKAsyncRequest *)initWithFacebookConnection:(MKFacebook *)aFacebookConnection 
									 delegate:(id)aDelegate 
									 selector:(SEL)aSelector;

/*!
 @param aMethodName Facebook method to be called, i.e. "facebook.users.getInfo".
 @param parameters NSDictionary containing parameters to be passed to Facebook method.
 @param aFacebookConnection MKFacebook object that has been used to log in a user.
 @param aDelegate Object to receive returned XML from Facebook.
 @param aSelector Method to have returned XML passed to.  Should accept (id) as parameter.
  Creates new MKAsyncRequest object and requests Facebook method with specified parameters.  Releases itself when it's done.
  @deprecated Deprecated as of version 0.7
 */
+(void)fetchFacebookData:(NSString *)aMethodName parameters:(NSDictionary *)parameters facebookConnection:aFacebookConnection delegate:(id)aDelegate selector:(SEL)aSelector;

/*!
 @param aMethodName Facebook method to be called, i.e. "facebook.users.getInfo".
 @param parameters NSDictionary containing parameters to be passed to Facebook method.
  Requests specified method with parameters.  Response is passed to delegate / selector.
  @deprecated Deprecated as of version 0.7
 */
-(void)fetchFacebookData:(NSString *)aMethodName parameters:(NSDictionary *)parameters;

/*!
  Cancels request.
  @deprecated Deprecated as of version 0.7
 */
-(void)cancel;
@end
