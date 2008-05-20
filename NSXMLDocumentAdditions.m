/*
 NSXMLDocumentAdditions.m
 MKAbeFook

 Created by Mike Kinney on 12/15/07.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import "NSXMLDocumentAdditions.h"

//Parsing methods originally written by Josh Wiseman (Facebook, Inc.) and distributed with the iPhoto plugin. modifications made by Mike Kinney 


@implementation NSXMLDocument (NSXMLDocumentAdditions)


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
