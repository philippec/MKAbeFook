//
//  CXMLDocumentAdditions.m
//  Mobile MKAbeFook
//
//  Created by Mike Kinney on 3/31/08.
//  Copyright 2008 Mike Kinney. All rights reserved.
//

#import "CXMLDocumentAdditions.h"


@implementation CXMLDocument (CXMLDocumentAdditions)

-(BOOL)validFacebookResponse
{
	if (self == nil)
		return NO;
	
	NSString *rootName = [[self rootElement] name];
	
	NSRange errorRange = [rootName rangeOfString:@"error"];
	NSRange responseRange = [rootName rangeOfString:@"response"];
	if (errorRange.location != NSNotFound || responseRange.location == NSNotFound) {
		
		return NO;
	}
	
	return YES;
}

@end
