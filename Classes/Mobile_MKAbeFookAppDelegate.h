//
//  Mobile_MKAbeFookAppDelegate.h
//  Mobile MKAbeFook
//
//  Created by Mike Kinney on 3/28/08.
//  Copyright Mike Kinney 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyView;

@interface Mobile_MKAbeFookAppDelegate : NSObject {
    UIWindow *window;
    MyView *contentView;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) MyView *contentView;

@end
