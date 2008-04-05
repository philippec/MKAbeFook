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
//  NSXMLElementAdditions.h
//  BRAP Client
//
//  Created by Mike Kinney on 11/27/07.
//  Copyright 2008 Mike Kinney. All rights reserved.
//

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
