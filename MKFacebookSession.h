//
//  MKFacebookSession.h
//  MKAbeFook
//
//  Created by Mike Kinney on 9/19/09.
//  Copyright 2009 Mike Kinney. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SynthesizeSingleton.h"

extern NSString *MKFacebookSessionKey;

//Handles saving session information to disk and loading existing sessions.
@interface MKFacebookSession : NSObject {
	
	NSDictionary *session;
	NSString *apiKey;
	NSString *secretKey;

}

@property (nonatomic, retain) NSDictionary *session;
@property (nonatomic, retain) NSString *apiKey;
@property (nonatomic, retain) NSString *secretKey;

+ (MKFacebookSession *)sharedMKFacebookSession;

// Accepts a new session dictionary.  Saves the session to the application defaults.
- (void)saveSession:(NSDictionary *)aSession;


// Loads any saved session from application defaults.  Returns false if no session could be loaded.
- (BOOL)loadSession;


// Destroys any saved session.
- (void)destroySession;


// Checks to see if session looks valid.
- (BOOL)validSession;


//accessors to session information
- (NSString *)sessionKey;
- (NSString *)sessionSecret;
- (NSString *)expirationDate;
- (NSString *)uid;
- (NSString *)sig;

@end
