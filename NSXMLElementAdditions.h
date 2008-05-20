/*
 
 NSXMLElementAdditions.h
 BRAP Client

 Created by Mike Kinney on 11/27/07.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

//Parsing methods originally written by Josh Wiseman (Facebook, Inc.) and distributed with the iPhoto plugin. modifications made by Mike Kinney 

#import <Cocoa/Cocoa.h>

/*!
 @category NSXMLElementAdditions(NSXMLElement)
 @brief Adds arrayFromXMLElement and dictionaryFromXMLElement to NSXMLElement class.
 
 The -(NSArray *)arrayFromXMLElement method recursively traverses the hierarchy rooted at XMLElement, aggregating the top-level results into a list (array). If conflicting top-level elements are found, the top-level elements are packaged into a structure (dictionary), and returned as the only object of the array. Each element in the array is either another array, a dictionary, or a string.
 
 The -(NSDictionary *)dictionaryFromXMLElement method Recursively traverses the hierarchy rooted at XMLElement, aggregating the top-level results into a structure (dictionary). Each element in the dictionary is either an array, a dictionary, or a string.

 @version 0.7
 */
@interface NSXMLElement (NSXMLElementAdditions)

-(NSArray *)arrayFromXMLElement;
-(NSDictionary *)dictionaryFromXMLElement;

@end
