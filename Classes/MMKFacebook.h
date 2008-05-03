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
//  MMKFacebook.h
//  Mobile MKAbeFook
//
//  Created by Mike on 3/28/2008.
//  Copyright 2006 Mike Kinney. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMKLoginViewController.h"

extern NSString *MKAPIServerURL;
extern NSString *MKLoginUrl;
extern NSString *MMKFacebookAPIVersion;
extern NSString *MMKFacebookFormat;


@protocol MMKFacebook
-(UIView *)applicationView;
-(void)userLoginSuccessful;

@end

/*!
 @class MMKFacebook
 MMKFacebook is used to set up a connection to the Facebook API.  It handles creating an auth token, generating an auth session and logging a in a user.  MMKFacebook stores the session secret and session key that are used in all requests to the Facebook API.
 
 
Available Delegate Methods
 
-(void)userLoginSuccessful; (required)<br/>
&nbsp;&nbsp; Called when login window is closed and valid authToken, authSession, and uid have been verified.
 
-(void)userLoginFailed; (optional)<br/>
&nbsp;&nbsp; Called when login window is closed and either authToken, authSession or uid cannot be verified.
 
-(void)facebookAuthenticationError:(NSDictionary *)error; (optional)<br/>
 &nbsp;&nbsp; Called when an error is encountered attempting to obtain an authToken or authSession.  Passes parsed XML response from Facebook as NSDictionary object.
 
 
 */
@interface MMKFacebook : NSObject {
	
	NSString *apiKey;
	NSString *secretKey;
	NSString *authToken;
	NSString *sessionKey;
	NSString *sessionSecret;
	NSString *uid;
	NSString *defaultsName;
	BOOL hasAuthToken;
	BOOL hasSessionKey;
	BOOL hasSessionSecret;
	BOOL hasUid;
	BOOL userHasLoggedInMultipleTimes; //used to prevent persistent session from loading if a user as logged out but the application hasn't written the NSUserDefaults yet
	NSTimeInterval connectionTimeoutInterval;
	id _delegate;
	BOOL _alertMessagesEnabled;
	BOOL _shouldUseSynchronousLogin;
	
	UINavigationController *_navigationController;
	MMKLoginViewController *_loginViewController;


	
}

/*!
 @param anAPIKey Your API key issued by Facebook.
 @param aSecret Your secret key issued by Facebook.
 @param aDelegate A delegate object that will receive calls from the MMKFacebook object.
 
 The delegate object must implement a userLoggedIn: method that is called after a user has logged in and closed the login window.  It may optionally implement a userLoginFaild method that will be called if the login fails.
 @result Returns allocated and initiated MMKFacebook object ready to be used to log into the Facebook API.
@version 0.1 and later
 */
+(MMKFacebook *)facebookWithAPIKey:(NSString *)anAPIKey withSecret:(NSString *)aSecret delegate:(id)aDelegate;

/*!
 @param anAPIKey Your API key issued by Facebook.
 @param aSecret Your secret key issued by Facebook.
 @param aDelegate A delegate object that will receive calls from the MMKFacebook object.
 
 The delegate object must implement a userLoggedIn: method that is called after a user has logged in and closed the login window.  It may optionally implement a userLoginFaild method that will be called if the login fails.
 @result Returns initiated MMKFacebook object ready to be used to log into the Facebook API.
  @version 0.1 and later
 */
-(MMKFacebook *)initUsingAPIKey:(NSString *)anAPIKey usingSecret:(NSString *)aSecret delegate:(id)aDelegate;



/*!
 @param aBool Specify yes or no to enable or disable alert messages.
 
 If alerts are enabled MMKFacebook will automatically display simple alert messages if errors are encountered while trying to authenticate and log into Facebook.com.  As of 0.1 alert messages are enabled by default.
  @version 0.1 and later
 */
-(void)setAlertsEnabled:(BOOL)aBool;

/*!
 @result Returns YES if alert messages are enabled, NO if they are disabled.
@version 0.1 and later
 */
-(BOOL)alertsEnabled;


-(NSString *)apiKey;
-(NSString *)sessionKey;
-(NSString *)generateSigForParameters:(NSDictionary *)parameters;
-(NSString *)generateTimeStamp;
-(id)delegate;

/*!
 @param aConnectionTimeoutInterval
 
 Sets the length of time to wait before an attempted connection gives up.  Default time is 5 seconds.
 */
-(void)setConnectionTimeoutInterval:(double)aConnectionTimeoutInterval;

/*!
 @result Retuns current connection timeout interval.
 */
-(NSTimeInterval)connectionTimeoutInterval;

/*!
 @result Returns uid of user currently logged in.
 */
