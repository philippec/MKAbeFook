//
//  MKVideoRequest.m
//  MKAbeFook
//
//  Created by Mike Kinney on 3/5/10.
//  Copyright 2010 Mike Kinney. All rights reserved.
//

#import "MKVideoRequest.h"


@implementation MKVideoRequest

+ (id)requestWithDelegate:(id)aDelegate{
	MKVideoRequest *videoUpload = [[[MKVideoRequest alloc] initWithDelegate:aDelegate selector:nil] autorelease];
	return videoUpload;
}


- (id)initWithDelegate:(id)delegate selector:(SEL)selector{
	self = [super initWithDelegate:delegate selector:selector];
	return self;
}


- (void)videoGetUploadLimits{
	self.method = @"video.getUploadLimits";
	[self sendRequest];
}


- (void)videoUpload:(NSData *)video title:(NSString *)title description:(NSString *)description{
	[self setURLRequestType:MKFacebookRequestTypePOST];
	NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
	[parameters setObject:video forKey:@"video"];
	[parameters setValue:title forKey:@"title"];
	[parameters setValue:description forKey:@"description"];
	[self setParameters:parameters];
	[self sendRequest];
	[parameters release];
}
@end
