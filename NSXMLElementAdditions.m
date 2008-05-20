/*

 NSXMLElementAdditions.m
 BRAP Client

 Created by Mike Kinney on 11/27/07.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import "NSXMLElementAdditions.h"

//Parsing methods originally written by Josh Wiseman (Facebook, Inc.) and distributed with the iPhoto plugin. modifications made by Mike Kinney 

@implementation NSXMLElement (NSXMLElementAdditions)
-(NSArray *)arrayFromXMLElement
{
	NSMutableArray *array = [[[NSMutableArray alloc] init] autorelease];
	NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
	
	BOOL isList = NO;
	NSString *isListString = [[self attributeForName:@"list"] stringValue];
	if (isListString && [isListString caseInsensitiveCompare:@"true"] == NSOrderedSame)
		isList = YES;
	
	NSEnumerator *e = [[self children] objectEnumerator];
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
			self = childElement;
			// assume the child is a list
			value = [self arrayFromXMLElement];
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