-(NSString *)uid;

/*!
 @result Checks to see if auth token, session key, session secret and uid are set.  Returns true if everything is set and it's safe to assume a user has logged in.  
 */
-(BOOL)userLoggedIn;

/*!
 Sets auth token, session key, session secret and uid to nil.  Use clearInfiniteSession to also remove any stored infinite sessions.
 */
-(void)resetFacebookConnection;

/*!
 Attempts to load a stored infinte session for the application.  This method checks NSUserDefaults for a stored sessionKey and sessionSecret.  It uses a synchronous request to try to authenticate the stored session.  Note: The MMKFacebook class only allows a persistent session to be loaded once per instance.  For example, if a persistent session is successfully loaded then the resetFacebookConnection method is called that instance of MMKFacebook will return false for every call to loadPersistentSession for the remainder of its existence.  This behavior may change in the future.
 @result Returns true if stored session information is valid and a user id is successfully returned from Facebook otherwise it returns false.
 */
-(BOOL)loadPersistentSession;

/*!
 Removes sessionKey and sessionSecret keys from application NSUserDefaults.  This method also calls resetFacebookConnection.
 @version 0.1 and later
 */
-(void)clearInfiniteSession;

//Login Window
-(void)getAuthSession;

/*!
 While the login window is loading a MMKFacebookRequest sends an asynchronous request to Facebook to obtain an auth token.  The auth token is used to create the URL that is loaded in the login window.  After a user logs in and closes the window another MMKFacebookRequest is sent to obtain an auth session.  If a successful auth session is obtained the userLoggedIn: delegate method will be called.  If no auth session is received the userLoginFailed delegate method is called.
 */
-(void)showFacebookLoginWindow;



//prepare url
/*!
 @param aMethodName Full Facebook method name to be called.  Example: facebook.users.getInfo
 @param parameters NSDictionary containing parameters and values for the method being called.  They keys are the parameter names and the values are the arguments.
 
 This method will automatically include all parameters required by every Facebook method.  Parameters you do not need to include are "v", "api_key", "format", "session_key", and "call_id".  See official Facebook documentation for all other parameters available depending on the method you are calling.  As of 0.1 this method is considered deprecated, use generateFacebookURL: instead.
 @result Returns complete NSURL ready to be sent to the Facebook API.
 */
-(NSURL *)generateFacebookURL:(NSString *)aMethodName parameters:(NSDictionary *)parameters;

/*!
 @param parameters NSDictionary containing parameters and values for a desired method.  The dictionary must include a key "method" that has the value of the desired method to be called, i.e. "facebook.users.getInfo".  They keys are the parameter names and the values are the arguments.
 
 This method will automatically include all parameters required by every Facebook method.  Parameters you do not need to include are "v", "api_key", "format", "session_key", "sig", and "call_id".  See official Facebook documentation for all other parameters available depending on the method you are calling.
 @result Returns complete NSURL ready to be sent to the Facebook API.
 */
-(NSURL *)generateFacebookURL:(NSDictionary *)parameters;

-(NSString *)generateTimeStamp;


/*!
 @param theURL URL generated by generateFacebokURL:parameters: or generateFacebookURL:
 
 Initiates a synchronous request to Facebook.  See MMKFacebookRequest for sending asynchronous requests. 
 @result Returns NSXMLDocument that was returned from Facebook.  Returns nil if a network error was encountered.
 @version 0.1 and later
 */
-(id)fetchFacebookData:(NSURL *)theURL;

/*!
 @param aBool Send YES if login procedure should use sychronous requests, or no to use asynchronous requests.
 
 If you call showFacebookLoginWindow or showFacebookLoginWindowForSheet while the main run loop is not in NSDefaultMainRunLoop mode you will need to use sychronous login requests.  For example if a modal window is present you will need to sychronous requests.  Use this method when working with iPhoto or Apeture plugins.
 */
-(void)setShouldUseSynchronousLogin:(BOOL)aBool;

/*!
 Default is NO.
 */
-(BOOL)shouldUseSychronousLogin;

/*!
 @param aString Name of extended permission to grant. (As of this writing Facebook allows status_update, photo_upload, and create_listing)
 
 This method will display a new window and load the Facebook URL  http://www.facebook.com/authorize.php?api_key=YOUR_API_KEY&v=1.0&ext_perm=PERMISSION_NAME
 authentication information is filled in automatically.  If no user is logged in an alert message will be displayed unless they have been turned off.
 @versioni 0.1.4 and later
*/
//-(void)grantExtendedPermission:(NSString *)aString;

@end



@interface NSString (StringExtras)
- (NSString *) encodeURLLegally;
- (NSString *) md5Hash;
@end


