//
//  CXMLElementAdditions.h
//  Mobile MKAbeFook
//
//  Created by Mike Kinney on 3/31/08.
//  Copyright 2008 Mike Kinney. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CXMLElement.h"

@interface CXMLElement (CXMLElementAdditions)
-(NSArray *)arrayFromXMLElement;
-(NSDictionary *)dictionaryFromXMLElement;
@end
