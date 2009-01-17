//
//  MKPhotosRequest.m
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

#import "MKPhotosRequest.h"
#import "NSXMLElementAdditions.h"

@implementation MKPhotosRequest

#pragma mark MKFacebookRequestProtocol Requirements
+(id)requestUsingFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate
{
	return [[[MKPhotosRequest alloc] initWithFacebookConnection:facebookConnection delegate:delegate] autorelease];
}

-(id)initWithFacebookConnection:(MKFacebook *)facebookConnection delegate:(id)delegate
{
	if(self = [super init])
	{
		[self setFacebookConnection:facebookConnection];
		[self setDelegate:self];
		[self setSelector:@selector(receivedFacebookResponse:)];
		__delegate = delegate;
		_returnXML = NO;
	}
	return self;
}
#pragma mark -


#pragma mark Supported Methods
-(void)photosGet:(NSArray *)pids aid:(NSString *)aid subjId:(NSString *)subj_id
{
	_methodRequest = MKPhotosFacebookMethodPhotosGet;
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	[parameters setValue:@"photos.get" forKey:@"method"];
	if(pids != nil)
		[parameters setValue:[pids componentsJoinedByString:@","] forKey:@"pids"];
	if(aid != nil)
		 [parameters setValue:aid forKey:@"aid"];
	if(subj_id != nil)
		 [parameters setValue:subj_id forKey:@"subj_id"];
		 
	[self setParameters:parameters];
	[self sendRequest];
	[parameters release];
}

-(void)photosGet:(NSString *)aid;
{
	[self photosGet:nil aid:aid subjId:nil];
}

-(void)photosGetTags:(NSArray *)pids
{
	_methodRequest = MKPhotosFacebookMethodPhotosGetTags;
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	[parameters setValue:@"photos.getTags" forKey:@"method"];
	[parameters setValue:[pids componentsJoinedByString:@","] forKey:@"pids"];
	[self setParameters:parameters];
	[self sendRequest];
	[parameters release];
}

//UPLOADING METHODS

-(void)photosUpload:(NSImage *)photo aid:(NSString *)aid caption:(NSString *)caption
{
	_methodRequest = MKPhotosFacebookMethodPhotosUpload;
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	[parameters setValue:@"photos.upload" forKey:@"method"];
	[parameters setValue:photo forKey:@"photo"];
	if(aid != nil)
		[parameters setValue:aid forKey:@"aid"];
	if(caption != nil)
		[parameters setValue:caption forKey:@"caption"];
	
	[self setParameters:parameters];
	[self sendRequest];
	[parameters release];	
}

-(void)photosUpload:(NSImage *)photo
{
	[self photosUpload:photo aid:nil caption:nil];
}
#pragma mark -

#pragma mark Response Handling
-(void)setReturnXML:(BOOL)aBool
{
	_returnXML = aBool;
}


-(void)receivedFacebookResponse:(NSXMLDocument *)xmlResponse
{
	SEL selectorToPerform;
	switch (_methodRequest) {
		case MKPhotosFacebookMethodPhotosGet:
			if([__delegate respondsToSelector:@selector(photosRequest:photosGet:)])
			{
				selectorToPerform = @selector(photosRequest:photosGet:);
			}else
			{
				NSLog(@"MKPhotosRequest delegate does not respond to -(void)photosRequest:(MKPhotosRequest *)photoRequest photosGet:(id)response");
			}
			break;
			
		case MKPhotosFacebookMethodPhotosGetTags:
			if([__delegate respondsToSelector:@selector(photosRequest:photosGetTags:)])
			{
				selectorToPerform = @selector(photosRequest:photosGetTags:);
			}else
			{
				NSLog(@"MKPhotosRequest delegate does not respond to -(void)photosRequest:(MKPhotosRequest *)photoRequest photosGetTags:(id)response");
			}
			 
			break;

		case MKPhotosFacebookMethodPhotosUpload:
			if([__delegate respondsToSelector:@selector(photosRequest:photosUpload:)])
			{
				selectorToPerform = @selector(photosRequest:photosUpload:);
			}else
			{
				NSLog(@"MKPhotosRequest delegate does not respond to -(void)photosRequest:(MKPhotosRequest *)photoRequest photosUpload:(id)response");
			}			break;
			
		default:
			NSLog(@"Sweet zombie jesus how did you get here.... WTF DID YOU DO!?!?!!");
			break;
	}
	
	if(_returnXML == YES)
	{
		[__delegate performSelector:selectorToPerform withObject:self withObject:xmlResponse];	
	}else
	{
		//this is the default.  user will have to setReturnXML:YES to have raw xml returned to them
		[__delegate performSelector:selectorToPerform withObject:self withObject:[[xmlResponse rootElement] arrayFromXMLElement]];
	}
}
#pragma mark -

@end
