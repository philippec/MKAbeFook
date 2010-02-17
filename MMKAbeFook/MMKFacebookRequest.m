/*
 
 MMKFacebookRequest.m
 Mobile MKAbeFook
 
 Created by Mike on 3/28/08.
 
 Copyright (c) 2009, Mike Kinney
 All rights reserved.
 
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 
 Neither the name of MKAbeFook nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import <QuartzCore/QuartzCore.h>
#import "MMKFacebookRequest.h"
#import "MMKFacebook.h"

#import "CXMLDocument.h"
#import "CXMLDocumentAdditions.h"
#import "CXMLElementAdditions.h"


#define LOADING_SCREEN_ANIMATION_DURATION 1.0


@implementation MMKFacebookRequest



+(id)requestUsingFacebookConnection:(MMKFacebook *)aFacebookConnection delegate:(id)aDelegate selector:(SEL)aSelector
{
	MMKFacebookRequest *theRequest = [[[MMKFacebookRequest alloc] initWithFacebookConnection:aFacebookConnection delegate:aDelegate selector:aSelector] autorelease];
	return theRequest;
}

+(id)requestUsingFacebookConnection:(MMKFacebook *)aFacebookConnection delegate:(id)aDelegate
{
	MMKFacebookRequest *theRequest = [[[MMKFacebookRequest alloc] initWithFacebookConnection:aFacebookConnection delegate:aDelegate selector:nil] autorelease];
	return theRequest;	
}

-(MMKFacebookRequest *)init
{
	self = [super init];
	if(self != nil)
	{
		_facebookConnection = nil;
		_delegate = nil;
		_selector = @selector(facebookResponseReceived:);
		
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary alloc] init];
		_urlRequestType = MMKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayLoadingSheet = YES;
		_displayGeneralErrors = YES;
		_numberOfRequestAttempts = 5;
		
	}
	return self;
}

-(MMKFacebookRequest *)initWithFacebookConnection:(MMKFacebook *)aFacebookConnection 
										 delegate:(id)aDelegate 
										 selector:(SEL)aSelector
{
	self = [self init];
	if(self != nil)
	{
		[self setDelegate:aDelegate];
		if(aSelector == nil)
			[self setSelector:@selector(facebookResponseReceived:)];
		else
			[self setSelector:aSelector];
		[self setFacebookConnection:aFacebookConnection];
	}
	return self;
}


-(MMKFacebookRequest *)initWithFacebookConnection:(MMKFacebook *)aFacebookConnection 
									   parameters:(NSDictionary *)parameters 
										 delegate:(id)aDelegate 
										 selector:(SEL)aSelector
{
	self = [self initWithFacebookConnection:aFacebookConnection delegate:aDelegate selector:aSelector];
	if(self != nil)
	{
		[self setFacebookConnection:aFacebookConnection];
	}
	return self;
}

#pragma mark Setters and Getters

-(void)setFacebookConnection:(MMKFacebook *)aFacebookConnection
{
	_facebookConnection = aFacebookConnection;
}

-(void)setDelegate:(id)delegate
{
	_delegate = delegate;
}

-(void)setSelector:(SEL)selector
{
	_selector = selector;
}

-(void)setURLRequestType:(MMKFacebookRequestType)urlRequestType
{
	_urlRequestType = urlRequestType;
}

-(int)urlRequestType
{
	return _urlRequestType;
}

-(void)setParameters:(NSDictionary *)parameters
{
	[_parameters addEntriesFromDictionary:parameters];
}

-(void)displayLoadingSheet:(BOOL)shouldDisplayLoadingSheet
{
	_displayLoadingSheet = shouldDisplayLoadingSheet;
}

-(BOOL)displayAPIErrorAlert
{
	return _displayGeneralErrors;
}

-(void)setDisplayAPIErrorAlert:(BOOL)aBool
{
	_displayGeneralErrors = aBool;
}

#pragma mark -

-(void)dealloc
{
	
	//if(_loadingSheet != nil)
	//	[_loadingSheet release];
	
	[_requestURL release];
	[_parameters release];
	[_responseData release];
	[super dealloc];
}

-(void)sendRequest
{

	if(_facebookConnection == nil)
	{
		UIAlertView *uhOh = [[[UIAlertView alloc] initWithTitle:@"Not Connected"
														message:@"Please login to Facebook"
													   delegate:self 
											  cancelButtonTitle:@"Fine!"
											  otherButtonTitles:nil] autorelease];
		[uhOh show];
		return;
	}
	
	//if no user is logged in and they're trying to send a request OTHER than something required for logging in a user abort the request
	if(![_facebookConnection userLoggedIn] && (![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] && ![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"]))
	{
		/*
		NSException *exception = [NSException exceptionWithName:@"Invalid Facebook Connection"
														 reason:@"MKFacebookRequest could not continue because no user is logged in.  Request has been aborted."
													   userInfo:nil];
		
		[exception raise];
		 */
		UIAlertView *uhOh = [[[UIAlertView alloc] initWithTitle:@"Not Connected"
														message:@"Please login to Facebook"
													   delegate:self 
											  cancelButtonTitle:@"Fine!"
											  otherButtonTitles:nil] autorelease];
		[uhOh show];
		
		return;
	}
	
	
	if([_parameters count] == 0)
	{
		if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		{
			NSError *error = [NSError errorWithDomain:@"MKAbeFook" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"No Parameters Specified", @"Error", nil]];
			[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
		}
		return;
	}
	
	//to display some type of loading information we need to have access to the facebookconnection delegate and it must respond to the frontView method defined in the mmkfacebook protocol
	//TODO: this area needs a lot of clean up
	if([[_facebookConnection delegate] respondsToSelector:@selector(applicationView)])
	{
		//display little view at top of screen with a progress indicator in it
		if(_displayLoadingSheet == YES)
		{
			_loadingSheet = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0)];
			[_loadingSheet setBackgroundColor:[UIColor grayColor]];						
			
			UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
			[cancelButton setFrame:CGRectMake(10, -10, kStdButtonWidth - 15, kStdButtonHeight - 10)];
			[cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
			[cancelButton addTarget:self action:@selector(cancelRequest) forControlEvents:UIControlEventTouchUpInside];
			[_loadingSheet addSubview:cancelButton];
			
			UILabel *loadingText = [[UILabel alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width / 2 - 40, 0, 80, 20)];
			[loadingText setBackgroundColor:[UIColor clearColor]];
			[loadingText setTextAlignment:UITextAlignmentCenter];
			loadingText.text = @"Loading";
			loadingText.font = [UIFont boldSystemFontOfSize:19.0];
			loadingText.textColor = [UIColor whiteColor];
			[_loadingSheet addSubview:loadingText];
			
			
			UIActivityIndicatorView *progressIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width - 40, 0, 30, 30)];
			[progressIndicator setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
			[progressIndicator startAnimating];
			[_loadingSheet addSubview:progressIndicator];
			
			
			[[[_facebookConnection delegate] applicationView] addSubview:_loadingSheet];
			
			//[UIView beginAnimations:nil context:NULL];
			//[UIView setAnimationDuration:LOADING_SCREEN_ANIMATION_DURATION];
			[_loadingSheet setFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70)];
			[loadingText setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width / 2 - 40, 33, 80, 20)];
			[progressIndicator setFrame:CGRectMake([[UIScreen mainScreen] bounds].size.width -40, 30 , 30, 30)];
			[cancelButton setFrame:CGRectMake(10, 30, kStdButtonWidth - 15, kStdButtonHeight - 10)]; 
			//[UIView commitAnimations];

			[progressIndicator release];
			[loadingText release];

		}
	}
	
	
	//now to actually prepare the request!
	
	NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
	NSString *applicationVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
	NSString *userAgent;
	if(applicationName != nil && applicationVersion != nil)
		userAgent = [NSString stringWithFormat:@"%@ %@", applicationName, applicationVersion];
	else
		userAgent = @"Mobile MKAbeFook";
	
	
	_requestIsDone = NO;
	if(_urlRequestType == MMKPostRequest)
	{
		NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:_requestURL 
																	 cachePolicy:NSURLRequestReloadIgnoringCacheData 
																 timeoutInterval:[_facebookConnection connectionTimeoutInterval]];
		
		[postRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		
		NSMutableData *postBody = [NSMutableData data];
		NSString *stringBoundary = [NSString stringWithString:@"xXxiFyOuTyPeThIsThEwOrLdWiLlExPlOdExXx"];
		NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", stringBoundary]; //make this here so we only have to do it once and not during every loop
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
		[postRequest setHTTPMethod:@"POST"];
		[postRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
		[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", stringBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		//add items that are required by all requests to _parameters dictionary so they are added to the postRequest and we can easily make a sig from them
		[_parameters setValue:MMKFacebookAPIVersion forKey:@"v"];
		[_parameters setValue:[_facebookConnection apiKey] forKey:@"api_key"];
		[_parameters setValue:MMKFacebookFormat forKey:@"format"];
		
		//all other methods require call_id and session_key
		if(![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || ![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
		{
			[_parameters setValue:[_facebookConnection sessionKey] forKey:@"session_key"];
			[_parameters setValue:[_facebookConnection generateTimeStamp] forKey:@"call_id"];
		}
		
		NSEnumerator *e = [_parameters keyEnumerator];
		id key;
		NSString *imageKey = nil;
		while(key = [e nextObject])
		{
			if([[_parameters objectForKey:key] isKindOfClass:[UIImage class]])
			{
				NSLog(@"found picture to upload");
				NSData *imageData = UIImageJPEGRepresentation([_parameters objectForKey:key], 1.0);
				/*
				NSData *resizedTIFFData = [[_parameters objectForKey:key] UIImageJPEGRepresentation];
				NSBitmapImageRep *resizedImageRep = [NSBitmapImageRep imageRepWithData: resizedTIFFData];
				NSDictionary *imageProperties = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat: 1.0] forKey:UIImageCompressionFactor];
				NSData *imageData = [resizedImageRep representationUsingType: NSJPEGFileType properties: imageProperties];
				*/
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"something\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];	
				[postBody appendData: imageData];
				[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
				
				//we need to remove this the image object from the dictionary so we can generate a correct sig from the other values, but we can't do it here or leopard will complain.  so we'll do it OUTSIDE the while loop.
				//[_parameters removeObjectForKey:key];
				imageKey = [NSString stringWithString:key];
			}else
			{
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[_parameters valueForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];				
			}
			 
		}
		//we can't remove this during the while loop so we'll do it here
		if(imageKey != nil)
			[_parameters removeObjectForKey:imageKey];
		
		[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"sig\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[_facebookConnection generateSigForParameters:_parameters] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
		[postRequest setHTTPBody:postBody];
		_dasConnection = [NSURLConnection connectionWithRequest:postRequest delegate:self];
	}
	
	if(_urlRequestType == MMKGetRequest)
	{
		NSURL *theURL = [_facebookConnection generateFacebookURL:_parameters];
		NSMutableURLRequest *getRequest = [NSMutableURLRequest requestWithURL:theURL 
																  cachePolicy:NSURLRequestReloadIgnoringCacheData 
															  timeoutInterval:[_facebookConnection connectionTimeoutInterval]];
		[getRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		_dasConnection = [NSURLConnection connectionWithRequest:getRequest delegate:self];
	}
	 
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_responseData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	//NSLog(@"response content length :%lld", [response expectedContentLength]);
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MMKFacebookRequestActivityEnded" object:nil];
	
	NSString *temp = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
	NSLog(@"%@", temp);
	NSError *error = nil;
	CXMLDocument *returnXML = [[[CXMLDocument alloc] initWithXMLString:temp options:0 error:&error] autorelease];
	[temp release];
	
	
	if(error != nil)
	{
		[_facebookConnection displayGeneralAPIError:@"API Error" 
											message:@"Facebook returned puke, the API might be down." 
										buttonTitle:@"OK"];
	}else if([returnXML validFacebookResponse] == NO)
	{
		NSDictionary *errorDictionary = [[returnXML rootElement] dictionaryFromXMLElement];
		//4 is a magic number that represents "The application has reached the maximum number of requests allowed. More requests are allowed once the time window has completed."
		//luckily for us Facebook doesn't define "the time window".  fuckers.
		//we will also try the request again if we see a 1 (unknown) or 2 (service unavailable) error
		int errorInt = [[errorDictionary valueForKey:@"error_code"] intValue];
		if((errorInt == 4 || errorInt == 1 || errorInt == 2 ) && _numberOfRequestAttempts <= _requestAttemptCount)
		{
			NSDate *sleepUntilDate = [[NSDate date] addTimeInterval:2.0];
			[NSThread sleepUntilDate:sleepUntilDate];
			[_responseData setData:[NSData data]];
			_requestAttemptCount++;
			NSLog(@"Too many requests, waiting just a moment....%@", [self description]);
			[self sendRequest];
			return;
		}
		NSLog(@"I GAVE UP!!! throw it away...");
		//we've tried the request a few times, now we're giving up.
		if([_delegate respondsToSelector:@selector(facebookErrorResponseReceived:)])
			[_delegate performSelector:@selector(facebookErrorResponseReceived:) withObject:returnXML];
		
		NSString *errorTitle = [NSString stringWithFormat:@"Error: %@", [errorDictionary valueForKey:@"error_code"]];
		if([self displayAPIErrorAlert])
		{
			[_facebookConnection displayGeneralAPIError:errorTitle message:[errorDictionary valueForKey:@"error_msg"] buttonTitle:@"OK"];			
		}
	}else
	{
		if([_delegate respondsToSelector:_selector])
			[_delegate performSelector:_selector withObject:returnXML];		
	}

	[_responseData setData:[NSData data]];
	_requestIsDone = YES;
	
	[self returnToApplicationView];
	
}

-(void)returnToApplicationView
{
	if([[_facebookConnection delegate] respondsToSelector:@selector(applicationView)])
	{
		if(_displayLoadingSheet == YES)
		{
			[_loadingSheet removeFromSuperview];
			
		}
	}
}


-(void)cancelRequest
{
	if(_requestIsDone == NO)
	{
		//NSLog(@"cancelling request...");
		[_dasConnection cancel];
		_requestIsDone = YES;
	}
	[self returnToApplicationView];
}

//TODO: document that we will automatically present the user with an error message but additional information can be passed or clean up can be done using the delegate calls
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{	
	if([self displayAPIErrorAlert])
		[_facebookConnection displayGeneralAPIError:@"Connection Error" message:@"Are you connected to the interwebs?" buttonTitle:@"OK"];
	
	if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
}


@end
