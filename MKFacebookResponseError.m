//
//  MKFacebookResponseError.m
//  MKAbeFook
//
//  Created by Mike Kinney on 3/6/10.
//  Copyright 2010 Mike Kinney. All rights reserved.
//

#import "MKFacebookResponseError.h"
#import "NSXMLDocumentAdditions.h"
#import "NSXMLElementAdditions.h"
#import "JSON.h"
#import "NSDictionaryAdditions.h"
#import "MKFacebookRequest.h"



@implementation MKFacebookResponseError

@synthesize errorCode, errorMessage, requestArgs;

+ (MKFacebookResponseError *)errorFromRequest:(MKFacebookRequest *)request{
	MKFacebookResponseError *error = [[[MKFacebookResponseError alloc] initWithRequest:request] autorelease];
	return error;
}

- (id)initWithRequest:(MKFacebookRequest *)request{
	
	self = [super init];
	errorCode = 0;
	errorMessage = nil;
	requestArgs = nil;
	
	if (request == nil) {
		errorMessage = @"Unknown Error";
		return self;
	}
	
	NSDictionary *responseDictionary = nil;
	NSString *rawResponse = request.rawResponse;
	
	if (request.responseFormat == MKFacebookRequestResponseFormatXML) {
		NSXMLDocument *xml = [[NSXMLDocument alloc] initWithXMLString:rawResponse options:0 error:nil];
		responseDictionary = [[xml rootElement] dictionaryFromXMLElement];
		[xml release];
	}
	
	if (request.responseFormat == MKFacebookRequestResponseFormatJSON) {
		responseDictionary = [rawResponse JSONValue]; 
	}
	
	if (responseDictionary != nil) {
		if ([responseDictionary valueForKey:@"error_code"] != nil) {
			errorCode = [[responseDictionary valueForKey:@"error_code"] intValue];
		}
		
		if ([responseDictionary valueForKey:@"error_msg"] != nil) {
			errorMessage = [[NSString alloc] initWithString:[responseDictionary valueForKey:@"error_msg"]];
		}
		
		if ([responseDictionary valueForKey:@"request_args"] != nil) {
			requestArgs = [[NSArray alloc] initWithArray:[responseDictionary valueForKey:@"request_args"]];
		}
	}
	
	return self;
}

- (void)dealloc{
	[errorMessage release];
	[requestArgs release];
	[super dealloc];
}

@end
