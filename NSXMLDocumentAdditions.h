/*

 NSXMLDocumentAdditions.h
 MKAbeFook

 Created by Mike Kinney on 12/15/07.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

//Parsing methods originally written by Josh Wiseman (Facebook, Inc.) and distributed with the iPhoto plugin. modifications made by Mike Kinney 

#import <Cocoa/Cocoa.h>

/*!
@category NSXMLDocumentAdditions (NSXMLDocument)
 @brief Adds validFacebookResponse method to NSXMLDocument class.
 
 This category adds the -(BOOL)validFacebookResponse method to the NSXMLDocument class.  If the XML returned by Facebook.com contains an error validFacebookResponse returns NO.
  @version 0.7 and later
*/

@interface NSXMLDocument (NSXMLDocumentAdditions)

-(BOOL)validFacebookResponse;
@end
