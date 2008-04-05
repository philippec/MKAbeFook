/*
 Copyright (c) 2008, Mike Kinney
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
 following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the 
 following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the 
 following disclaimer in the documentation and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

//
//  NSXMLElementAdditions.m
//  BRAP Client
//
//  Created by Mike Kinney on 11/27/07.
//  Copyright 2008 Mike Kinney. All rights reserved.
//

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
