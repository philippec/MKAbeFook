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

@implementation MKPhotosRequest

+ (id)requestWithDelegate:(id)aDelegate{
	MKPhotosRequest *request = [[[MKPhotosRequest alloc] initWithDelegate:aDelegate selector:nil] autorelease];
	return request;
}

- (id)initWithDelegate:(id)delegate selector:(SEL)selector{
	self = [super initWithDelegate:delegate selector:selector];
	return self;
}

#pragma mark Get Methods
-(void)photosGet:(NSArray *)pids aid:(NSString *)aid subjId:(NSString *)subj_id
{
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	self.method = @"photos.get";
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
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	self.method = @"photos.getTags";
	[parameters setValue:[pids componentsJoinedByString:@","] forKey:@"pids"];
	[self setParameters:parameters];
	[self sendRequest];
	[parameters release];
}

- (void)photosGetAlbums:(NSArray *)aids{
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	self.method = @"photos.getAlbums";
	[parameters setValue:[aids componentsJoinedByString:@","] forKey:@"aids"];
	[self setParameters:parameters];
	[self sendRequest];
	[parameters release];
}
#pragma mark -

#pragma mark Upload Methods
-(void)photosUpload:(NSImage *)photo aid:(NSString *)aid caption:(NSString *)caption
{
	[self setURLRequestType:MKFacebookRequestTypePOST];
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	self.method = @"photos.upload";
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

@end
