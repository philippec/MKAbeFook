//
//  MKParsingExtras.h
//  MKAbeFook
//
//  Created by Mike on 12/1/06.
/*
 Copyright (c) 2008, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */


//
//  Modified by Josh Wiseman (Facebook, Inc.) on 1/24/07
//

//0.6.3 this category is deprecated.  use NSXMLElementAdditions instead.

#import "MKAbeFook.h"
/*!
 @brief Adds XML parsing methods to MKFacebook class (Deprecated in 0.7)
 
 @category MKParsingExtras(MKFacebook)
  This category is deprecated as of 0.7.  Use methods in NSXMLDocumentAdditions and NSXMLElementAdditions instead.
 @deprecated Deprecated as of version 0.7
 */

@interface MKFacebook (MKParsingExtras)

// helper methods

	/*!

	 @param XMLElement The element from which to generate the array
	  Parses XML into NSArray object.
	  Recursively traverses the hierarchy rooted at XMLElement, aggregating the top-level results into a list (array). If conflicting top-level elements are found, the top-level elements are packaged into a structure (dictionary), and returned as the only object of the array. Each element in the array is either another array, a dictionary, or a string.
	 @result NSArray
	  @deprecated Deprecated as of version 0.7
	*/
-(NSArray *)arrayFromXMLElement:(NSXMLElement *)XMLElement;

	/*!
	 @param XMLElement The element from which to generate the dictionary
	  Parses XML into NSDictionary object.
	  Recursively traverses the hierarchy rooted at XMLElement, aggregating the top-level results into a structure (dictionary). Each element in the dictionary is either an array, a dictionary, or a string.
	 @result NSDictionary
	  @deprecated Deprecated as of version 0.7
	 */
-(NSDictionary *)dictionaryFromXMLElement:(NSXMLElement *)XMLElement;

	/*!
	 @param XMLResponse An NSXMLDocument, the result of a Facebook API call
	  Determines whether an XML response from a Facebook API call is valid
	  Checks the top-level element of an XML response, making sure that it isn't an error.
	 @result BOOL
	  @deprecated Deprecated as of version 0.7
	*/
-(BOOL)validXMLResponse:(NSXMLDocument *)XMLResponse;

	/*!
	 @param XMLResponse An XMLDoccument, the result of a Facebook API call
	  Parses an XML response from a Facebook API call into an array. See arrayfromXMLElement: for the semantics of the response.
	 @result NSArray
	  @deprecated Deprecated as of version 0.7
	*/
-(NSArray *)arrayFromXMLResponse:(NSXMLDocument *)XMLResponse;

	/*!
	 @param XMLResponse An XMLDoccument, the result of a Facebook API call
	 Parses an XML response from a Facebook API call into a dictionary. See dictionaryfromXMLElement: for the semantics of the response.
	 @result NSDictionary
	  @deprecated Deprecated as of version 0.7
	 */
-(NSDictionary *)dictionaryFromXMLResponse:(NSXMLDocument *)XMLResponse;


@end
