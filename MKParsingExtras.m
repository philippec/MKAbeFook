/*
 
 MKParsingExtras.m
 MKAbeFook

 Created by Mike on 12/1/06.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/
 
//
//  Modified by Josh Wiseman (Facebook, Inc.) on 1/24/07
//
//  XML parsing from Josh Wiseman.  Debug and error checking disabled until error handling is established throughout the framework. - Mike July 1, 2007

#import "MKParsingExtras.h"

@implementation MKFacebook (MKParsingExtras)

#pragma mark XML parse methods

-(NSArray *)arrayFromXMLElement:(NSXMLElement *)XMLElement
{
	NSMutableArray *array = [NSMutableArray array];
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	BOOL isList = NO;
	NSString *isListString = [[XMLElement attributeForName:@"list"] stringValue];
	if (isListString && [isListString caseInsensitiveCompare:@"true"] == NSOrderedSame)
		isList = YES;
	
	NSEnumerator *e = [[XMLElement children] objectEnumerator];
	NSXMLElement *childElement;
	NSString *key;
	id value;
	while (childElement = [e nextObject]) {
		key = [childElement name];
		value = nil;
		
		// if it's a pure text value
		if ([childElement childCount] == 1 && [[childElement childAtIndex:0] kind] == NSXMLTextKind) {
			value = [childElement stringValue];
		}
		else if ([childElement childCount] > 0) {
			// assume the child is a list
			value = [self arrayFromXMLElement:childElement];
			// if the returned array only has one object, turn it into a structure
			if ([(NSArray *)value count] == 1) {
				value = (NSDictionary *)[(NSArray *)value objectAtIndex:0];
			}
		}
		
		// as long as it wasn't an empty element
		if (value) {
			// save the value into a dictionary as well, just in case this isn't really a list
			[dictionary setValue:value forKey:key];
			[array addObject:value];
		}
	}
	
	// if we didn't really have a list, populate the array with the dictionary we've been saving in parallel.
	if (isList == NO) {
		[array removeAllObjects];
		[array addObject: dictionary];
	}
	
	return array;
}

-(NSDictionary *)dictionaryFromXMLElement:(NSXMLElement *)XMLElement
{
	NSArray *array = [self arrayFromXMLElement:XMLElement];
	if ([array count] != 1)
		return nil;

	id firstValue = [array objectAtIndex:0];
	if ([[firstValue class] isSubclassOfClass: [NSDictionary class]] == NO)
		return nil;
	return firstValue;
}

-(BOOL)validXMLResponse:(NSXMLDocument *)XMLResponse
{
	if (XMLResponse == nil)
		return NO;
	
	NSXMLElement *rootElement = [XMLResponse rootElement];
	NSString *rootName = [rootElement name];

	NSRange errorRange = [rootName rangeOfString:@"error"];
	NSRange responseRange = [rootName rangeOfString:@"response"];
	if (errorRange.location != NSNotFound || responseRange.location == NSNotFound) {
		//requestError = MKErrorAPIOperation;
		//[self setValue:[self dictionaryFromXMLElement:rootElement] forKey:@"errorDictionary"];
		//if (debug)
		//	[self printErrorData];
		
		return NO;
	}
	
	return YES;
}

-(NSArray *)arrayFromXMLResponse:(NSXMLDocument *)XMLResponse
{
	if ([self validXMLResponse:XMLResponse] == NO) {
		return nil;
	}
	
	NSXMLElement *rootElement = [XMLResponse rootElement];
	NSArray *responseArray = [self arrayFromXMLElement:rootElement];
	
	//if (responseArray == nil) {
		//requestError = MKErrorAPISchema;
		//[self setValue:XMLResponse forKey:@"errorXML"];
		//if (debug)
		//	[self printErrorData];
		
		/*
		if([_delegate respondsToSelector:@selector(receivedFacebookXMLErrorResponse:)])
			[_delegate performSelector:@selector(receivedFacebookXMLErrorResponse:) withObject:XMLResponse];
		 */
		
	//}
	
	return responseArray;
}

-(NSDictionary *)dictionaryFromXMLResponse:(NSXMLDocument *)XMLResponse
{
	if ([self validXMLResponse:XMLResponse] == NO) {
		return nil;
	}
	
	NSXMLElement *rootElement = [XMLResponse rootElement];
	NSDictionary *responseDictionary = [self dictionaryFromXMLElement:rootElement];
	//if (responseDictionary == nil) {
		//requestError = MKErrorAPISchema;
		//[self setValue:XMLResponse forKey:@"errorXML"];
		//if (debug)
		//	[self printErrorData];
		
		//if([_delegate respondsToSelector:@selector(receivedFacebookXMLErrorResponse:)])
		//	[_delegate performSelector:@selector(receivedFacebookXMLErrorResponse:) withObject:XMLResponse];
	//}
	
	return responseDictionary;
}

@end
