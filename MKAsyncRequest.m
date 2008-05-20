/*
 
 MKAsyncRequest.m
 MKAbeFook

 Created by Mike on 3/8/07.

 This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
 To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/us/legalcode or send a letter to Creative Commons, 543 Howard Street, 5th Floor, San Francisco, California, 94105, USA.
 
*/

#import "MKAsyncRequest.h"


@implementation MKAsyncRequest

-(MKAsyncRequest *)initWithFacebookConnection:(MKFacebook *)aFacebookConnection 
					   delegate:(id)aDelegate 
					   selector:(SEL)aSelector
{
	//if(![aFacebookConnection userLoggedIn])
	//{
		//hmm what should we do here?
	//}

	self = [super init];
	facebookConnection = aFacebookConnection;
	_delegate = aDelegate;
	_selector = aSelector;
	_shouldReleaseWhenFinished = YES;
	responseData = [[NSMutableData alloc] init];
	return self;
}

-(void)dealloc
{
	[responseData release];
	[super dealloc];
}

+(void)fetchFacebookData:(NSString *)aMethodName parameters:(NSDictionary *)parameters facebookConnection:aFacebookConnection delegate:(id)aDelegate selector:(SEL)aSelector
{
	self = [[MKAsyncRequest alloc] initWithFacebookConnection:aFacebookConnection
													 delegate:aDelegate
													 selector:aSelector];
	
	NSURL *theURL = [aFacebookConnection generateFacebookURL:aMethodName parameters:parameters];
	

	//0.6 now uses connectionTimeoutInterval from aFacebookConnection.  Thanks Adam.
	NSURLRequest *request = [NSURLRequest requestWithURL:theURL 
											 cachePolicy:NSURLRequestReloadIgnoringCacheData 
										 timeoutInterval:[aFacebookConnection connectionTimeoutInterval]];
	
	[NSURLConnection connectionWithRequest:request
								  delegate:self];
}

-(void)fetchFacebookData:(NSString *)aMethodName parameters:(NSDictionary *)parameters
{
	_shouldReleaseWhenFinished = NO;
	_requestIsDone = NO;
	NSURL *theURL = [facebookConnection generateFacebookURL:aMethodName parameters:parameters];
	NSURLRequest *request = [NSURLRequest requestWithURL:theURL
											 cachePolicy:NSURLRequestReloadIgnoringCacheData
											 timeoutInterval:[facebookConnection connectionTimeoutInterval]];
	dasConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[responseData appendData:data];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSXMLDocument *returnXML = [[[NSXMLDocument alloc] initWithData:responseData
														   options:0
															 error:nil] autorelease];
	/*	
	if(![facebookConnection validXMLResponse:returnXML])
	{
		if([_delegate respondsToSelector:@selector(receivedFacebookXMLErrorResponse:)])
			[_delegate performSelector:@selector(receivedFacebookXMLErrorResponse:) withObject:returnXML];
	}
	*/
	
	if([_delegate respondsToSelector:_selector])
		[_delegate performSelector:_selector withObject:returnXML];
	
	 
	//if we're just doing one request we release ourself when we're done
	if(_shouldReleaseWhenFinished == YES)
	{
		[self release];
	}else //otherwise we need to keep ourself around and clean up our data instance variable
	{
		[responseData setData:[NSData data]];
		_requestIsDone = YES;
	}
}

-(void)cancel
{
	if(_requestIsDone == NO)
	{
		//NSLog(@"cancelling request...");
		[dasConnection cancel];
		_requestIsDone = YES;
	}
}

//0.6 suggestion to pass connection error.  Thanks Adam.
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	/* i like this better.  we'll switch to this eventually
	if([_delegate respondsToSelector:@selector(facebookRequestFailed:)])
		[_delegate performSelector:@selector(facebookRequestFailed:) withObject:error];
	 */
	
	if([_delegate respondsToSelector:@selector(asyncRequestFailed:)])
		[_delegate performSelector:@selector(asyncRequestFailed:) withObject:error];
}


@end
