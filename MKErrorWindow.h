//
//  MKErrorWindow.h
//  MKAbeFook
//
//  Created by Mike Kinney on 7/21/08.
//

#import <Cocoa/Cocoa.h>

/*!
 @brief Display simple error messages with option of providing more details
 
 @class MKErrorWindow
 MKErrorWindow is used to display error messages that may or may not contain additional information useful for debugging the error.
 
 
 */

@interface MKErrorWindow : NSWindowController {

	IBOutlet NSImageView *errorImage;
	IBOutlet NSTextField *errorTitle;
	IBOutlet NSTextField *errorMessage;
	IBOutlet NSTextView *errorDetails;
	
	IBOutlet NSButton *detailsButton;
	
	NSString *_errorTitle;
	NSString *_errorMessage;
	NSString *_errorDetails;
	
}
/*!
 @param title Error title (required)
 @param message Brief error message (required)
 @param details Extended details about the error, pass nill if you have no details to display. (optional)

 Create a new error window with appropriate title, error message, and additional details.
 
 @result Returns allocated and initiated MKErrorWindow that will automatically be released when closed (user clicks OK).
 @version 0.7.7 and later
 */
+(MKErrorWindow *)errorWindowWithTitle:(NSString *)title message:(NSString *)message details:(NSString *)details;

/*used internally*/
-(MKErrorWindow *)initWithTitle:(NSString *)title message:(NSString *)message details:(NSString *)details;

/*!
 
 Displays error window in the center of the screen.
 
 @version 0.7.7 and later
 */
-(void)display;
-(IBAction)okButton:(id)sender;
-(IBAction)detailsButton:(id)sender;

@end
