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
//  MKPhotoUploader.h
//  MKAbeFook
//
//  Created by Mike on 3/4/07.
//  Copyright 2007 Mike Kinney. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "MKFacebook.h"

/*!
 @class MKPhotoUploader
 @discussion This class is considered deprecated as of version 0.7.  Use MKFacebookRequest instead.
 
 Available Delegate Methods

-(void)photoDidFinishUploading:(id)facebookResponse;<br/>
&nbsp;&nbsp;  Called when single photo has uploaded.  Passes response from Facebook as NXMLDocument.
 
-(void)bunchOfPhotosDidFinishUploading;
&nbsp;&nbsp; Called when all photos have finished uploading.
 
-(void)invalidImage:(NSDictionary *)aDictionary;
 &nbsp;&nbsp;  Called if item in bunchOfPhotosArray could not create a valid NSImage.  Passes information about the failed item.
 */

@interface MKPhotoUploader : NSObject {
	NSURLConnection *facebookUploadConnection;
	id _delegate;
	MKFacebook *facebookConnection;
	NSMutableData *responseData;
	NSArray *bunchOfPhotosArray;
	BOOL isUploadingABunchOfPhotos;
	int bunchOfPhotosIndex; 
}

/*!
 @method usingFacebookConnection:delegate:
 @param aFacebookConnection MKFacebook object a user has successfully logged into.
 @param aDelegate Object to receive delegate notifications.
 @discussion Deprecated as of 0.7.
 @result Creates newly allocated MKPhotoUploader object ready to upload photos to Facebook.com.
 */
+(MKPhotoUploader *)usingFacebookConnection:(MKFacebook *)aFacebookConnection delegate:(id)aDelegate;

/*!
 @method initUsingFacebookConnection:delegate:
 @param aFacebookConnection MKFacebook object a user has successfully logged into.
 @param aDelegate Object to receive delegate notifications.
 @discussion Deprecated as of 0.7.
 @result Creates new MKPhotoUploader object ready to upload photos to Facebook.com.
 */
-(MKPhotoUploader *)initUsingFacebookConnection:(MKFacebook *)aFacebookConnection delegate:(id)aDelegate;
-(id)delegate;
-(void)setDelegate:(id)aDelegate;

/*!
 @method uploadABunchOfPhotos:
 @param aBunchOfPhotosArray Array of NSDictionary objects containing keys "aid", "caption", and "pathToImage".  "pathToImage" value should be a valid path to a image file that can be used to create a NSImage object.
 @discussion Deprecated as of 0.7.
 */
-(void)uploadABunchOfPhotos:(NSArray *)aBunchOfPhotosArray;
//this should be private
-(void)uploadNextPhoto;

/*!
 @method facebookPhotoUpload:caption:image:
 @param anAid Album id to upload photo to.
 @param aCaption Caption for photo.
 @param anImage NSImage to upload.
 @discussion Deprecated as of 0.7.
 */
-(void)facebookPhotoUpload:(NSString *)anAid caption:(NSString *)aCaption image:(NSImage *)anImage;

/*!
 @method facebookPhotoUpload:caption:pathToImage:
 @param anAid Album id to upload photo to.
 @param aCaption Caption for photo.
 @param pathToImage Path to image file that can be used to create a NSImage object.
 @discussion Deprecated as of 0.7.
 */
-(void)facebookPhotoUpload:(NSString *)anAid caption:(NSString *)aCaption pathToImage:(NSString *)aPathToImage;
-(void)cancelUpload;

@end




