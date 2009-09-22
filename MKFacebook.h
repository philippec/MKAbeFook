// 
//  MKFacebook.h
//  MKAbeFook
//
//  Created by Mike on 10/11/06.
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



@class MKLoginWindow;

extern NSString *MKAPIServerURL;
extern NSString *MKLoginUrl;
extern NSString *MKFacebookAPIVersion;
extern NSString *MKFacebookResponseFormat;
/*!
 @brief Login and commuincate with Facebook.com
 
 @class MKFacebook
 MKFacebook is used to set up a connection to the Facebook API.  It handles creating an auth token, generating an auth session and logging a in a user.  MKFacebook stores the session secret and session key that are used in all requests to the Facebook API.

Available Delegate Methods
 
-(void)userLoginSuccessful; (required)<br/>
&nbsp;&nbsp; Called when login window is closed and valid authToken, authSession, and uid have been verified.
 
-(void)userLoginFailed; (optional)<br/>
&nbsp;&nbsp; Called when login window is closed and either authToken, authSession or uid cannot be verified.
 
-(void)facebookAuthenticationError:(NSDictionary *)error; (optional)<br/>
 &nbsp;&nbsp; Called when an error is encountered attempting to obtain an authToken or authSession.  Passes parsed XML response from Facebook as NSDictionary object.
 */
@interface MKFacebook : NSObject {
	
	MKLoginWindow *loginWindow;


	id _delegate;
	BOOL _alertMessagesEnabled;
	BOOL _displayLoginAlerts;

}

#pragma mark Instantiate
/*! @name Instantiate
 *	Create a new MKFacebook object.
 */
//@{


/*!
 @brief Setup new MKFacebook object.
 
 @param anAPIKey Your API key issued by Facebook.
 @param aSecret Your secret key issued by Facebook.
 @param aDelegate A delegate object that will receive calls from the MKFacebook object.
  
 The delegate object must implement a userLoggedIn: method that is called after a user has logged in and closed the login window.  It may optionally implement a userLoginFaild method that will be called if the login fails.
 
 @result Returns allocated and initiated MKFacebook object ready to be used to log into the Facebook API.
@version 0.7 and later
 */
+ (MKFacebook *)facebookWithAPIKey:(NSString *)anAPIKey delegate:(id)aDelegate;



/*!
 @brief Setup new MKFacebook object.
 
 @param anAPIKey Your API key issued by Facebook.
 @param aSecret Your secret key issued by Facebook.
 @param aDelegate A delegate object that will receive calls from the MKFacebook object.
  
 The delegate object must implement a userLoggedIn: method that is called after a user has logged in and closed the login window.  It may optionally implement a userLoginFaild method that will be called if the login fails.
 
 @result Returns initiated MKFacebook object ready to be used to log into the Facebook API.
  @version 0.7 and later
 */
- (MKFacebook *)initUsingAPIKey:(NSString *)anAPIKey delegate:(id)aDelegate;


//@}	//ENDS Instantiate group
#pragma mark -



#pragma mark Manage User Login
/*! @name Manage User Login
 *	Display login window, get information about user login status.
 */
//@{


/*!
 @brief Returns TRUE if valid session exists.
 
 @result Checks to see if auth token, session key, session secret and uid are set.  Returns true if everything is set and it's safe to assume a user has logged in.  
 */
- (BOOL)userLoggedIn;


/*!
 @brief Get the UID of the logged in user.
 
 @result Returns uid of user currently logged in.
 */
- (NSString *)uid;



/*!
 @brief Logs in a user from a saved session.
 
  Attempts to load a stored infinte session for the application.  This method checks NSUserDefaults for a stored sessionKey and sessionSecret.  It uses a synchronous request to try to authenticate the stored session.  Note: The MKFacebook class only allows a persistent session to be loaded once per instance.  For example, if a persistent session is successfully loaded then the resetFacebookConnection method is called that instance of MKFacebook will return false for every call to loadPersistentSession for the remainder of its existence.  This behavior may change in the future.
 
 In order for a user to receive what appears to be an infinite session they must grant the application "offline_access" using -(void)grantExtendedPermisison:(NSString *)aString;.  Unfortunately the user will have to login one more time after this is called before -(void)loadPersistentSession; will work.
 
 Trying to load a persistent session will use a synchronous request, your application might hang if the connectionTimeoutInterval is set to a high number of seconds.
 
 @result Returns true if stored session information is valid and a user id is successfully returned from Facebook otherwise it returns false.
 */
- (BOOL)loadPersistentSession;



/*!
 @brief Attempts to log a user in using existing session.  If no session is available a login window is diplayed.
 
 Tries to load existing session.  If no session is available a login window will be displayed.
 @param permissions List of permisisons to offer the user.
 @param sheet If YES is passed in a NSWindow will be returned, otherwise a login window will appear and nil will be returned.
 @return Either a NSWindow to be attached as a sheet or nil.
 */
- (NSWindow *)loginWithPermissions:(NSArray *)permissions forSheet:(BOOL)sheet;


/*!
 @brief Destoys login session.
 
 Removes any saved sessions and invalidates any future requests until a user logs in again.
 @version 0.9.0
 */
- (void)logout;


//called from MKLoginWindow after a successful login
- (void)userLoginSuccessful;


//@}	//ENDS Manage User Login group
#pragma mark -



#pragma mark Extend Permisisons
/*! @name Extend Permissions
 *	Display a window to allow user to extent application permissions.
 */
//@{


/*!
 @brief Display a window and a Facebook page to extend permisisons.
 
 @param aString Name of extended permission to grant. See Facebook documentation for allowed extended permissions.

 This method will display a new window and load the Facebook URL  http://www.facebook.com/authorize.php?api_key=YOUR_API_KEY&v=1.0&ext_perm=PERMISSION_NAME
 with authentication information is filled in automatically.  If no user is logged in an alert message will be displayed unless they have been turned off.  Unfortunately the user will have to login again to grant the permissions.
 @version 0.7.4 and later
*/
- (void)grantExtendedPermission:(NSString *)aString;



/*!
 @brief Display a window and a Facebook page to extend permisisons.
 
 @param aString Name of extended permission to grant. See Facebook documentation for allowed extended permissions.
 @result Returns NSWindow with WebView that loads the grant extended permissions request.
 @version 0.8.2 and later
 */
- (NSWindow *)grantExtendedPermissionForSheet:(NSString *)aString;


//@}	//ENDS Extend Permissions group
#pragma mark -


#pragma mark Handle Login Alerts
/*! @name Handle Login Alerts
 *	
 */
//@{


/*!
 Set whether or not alert windows should be displayed if Facebook returns an error during the login process.  Default is YES.
 @param aBool Should we display the error or should we not?
 @version 0.8 and later
 */
- (void)setDisplayLoginAlerts:(BOOL)aBool;



/*!
 @result Returns YES if login alerts are enabled, maybe so (but actually NO) if they are not.
 @version 0.8 and later
 */
- (BOOL)displayLoginAlerts;


//@}	//ENDS Handle Login Alerts group
#pragma mark -

@end





/*!
 Some methods you should implement.
 @version 0.8 and later
 */
@protocol MKFacebookDelegate


/*! @name Receive Login Information
 *
 */
//@{

/*!
 Called after authentication process has finished and it has been established that a use has successfully logged in.
 @version 0.8 and later
 */
-(void)userLoginSuccessful;



/*!
 You have three guesses as to why this gets called.
 @version 0.8 and later
 */
-(void)userLoginFailed;
//@}

@end





