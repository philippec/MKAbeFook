// 
//  MKPhotoUploader.m
//  MKAbeFook
//
//  Created by Mike on 3/4/07.
/*
 Copyright (c) 2008, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "MKPhotoUploader.h"

@implementation MKPhotoUploader

+(MKPhotoUploader *)usingFacebookConnection:(MKFacebook *)aFacebookConnection delegate:(id)aDelegate
{
	return [[MKPhotoUploader alloc] initUsingFacebookConnection:aFacebookConnection delegate:aDelegate];
}


-(MKPhotoUploader *)initUsingFacebookConnection:(MKFacebook *)aFacebookConnection delegate:(id)aDelegate
{
	if(![aFacebookConnection userLoggedIn])
	{
		NSException *exception = [NSException exceptionWithName: @"InvalidFacebookConnection"
														 reason: @"No Facebook user logged in" userInfo:nil];
		
		[exception raise];	
		return nil;
	}
	
	if(![aDelegate respondsToSelector:@selector(photoDidFinishUploading:)])
	{
		NSException *exception = [NSException exceptionWithName: @"InvalidDelegate"
														 reason: @"No photoDidFinishUploading method found" userInfo:nil];
		
		[exception raise];	
		return nil;
	}
	
	self = [super init];
	facebookConnection = aFacebookConnection; //we should check this before letting the object be created
	[self setDelegate:aDelegate];
	responseData = [[NSMutableData alloc] init]; //wasteful if we don't need it	
	bunchOfPhotosArray = [[NSArray alloc] init]; //wasteful if we don't need it
	isUploadingABunchOfPhotos = NO;
	bunchOfPhotosIndex = 0;
	return self;
}

-(void)dealloc
{
	[responseData release];
	[bunchOfPhotosArray release];
	[super dealloc];
}

-(id)delegate
{
	return _delegate;
}

-(void)setDelegate:(id)aDelegate
{
	_delegate = aDelegate;
}



-(void)uploadABunchOfPhotos:(NSArray *)aBunchOfPhotosArray
{
	//quick dirty half assed checking... fix this later
	bunchOfPhotosIndex = 0; //this might be something other than zero if object is reused
	BOOL validArray = NO;
	int i;
	for(i=0; i < [aBunchOfPhotosArray count]; i++)
	{
		if([[aBunchOfPhotosArray objectAtIndex:i] valueForKey:@"aid"] != nil &&
		   [[aBunchOfPhotosArray objectAtIndex:i] valueForKey:@"caption"] != nil && 
		   [[aBunchOfPhotosArray objectAtIndex:i] valueForKey:@"pathToImage"] != nil)
			validArray = YES;
			
	}
	if(validArray)
	{
		bunchOfPhotosArray = [aBunchOfPhotosArray copy];
		isUploadingABunchOfPhotos = YES;
		[self uploadNextPhoto]; //start uploading
	}
	else
   {
		NSException *exception = [NSException exceptionWithName: @"InvalidArray"
														 reason: @"Invalid photos array" userInfo:nil];
		
		[exception raise];	
   }
}

-(int)bunchOfPhotosIndex
{
	return bunchOfPhotosIndex;
}


//this should be private
-(void)uploadNextPhoto
{
	NSString *anAid = [[bunchOfPhotosArray objectAtIndex:bunchOfPhotosIndex] valueForKey:@"aid"];
	NSString *caption = [[bunchOfPhotosArray objectAtIndex:bunchOfPhotosIndex] valueForKey:@"caption"];
	NSString *pathToImage = [[bunchOfPhotosArray objectAtIndex:bunchOfPhotosIndex] valueForKey:@"pathToImage"];

	
	[self facebookPhotoUpload:anAid caption:caption pathToImage:pathToImage];
}

-(void)facebookPhotoUpload:(NSString *)anAid caption:(NSString *)aCaption image:(NSImage *)anImage
{
	//no error checking is done for the rest of this.  we will surely need some at some point.
	//image modification by Josh Wiseman (Facebook, Inc.)
	NSData *resizedTIFFData = [anImage TIFFRepresentation];
	NSBitmapImageRep *resizedImageRep = [NSBitmapImageRep imageRepWithData: resizedTIFFData];
	NSDictionary *imageProperties = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat: 1.0] forKey:NSImageCompressionFactor];
	
	NSData *imageData = [resizedImageRep representationUsingType: NSJPEGFileType properties: imageProperties];
	
	NSMutableDictionary *tempDictionary = [[[NSMutableDictionary alloc] init] autorelease];
	[tempDictionary setValue:@"facebook.photos.upload" forKey:@"method"];
	[tempDictionary setValue:[facebookConnection generateTimeStamp] forKey:@"call_id"];
	[tempDictionary setValue:anAid forKey:@"aid"];
	[tempDictionary setValue:aCaption forKey:@"caption"];
	[tempDictionary setValue:MKFacebookAPIVersion forKey:@"v"];
	[tempDictionary setValue:MKFacebookFormat forKey:@"format"];
	[tempDictionary setValue:[facebookConnection sessionKey] forKey:@"session_key"];
	[tempDictionary setValue:[facebookConnection apiKey] forKey:@"api_key"];
	
	NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:MKAPIServerURL]];
	NSMutableData *postBody = [NSMutableData data];
	[postRequest setHTTPMethod:@"POST"];
	NSString *stringBoundary = [NSString stringWithString:@"xXxThIsTeXtWiLlNeVeRbEeSeEnXxX"];
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
	[postRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
	
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"method\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"facebook.photos.upload"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"v\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:MKFacebookAPIVersion] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"api_key\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:[facebookConnection apiKey]] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"session_key\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:[facebookConnection sessionKey]] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"call_id\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:[tempDictionary valueForKey:@"call_id"]] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"caption\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:aCaption] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"format\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:MKFacebookFormat] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"aid\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:anAid] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postBody appendData:[[NSString stringWithString:@"Content-Disposition: form-data; name=\"sig\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:[facebookConnection generateSigForParameters:tempDictionary]] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	
	//should we be checking the file type? jpeg, png etc...
	
	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"something\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];	
	
	[postBody appendData:imageData];
	
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[postRequest setHTTPBody:postBody];
	
	facebookUploadConnection = [NSURLConnection connectionWithRequest:postRequest delegate:self];
	
}

-(void)facebookPhotoUpload:(NSString *)anAid caption:(NSString *)aCaption pathToImage:(NSString *)aPathToImage
{
	
	NSImage *anImage = [[[NSImage alloc] initByReferencingFile:aPathToImage] autorelease];
	if(![anImage isValid])
	{
		if([_delegate respondsToSelector:@selector(invalidImage:)])
		{
			NSMutableDictionary *error = [[[NSMutableDictionary alloc] init] autorelease];
			[error setValue:anAid forKey:@"aid"];
			[error setValue:aCaption forKey:@"caption"];
			[error setValue:aPathToImage forKey:@"pathToImage"];
			[_delegate performSelector:@selector(invalidImage:) withObject:error];
		}
		
		//if bunch, go to next item
		if(isUploadingABunchOfPhotos)
		{	
			if(bunchOfPhotosIndex + 1 < [bunchOfPhotosArray count]) //continue with array
			{
				bunchOfPhotosIndex++;
				[self uploadNextPhoto];	
			}else //or finish up
			{
				if ([_delegate respondsToSelector:@selector(bunchOfPhotosDidFinishUploading)])
					[_delegate performSelector:@selector(bunchOfPhotosDidFinishUploading) withObject:nil];
				[self release];
			}
			
		}
		
		return;
	}
	if(aCaption == nil)
		aCaption = [NSString stringWithString:@""];
	
	//do we need to know the file extension of the picture being uploaded?
	//NSArray *tempArray = [aPathToImage componentsSeparatedByString:@"/"];
	//NSString *fileName = [tempArray objectAtIndex:[tempArray count]-1];
	//NSString *type = [[fileName pathExtension] lowercaseString];
	
	if([_delegate respondsToSelector:@selector(currentlyUploadingImage:)])
	{
		//we could get this from the bunchOfPhotosArray
		NSMutableDictionary *currentImage = [[[NSMutableDictionary alloc] init]autorelease];
		[currentImage setValue:[NSString stringWithFormat:@"%i", bunchOfPhotosIndex+1] forKey:@"imageNumber"];
		[currentImage setValue:[NSString stringWithFormat:@"%i", [bunchOfPhotosArray count]] forKey:@"totalNumberOfImages"];
		[currentImage setValue:aCaption forKey:@"caption"];
		[currentImage setValue:aPathToImage forKey:@"pathToImage"];
		[_delegate performSelector:@selector(currentlyUploadingImage:) withObject:currentImage];		
	}
	
	[self facebookPhotoUpload:anAid caption:aCaption image:anImage];
	
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	
	NSXMLDocument *xmlDocument = [[[NSXMLDocument alloc] initWithData:responseData
															  options:0
																error:nil] autorelease];
	
	if([_delegate respondsToSelector:@selector(photoDidFinishUploading:)])
		[_delegate performSelector:@selector(photoDidFinishUploading:) withObject:xmlDocument]; 

				
	//clear response data, we really only need to do this we are uploading a bunch of photos
	[responseData setData:[NSData data]];
	
	//if we are uploading a bunch of photos, go to the next photo
	if(isUploadingABunchOfPhotos)
	{
		if(bunchOfPhotosIndex + 1 < [bunchOfPhotosArray count])
		{
			bunchOfPhotosIndex++;
			[self uploadNextPhoto];
		}
		else
		{
			if ([_delegate respondsToSelector:@selector(bunchOfPhotosDidFinishUploading)])
				[_delegate performSelector:@selector(bunchOfPhotosDidFinishUploading) withObject:nil];
			
			[self release];
		}
	}else
	{
		[self release];	
	}
	
}

-(void)cancelUpload
{
	[facebookUploadConnection cancel];
	isUploadingABunchOfPhotos = NO;
	//[self release];
	
}


@end
