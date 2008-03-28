//
//  CXMLElement.m
//  TouchXML
//
//  Created by Jonathan Wight on 03/07/08.
//  Copyright 2008 Toxic Software. All rights reserved.
//

#import "CXMLElement.h"

#import "CXMLNode_PrivateExtensions.h"

@implementation CXMLElement

- (NSArray *)elementsForName:(NSString *)name
{
NSMutableArray *theElements = [NSMutableArray array];

// TODO -- native xml api?
const xmlChar *theName = (const xmlChar *)[name UTF8String];

xmlNodePtr theCurrentNode = _node->children;
while (theCurrentNode != NULL)
	{
	if (theCurrentNode->type == XML_ELEMENT_NODE && xmlStrcmp(theName, theCurrentNode->name) == 0)
		{
		CXMLNode *theNode = [CXMLNode nodeWithLibXMLNode:(xmlNodePtr)theCurrentNode];
		[theElements addObject:theNode];
		}
	theCurrentNode = theCurrentNode->next;
	}
return(theElements);
}

//- (NSArray *)elementsForLocalName:(NSString *)localName URI:(NSString *)URI;

- (NSArray *)attributes
{
NSMutableArray *theAttributes = [NSMutableArray array];
xmlAttrPtr theCurrentNode = _node->properties;
while (theCurrentNode != NULL)
	{
	CXMLNode *theAttribute = [CXMLNode nodeWithLibXMLNode:(xmlNodePtr)theCurrentNode];
	[theAttributes addObject:theAttribute];
	theCurrentNode = theCurrentNode->next;
	}
return(theAttributes);
}

- (CXMLNode *)attributeForName:(NSString *)name
{
// TODO -- look for native libxml2 function for finding a named attribute (like xmlGetProp)
const xmlChar *theName = (const xmlChar *)[name UTF8String];

xmlAttrPtr theCurrentNode = _node->properties;
while (theCurrentNode != NULL)
	{
	if (xmlStrcmp(theName, theCurrentNode->name) == 0)
		{
		CXMLNode *theAttribute = [CXMLNode nodeWithLibXMLNode:(xmlNodePtr)theCurrentNode];
		return(theAttribute);
		}
	theCurrentNode = theCurrentNode->next;
	}
return(NULL);
}

//- (CXMLNode *)attributeForLocalName:(NSString *)localName URI:(NSString *)URI;

//- (NSArray *)namespaces; //primitive
//- (CXMLNode *)namespaceForPrefix:(NSString *)name;
//- (CXMLNode *)resolveNamespaceForName:(NSString *)name;
//- (NSString *)resolvePrefixForNamespaceURI:(NSString *)namespaceURI;


@end


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
