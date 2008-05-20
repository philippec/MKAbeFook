/*
 
 LoginWindow.h
 MKAbeFook

 Created by Mike on 10/11/06.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import <Cocoa/Cocoa.h>
//0.6 case sensitivity issue fixed.  Thanks Dale.
#import <WebKit/WebKit.h>
@interface MKLoginWindow : NSWindowController {
	NSString *path;
	IBOutlet WebView *loginWebView;
	IBOutlet NSButton *closeSheetButton; 
	id _delegate;
	SEL _selector;
}

-(id)initWithDelegate:(id)aDelegate withSelector:(SEL)aSelector;
-(id)initForSheetWithDelegate:aDelegate withSelector:(SEL)aSelector;
-(void)loadURL:(NSURL *)loginURL;
-(IBAction)closeSheet:(id)sender;
-(void)setWindowSize:(NSSize)windowSize;

@end
