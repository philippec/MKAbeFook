//
//  NSStringExtras.m
//  MKAbeFook
//
//  Created by Mike Kinney on 9/20/09.
//  Copyright 2009 Mike Kinney. All rights reserved.
//

#import "NSStringExtras.h"



@implementation NSString(NSStringExtras)
/*
 Encode a string legally so it can be turned into an NSURL
 Original Source: <http://cocoa.karelia.com/Foundation_Categories/NSString/Encode_a_string_leg.m>
 (See copyright notice at <http://cocoa.karelia.com>)
 */

/*"	Fix a URL-encoded string that may have some characters that makes NSURL barf.
 It basicaly re-encodes the string, but ignores escape characters + and %, and also #.
 "*/
- (NSString *) encodeURLLegally
{
	NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(
																			NULL, (CFStringRef) self, (CFStringRef) @"%+#", NULL,
																			CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
	return result;
}
@end
