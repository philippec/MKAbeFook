//
//  MKFacebookSession.h
//  MKAbeFook
//
//  Created by Mike Kinney on 9/19/09.
//  Copyright 2009 UNDRF. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SynthesizeSingleton.h"

extern NSString *MKFacebookSessionKey;

/*!
 @brief Handles saving session information to disk and loading existing sessions.
 */

@interface MKFacebookSession : NSObject {
	
	NSDictionary *session;

}

@property(nonatomic, retain) NSDictionary *session;

+ (MKFacebookSession *)sharedMKFacebookSession;

/*!
 Accepts a new session dictionary.  Saves the session to the application defaults.
 @param aSession New session to be saved.
 */
- (void)saveSession:(NSDictionary *)aSession;


/*!
 Loads any saved session from application defaults.  Returns false if no session could be loaded.
 */
- (BOOL)loadSession;

/*!
 Destroys any saved session.
 */
- (void)destroySession;


//accessors to session information
- (NSString *)sessionKey;
- (NSString *)secret;
- (NSString *)expirationDate;
- (NSString *)uid;
- (NSString *)sig;

@end
