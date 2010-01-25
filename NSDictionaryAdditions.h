//
//  NSDictionaryAdditions.h
//  MKAbeFook
//
//  Created by Mike Kinney on 10/22/09.
//  Copyright 2009 All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSDictionary (NSDictionaryAdditions)


/*! @name Validating
 *	Validates NSDictionary
 */
//@{

/*!
 @brief Checks to see if NSDictionary is a valid response from Facebook.
 
 Returns FALSE if dictionary does not represent a valid response.
 
 @return BOOL
 */
- (BOOL)validFacebookResponse;
//@}

@end
