/*
 
 MKFacebook.h
 MKAbeFook

 Created by Mike on 10/11/06.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import <Cocoa/Cocoa.h>



@class MKLoginWindow;

extern NSString *MKAPIServerURL;
extern NSString *MKLoginUrl;
extern NSString *MKFacebookAPIVersion;
extern NSString *MKFacebookFormat;
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
}

/*!
 @param anAPIKey Your API key issued by Facebook.
 @param aSecret Your secret key issued by Facebook.
 @param aDelegate A delegate object that will receive calls from the MKFacebook object.
  
 The delegate object must implement a userLoggedIn: method that is called after a user has logged in and closed the login window.  It may optionally implement a userLoginFaild method that will be called if the login fails.
 
 @result Returns allocated and initiated MKFacebook object ready to be used to log into the Facebook API.
@version 0.7 and later
 */
+(MKFacebook *)facebookWithAPIKey:(NSString *)anAPIKey withSecret:(NSString *)aSecret delegate:(id)aDelegate;

/*!
 @param anAPIKey Your API key issued by Facebook.
 @param aSecret Your secret key issued by Facebook.
 @param aDelegate A delegate object that will receive calls from the MKFacebook object.
  
 The delegate object must implement a userLoggedIn: method that is called after a user has logged in and closed the login window.  It may optionally implement a userLoginFaild method that will be called if the login fails.
 
 @result Returns initiated MKFacebook object ready to be used to log into the Facebook API.
  @version 0.7 and later
 */
-(MKFacebook *)initUsingAPIKey:(NSString *)anAPIKey usingSecret:(NSString *)aSecret delegate:(id)aDelegate;


/*!
 @param anAPIKey Your API key issued by Facebook.
 @param aSecret Your secret key issued by Facebook.
 @param aDelegate A delegate object that will receive calls from the MKFacebook object.
 @param aDefaultsName Name defaults identifier.  [[NSBundle mainBundle] bundleIdentifier] is usually appropriate.
  
 The delegate object must implement a userLoggedIn: method that is called after a user has logged in and closed the login window.  It may optionally implement a userLoginFaild method that will be called if the login fails.  This method is considered deprecated as of version 0.7.
 
 @result Returns allocated and initiated MKFacebook object ready to be used to log into the Facebook API.
 @deprecated Deprecated as of version 0.7
 */
+(MKFacebook *)facebookWithAPIKey:(NSString *)anAPIKey withSecret:(NSString *)aSecret delegate:(id)aDelegate withDefaultsName:(NSString *)aDefaultsName;

/*!
 @param anAPIKey Your API key issued by Facebook.
 @param aSecret Your secret key issued by Facebook.
 @param aDelegate A delegate object that will receive calls from the MKFacebook object.
 @param aDefaultsName Name defaults identifier.  [[NSBundle mainBundle] bundleIdentifier] is usually appropriate.
  
 The delegate object must implement a userLoggedIn: method that is called after a user has logged in and closed the login window.  It may optionally implement a userLoginFaild method that will be called if the login fails.  This method is considered deprecated as of version 0.7.
 
 @result Returns initiated MKFacebook object ready to be used to log into the Facebook API.
 @deprecated Deprecated as of version 0.7
 */
-(MKFacebook *)initUsingAPIKey:(NSString *)anAPIKey usingSecret:(NSString *)aSecret delegate:(id)aDelegate withDefaultsName:(NSString *)aDefaultsName;


/*!
 @param aBool Specify yes or no to enable or disable alert messages.
  
 If alerts are enabled MKFacebook will automatically display simple alert messages if errors are encountered while trying to authenticate and log into Facebook.com.  As of 0.7 alert messages are enabled by default.
  @version 0.7 and later
 */
-(void)setAlertsEnabled:(BOOL)aBool;

/*!
 @result Returns YES if alert messages are enabled, NO if they are disabled.
@version 0.7 and later
 */
-(BOOL)alertsEnabled;


-(NSString *)apiKey;
-(NSString *)sessionKey;
-(NSString *)generateSigForParameters:(NSDictionary *)parameters;
-(NSString *)generateTimeStamp;

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
  Attempts to load a stored infinte session for the application.  This method checks NSUserDefaults for a stored sessionKey and sessionSecret.  It uses a synchronous request to try to authenticate the stored session.  Note: The MKFacebook class only allows a persistent session to be loaded once per instance.  For example, if a persistent session is successfully loaded then the resetFacebookConnection method is called that instance of MKFacebook will return false for every call to loadPersistentSession for the remainder of its existence.  This behavior may change in the future.
 @result Returns true if stored session information is valid and a user id is successfully returned from Facebook otherwise it returns false.
 */
-(BOOL)loadPersistentSession;

/*!
  Removes sessionKey and sessionSecret keys from application NSUserDefaults.  This method also calls resetFacebookConnection.
 @version 0.7 and later
 */
-(void)clearInfiniteSession;

//Login Window
-(void)getAuthSession;

/*!
 Displays a login window for logging into the Facebook API.
  
 While the login window is loading a MKFacebookRequest sends an asynchronous request to Facebook to obtain an auth token.  The auth token is used to create the URL that is loaded in the login window.  After a user logs in and closes the window another MKFacebookRequest is sent to obtain an auth session.  If a successful auth session is obtained the userLoggedIn: delegate method will be called.  If no auth session is received the userLoginFailed delegate method is called.
 */
-(void)showFacebookLoginWindow;

/*!
 @result Returns a login window with a "Close" button that can be used as a sheet.
  
 See showFacebookLogin window method for a description of the login process.
 */
-(NSWindow *)showFacebookLoginWindowForSheet;

//prepare url
/*!
 @param aMethodName Full Facebook method name to be called.  Example: facebook.users.getInfo
 @param parameters NSDictionary containing parameters and values for the method being called.  They keys are the parameter names and the values are the arguments.
  
 This method will automatically include all parameters required by every Facebook method.  Parameters you do not need to include are "v", "api_key", "format", "session_key", and "call_id".  See official Facebook documentation for all other parameters available depending on the method you are calling.  As of 0.7 this method is considered deprecated, use generateFacebookURL: instead.
 
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

//synchronous request
/*!
 @param theURL URL generated by generateFacebokURL:parameters: or generateFacebookURL:
  
 Initiates a synchronous request to Facebook.  See MKFacebookRequest for sending asynchronous requests. 
 
 @result Returns NSXMLDocument that was returned from Facebook.  Returns nil if a network error was encountered.
 @version 0.7 and later
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
 with authentication information is filled in automatically.  If no user is logged in an alert message will be displayed unless they have been turned off.  Unfortunately the user will have to login again to grant the permissions.
 @version 0.7.4 and later
*/
-(void)grantExtendedPermission:(NSString *)aString;

@end



/*
 \category StringExtras(NSString)
  Extra string methods.
 */
@interface NSString (StringExtras)

/*
  Prepares string so it can be passed in a URL.
 */
- (NSString *) encodeURLLegally;
@end


