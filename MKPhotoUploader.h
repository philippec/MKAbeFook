/*
 
 MKPhotoUploader.h
 MKAbeFook

 Created by Mike on 3/4/07.
 Copyright 2008 Mike Kinney. All rights reserved.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/


#import <Cocoa/Cocoa.h>
#import "MKFacebook.h"

/*!
 @brief Uploads images to Facebook (Deprecated in 0.7)
 
 @class MKPhotoUploader
  This class is considered deprecated as of version 0.7.  Use MKFacebookRequest instead.
 
 Available Delegate Methods

-(void)photoDidFinishUploading:(id)facebookResponse;<br/>
&nbsp;&nbsp;  Called when single photo has uploaded.  Passes response from Facebook as NXMLDocument.
 
-(void)bunchOfPhotosDidFinishUploading;
&nbsp;&nbsp; Called when all photos have finished uploading.
 
-(void)invalidImage:(NSDictionary *)aDictionary;
 &nbsp;&nbsp;  Called if item in bunchOfPhotosArray could not create a valid NSImage.  Passes information about the failed item.
  @deprecated Deprecated as of version 0.7
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
 @param aFacebookConnection MKFacebook object a user has successfully logged into.
 @param aDelegate Object to receive delegate notifications.
  Deprecated as of 0.7.
 @result Creates newly allocated MKPhotoUploader object ready to upload photos to Facebook.com.
  @deprecated Deprecated as of version 0.7
 */
+(MKPhotoUploader *)usingFacebookConnection:(MKFacebook *)aFacebookConnection delegate:(id)aDelegate;

/*!
 @param aFacebookConnection MKFacebook object a user has successfully logged into.
 @param aDelegate Object to receive delegate notifications.
  Deprecated as of 0.7.
 @result Creates new MKPhotoUploader object ready to upload photos to Facebook.com.
  @deprecated Deprecated as of version 0.7
 */
-(MKPhotoUploader *)initUsingFacebookConnection:(MKFacebook *)aFacebookConnection delegate:(id)aDelegate;
-(id)delegate;
-(void)setDelegate:(id)aDelegate;

/*!
 @param aBunchOfPhotosArray Array of NSDictionary objects containing keys "aid", "caption", and "pathToImage".  "pathToImage" value should be a valid path to a image file that can be used to create a NSImage object.
  Deprecated as of 0.7.
  @deprecated Deprecated as of version 0.7
 */
-(void)uploadABunchOfPhotos:(NSArray *)aBunchOfPhotosArray;
//this should be private
-(void)uploadNextPhoto;

/*!
 @param anAid Album id to upload photo to.
 @param aCaption Caption for photo.
 @param anImage NSImage to upload.
  Deprecated as of 0.7.
  @deprecated Deprecated as of version 0.7
 */
-(void)facebookPhotoUpload:(NSString *)anAid caption:(NSString *)aCaption image:(NSImage *)anImage;

/*!
 @param anAid Album id to upload photo to.
 @param aCaption Caption for photo.
 @param aPathToImage Path to image file that can be used to create a NSImage object.
  Deprecated as of 0.7.
  @deprecated Deprecated as of version 0.7
 */
-(void)facebookPhotoUpload:(NSString *)anAid caption:(NSString *)aCaption pathToImage:(NSString *)aPathToImage;
-(void)cancelUpload;

@end




