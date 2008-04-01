/*
Copyright (c) 2008, Mike Kinney
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the 
following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the 
following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the 
following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
*/
//
//  MMKFacebookRequest.m
//  Mobile MKAbeFook
//
//  Created by Mike on 3/28/08.
//  Copyright 2007 Mike Kinney. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MMKFacebookRequest.h"
#import "MMKFacebook.h"

#import "CXMLDocument.h"
#import "CXMLDocumentAdditions.h"
#import "CXMLElementAdditions.h"

#define kProgressIndicatorView 999
#define LOADING_SCREEN_ANIMATION_DURATION 0.5

@implementation MMKFacebookRequest

-(MMKFacebookRequest *)init
{
	self = [super init];
	
	if(self != nil)
	{
		//NSLog(@"initiated1");
		
		facebookConnection = nil;
		_delegate = nil;
		_selector = nil;
		
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary alloc] init];
		_urlRequestType = MMKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayLoadingSheet = NO;
		_displayLoadingView = NO;
		
		_loadingViewTransitionType = [[NSString alloc] init];
		_loadingViewTransitionSubtype = [[NSString alloc] init];
		_loadingViewTransitionDuration = 0.5;
		
	}
	return self;
}

-(MMKFacebookRequest *)initWithFacebookConnection:(MMKFacebook *)aFacebookConnection 
					   delegate:(id)aDelegate 
					   selector:(SEL)aSelector
{
	//if(![aFacebookConnection userLoggedIn])
	//{
		//hmm what should we do here?
	//}

	self = [super init];
	if(self != nil)
	{
		//NSLog(@"initiated2");
		facebookConnection = [aFacebookConnection retain];
		_delegate = aDelegate;
		_selector = aSelector;
		
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary alloc] init];
		_urlRequestType = MMKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
		_displayLoadingSheet = NO;
		
	}
	return self;
}


-(MMKFacebookRequest *)initWithFacebookConnection:(MMKFacebook *)aFacebookConnection
									  parameters:(NSDictionary *)parameters
										delegate:(id)aDelegate 
										selector:(SEL)aSelector
{
	//if(![aFacebookConnection userLoggedIn])
	//{
	//hmm what should we do here?
	//}
	
	self = [super init];
	if(self != nil)
	{
		facebookConnection = [aFacebookConnection retain];
		_delegate = aDelegate;
		_selector = aSelector;
		
		_responseData = [[NSMutableData alloc] init];
		_parameters = [[NSMutableDictionary dictionaryWithDictionary:parameters] retain];
		_urlRequestType = MMKPostRequest;
		_requestURL = [[NSURL URLWithString:MKAPIServerURL] retain];
	}
	return self;
}

-(void)setFacebookConnection:(MMKFacebook *)aFacebookConnection
{
	facebookConnection = aFacebookConnection;
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
	//_parameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
}

-(void)setDisplayLoadingSheet:(BOOL)shouldDisplayLoadingSheet
{
	_displayLoadingSheet = shouldDisplayLoadingSheet;
}

-(void)dealloc
{
	[_loadingSheet release];
	[_requestURL release];
	[_parameters release];
	[_responseData release];
	[super dealloc];
}

