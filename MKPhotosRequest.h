//
//  MKPhotosRequest.h
//  MKAbeFook
//
//  Created by Mike Kinney on 11/3/08.
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
#import "MKFacebook.h"
#import "MKFacebookRequest.h"


typedef enum{
	MKPhotosFacebookMethodPhotosGet,
	MKPhotosFacebookMethodPhotosGetTags,
	MKPhotosFacebookMethodPhotosUpload
} MKPhotosFacebookMethod;


/*
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
/*
 
 @version 0.8 and later
 */
+(id)requestUsingFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate;

/*
 
 @version 0.8 and later
 */
-(id)initWithFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate;


#pragma mark Supported Methods
/*
 
 @version 0.8 and later
 */
-(void)photosGet:(NSArray *)pids aid:(NSString *)aid subjId:(NSString *)subj_id;

/*
 
 @version 0.8 and later
 */
-(void)photosGet:(NSString *)aid;

/*
 
 @version 0.8 and later
 */
-(void)photosGetTags:(NSArray *)pids;

//UPLOADING METHODS
/*
 
 @version 0.8 and later
 */
-(void)photosUpload:(NSImage *)photo aid:(NSString *)aid caption:(NSString *)caption;

/*
 
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