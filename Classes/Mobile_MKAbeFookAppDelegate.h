//
//  Mobile_MKAbeFookAppDelegate.h
//  Mobile MKAbeFook
//
//  Created by Mike Kinney on 3/28/08.
//  Copyright Mike Kinney 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyView;
#import "MMKFacebook.h"

@interface Mobile_MKAbeFookAppDelegate : NSObject <MMKFacebook, UIModalViewDelegate> {
    UIWindow *window;
	UIView *_frontView;
	UILabel *_text;
	UIButton *_loginButton;
	MMKFacebook *_facebookConnection;
}

-(UIView *)frontView;


@property (nonatomic, retain) UIWindow *window;


@end