-(void)sendRequest
{
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
	if([[facebookConnection delegate] respondsToSelector:@selector(frontView)])
	{
		if(_displayLoadingSheet == YES)
		{
			_loadingSheet = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0)];
			[_loadingSheet setBackgroundColor:[UIColor blueColor]];
			[_loadingSheet setTag: kProgressIndicatorView];
			[[[facebookConnection delegate] frontView] addSubview:_loadingSheet];
			
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:LOADING_SCREEN_ANIMATION_DURATION];
			[_loadingSheet setBounds:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 200)];
			[UIView commitAnimations];

		}else if(_displayLoadingView == YES)
		{
			if(_loadingView == nil)
			{
				_loadingView = @"DEFAULT LOADING VIEW CLASS";
			}
			[[[facebookConnection delegate] frontView] addSubview:_loadingView];
			CATransition *animation = [CATransition animation];
			[animation setDelegate:self];
			[animation setType:_loadingViewTransitionType];
			[animation setSubtype:_loadingViewTransitionSubtype];
			[animation setDuration: _loadingViewTransitionDuration];
			[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
			[[[[facebookConnection delegate] frontView] layer] addAnimation: animation forKey:nil];
		}
	}
	
	
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
		//NSLog([facebookConnection description]);
		NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:_requestURL 
																	 cachePolicy:NSURLRequestReloadIgnoringCacheData 
																 timeoutInterval:[facebookConnection connectionTimeoutInterval]];
		
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
		[_parameters setValue:[facebookConnection apiKey] forKey:@"api_key"];
		[_parameters setValue:MMKFacebookFormat forKey:@"format"];
		
		//all other methods require call_id and session_key
		if(![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.getSession"] || ![[_parameters valueForKey:@"method"] isEqualToString:@"facebook.auth.createToken"])
		{
			[_parameters setValue:[facebookConnection sessionKey] forKey:@"session_key"];
			[_parameters setValue:[facebookConnection generateTimeStamp] forKey:@"call_id"];
		}
		
		NSEnumerator *e = [_parameters keyEnumerator];
		id key;
		NSString *imageKey = nil; //apparently G4s don't like it when you don't at least set this to = nil.  0.7.3 fix.
		while(key = [e nextObject])
		{
			
			if([[_parameters objectForKey:key] isKindOfClass:[UIImage class]])
			{
				/*SKIPPING PHOTO HANDLING FOR NOW
				NSData *resizedTIFFData = [[_parameters objectForKey:key] TIFFRepresentation];
				NSBitmapImageRep *resizedImageRep = [NSBitmapImageRep imageRepWithData: resizedTIFFData];
				NSDictionary *imageProperties = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat: 1.0] forKey:UIImageCompressionFactor];
				NSData *imageData = [resizedImageRep representationUsingType: NSJPEGFileType properties: imageProperties];
				
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; filename=\"something\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[NSString stringWithString:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];	
				[postBody appendData: imageData];
				[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
				
				//we need to remove this the image object from the dictionary so we can generate a correct sig from the other values, but we can't do it here or leopard will complain.  so we'll do it OUTSIDE the while loop.
				//[_parameters removeObjectForKey:key];
				imageKey = [NSString stringWithString:key];
				*/
			}else
			{
			 
				[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[[_parameters valueForKey:key] dataUsingEncoding:NSUTF8StringEncoding]];
				[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];				
			}
			 
		}
		//0.7.1 fix.  we can't remove this during the while loop so we'll do it here
		if(imageKey != nil)
			[_parameters removeObjectForKey:imageKey];
		
		[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"sig\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[facebookConnection generateSigForParameters:_parameters] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[endLine dataUsingEncoding:NSUTF8StringEncoding]];
		
		[postRequest setHTTPBody:postBody];
		dasConnection = [NSURLConnection connectionWithRequest:postRequest delegate:self];
	}
	
	if(_urlRequestType == MMKGetRequest)
	{
		NSURL *theURL = [facebookConnection generateFacebookURL:_parameters];
		
		NSMutableURLRequest *getRequest = [NSMutableURLRequest requestWithURL:theURL 
																  cachePolicy:NSURLRequestReloadIgnoringCacheData 
															  timeoutInterval:[facebookConnection connectionTimeoutInterval]];
		[getRequest setValue:userAgent forHTTPHeaderField:@"User-Agent"];
		
		dasConnection = [NSURLConnection connectionWithRequest:getRequest delegate:self];
	}
	 
}


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *temp = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
	CXMLDocument *returnXML = [[CXMLDocument alloc] initWithXMLString:temp options:0 error:nil];
	[temp release];
	
	/*
	id returnObject;
	
	if([[returnXML rootElement] childCount] == 1)
		returnObject = [NSDictionary dictionaryWithObjectsAndKeys:[[returnXML rootElement] stringValue], [[returnXML rootElement] name], nil];
	else
		returnObject = [[returnXML rootElement] dictionaryFromXMLElement];
	
	NSLog([returnObject description]);
	return;
	*/
	 
	if([returnXML validFacebookResponse] == NO)
	{
		if([_delegate respondsToSelector:@selector(receivedFacebookXMLErrorResponse:)])
			[_delegate performSelector:@selector(receivedFacebookXMLErrorResponse:) withObject:returnXML];
	}
	
	if([_delegate respondsToSelector:_selector])
		[_delegate performSelector:_selector withObject:returnXML];
	
	[_responseData setData:[NSData data]];
	_requestIsDone = YES;
	
	[self returnToApplicationView];
	
}

-(void)returnToApplicationView
{
	if([[facebookConnection delegate] respondsToSelector:@selector(frontView)])
	{
		if(_displayLoadingSheet == YES)
		{
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:LOADING_SCREEN_ANIMATION_DURATION];
			[_loadingSheet setBounds:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 0)];
			[UIView commitAnimations];
			/* we don't remove from super view because it's released in the dealloc method, we can remove it from super view there if we need to */
			//[_loadingSheet removeFromSuperview];
			
		}else if(_displayLoadingView == YES)
		{
			CATransition *animation = [CATransition animation];
			[animation setDelegate:self];
			[animation setType:_loadingViewTransitionType];
			[animation setSubtype:_loadingViewTransitionSubtype];
			[animation setDuration: _loadingViewTransitionDuration];
			[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
			[[[[facebookConnection delegate] frontView] layer] addAnimation: animation forKey:nil];
			[_loadingView removeFromSuperview];
		}
	}
}


-(void)cancelRequest
{
	if(_requestIsDone == NO)
	{
		//NSLog(@"cancelling request...");
		[dasConnection cancel];
		_requestIsDone = YES;
	}
	[self returnToApplicationView];
}

//0.6 suggestion to pass connection error.  Thanks Adam.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{	
	if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
}

-(void)setDisplayLoadingView:(UIView *)view transitionType:(NSString *)transitionType transitionSubtype:(NSString *)transitionSubtype duration:(CFTimeInterval)duration
{
	_displayLoadingSheet = NO;
	
	_displayLoadingView = YES;
	
	_loadingView = view;

	transitionType = [transitionType copy];
	[_loadingViewTransitionType release];
	_loadingViewTransitionType = transitionType;
	
	transitionSubtype = [transitionSubtype copy];
	[_loadingViewTransitionSubtype release];
	_loadingViewTransitionSubtype = transitionSubtype;
	
	_loadingViewTransitionDuration = duration;
	
}


@end
