//
//  MKPhotosRequest.m
//  MKAbeFook
//
//  Created by Mike Kinney on 11/3/08.
//  Copyright 2008 Mike Kinney. All rights reserved.
//

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
