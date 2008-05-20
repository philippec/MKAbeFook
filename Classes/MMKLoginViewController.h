/*

 MMKLoginViewController.h
 Mobile MKAbeFook

 Created by Mike on 3/28/08.
 
 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import <UIKit/UIKit.h>

@interface MMKLoginViewController : UIViewController <UIWebViewDelegate> {
	UIWebView *_loginWebView;
	id _delegate;
	SEL _selector;
	UIActivityIndicatorView *_activityIndicator;
}
-(id)initWithDelegate:(id)aDelegate withSelector:(SEL)aSelector;
-(void)loadURL:(NSURL *)loginURL;
-(id)webView;
-(void)loadView;
@end
