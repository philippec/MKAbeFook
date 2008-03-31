//
//  CXMLElementAdditions.m
//  Mobile MKAbeFook
//
//  Created by Mike Kinney on 3/31/08.
//  Copyright 2008 Mike Kinney. All rights reserved.
//

#import "CXMLElementAdditions.h"


@implementation CXMLElement (CXMLElementAdditions)
-(NSArray *)arrayFromXMLElement
{
	
	NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
	NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
	
	BOOL isList = NO;
	NSString *isListString = [[self attributeForName:@"list"] stringValue];
	if (isListString && [isListString caseInsensitiveCompare:@"true"] == NSOrderedSame)
		isList = YES;

	
	NSEnumerator *e = [[self children] objectEnumerator];
	CXMLElement *childElement;
	NSString *key;
	id value;
	while (childElement = [e nextObject]) {
		key = [childElement name];
		value = nil;
		
		// if it's a pure text value
		if ([childElement childCount] == 1 && [[childElement childAtIndex:0] kind] == CXMLTextKind) {
			value = [childElement stringValue];
		}
		else if ([childElement childCount] > 0) {
			self = childElement;
			// assume the child is a list
			value = [self arrayFromXMLElement];
			// if the returned array only has one object, turn it into a structure
			if ([(NSArray *)value count] == 1) {
				//value = [NSDictionary dictionaryWithObjectsAndKeys:[[value objectAtIndex:0] stringValue], [[value objectAtIndex:0] name], nil];
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

-(NSDictionary *)dictionaryFromXMLElement
{
	
	NSArray *array = [self arrayFromXMLElement];
	if ([array count] != 1)
		return nil;
	
	id firstValue = [array objectAtIndex:0];
	if ([[firstValue class] isSubclassOfClass: [NSDictionary class]] == NO)
		return nil;
	return firstValue;
}

@end
