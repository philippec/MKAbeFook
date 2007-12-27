/*
 Copyright (c) 2007, Mike Kinney
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
//  NSXMLDocumentAdditions.h
//  MKAbeFook
//
//  Created by Mike Kinney on 12/15/07.
//  Copyright 2007 Mike Kinney. All rights reserved.
//

//Parsing methods originally written by Josh Wiseman (Facebook, Inc.) and distributed with the iPhoto plugin. modifications made by Mike Kinney 

#import <Cocoa/Cocoa.h>

/*!
@category NSXMLDocumentAdditions(NSXMLDocument)
 @discussion Extends NSXMLDocument
  @version 0.7 and later
*/

@interface NSXMLDocument (NSXMLDocumentAdditions)
/*!
@method validFacebookResponse
 @result Returns true if XML does not contain any errors from Facebook.
  @version 0.7 and later
*/
-(BOOL)validFacebookResponse;

@end
