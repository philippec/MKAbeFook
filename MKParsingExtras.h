/*

 MKParsingExtras.h
 MKAbeFook

 Created by Mike on 12/1/06.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.

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
