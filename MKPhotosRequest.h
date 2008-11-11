//
//  MKPhotosRequest.h
//  MKAbeFook
//
//  Created by Mike Kinney on 11/3/08.
//  Copyright 2008 Mike Kinney. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MKFacebook.h"
#import "MKFacebookRequest.h"


typedef enum{
	MKPhotosFacebookMethodPhotosGet,
	MKPhotosFacebookMethodPhotosGetTags,
	MKPhotosFacebookMethodPhotosUpload
} MKPhotosFacebookMethod;


/*!
 @brief Convenience for photo related requests.
 
 @class MKPhotosRequest
 This class is untested.  It will be tested, updated, fixed, maintained, and documented in the future.
 
 @version 0.8
 */
@interface MKPhotosRequest : MKFacebookRequest <MKFacebookRequestProtocol> {

	id __delegate;
	MKPhotosFacebookMethod _methodRequest;
	BOOL _returnXML;
}

#pragma mark MKFacebookProtocol Requirements
/*!
 
 @version 0.8 and later
 */
+(id)requestUsingFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate;

/*!
 
 @version 0.8 and later
 */
-(id)initWithFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate;


#pragma mark Supported Methods
/*!
 
 @version 0.8 and later
 */
-(void)photosGet:(NSArray *)pids aid:(NSString *)aid subjId:(NSString *)subj_id;

/*!
 
 @version 0.8 and later
 */
-(void)photosGet:(NSString *)aid;

/*!
 
 @version 0.8 and later
 */
-(void)photosGetTags:(NSArray *)pids;

//UPLOADING METHODS
/*!
 
 @version 0.8 and later
 */
-(void)photosUpload:(NSImage *)photo aid:(NSString *)aid caption:(NSString *)caption;

/*!
 
 @version 0.8 and later
 */
-(void)photosUpload:(NSImage *)photo;


#pragma mark Should be private
//response handling
-(void)setReturnXML:(BOOL)aBool;
-(void)receivedFacebookResponse:(NSXMLDocument *)xmlResponse;


@end

@protocol MKPhotosRequestDelegate

@end