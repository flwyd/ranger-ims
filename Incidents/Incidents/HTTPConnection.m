////
// HTTPConnection.m
// Incidents
////
// See the file COPYRIGHT for copyright information.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
////

#import "utilities.h"
#import "HTTPConnection.h"



@interface HTTPConnection () <NSConnectionDelegate>

@property (assign) BOOL active;

@property (strong) NSURLRequest      *request;
@property (strong) NSHTTPURLResponse *responseInfo;
@property (strong) NSData            *responseData;

@property (strong) NSURLConnection *urlConnection;

@property (strong) HTTPResponseHandler onSuccess;
@property (strong) HTTPErrorHandler    onError;

@end



@implementation HTTPConnection


+ (HTTPConnection *) JSONQueryConnectionWithURL:(NSURL *)url
                                responseHandler:(HTTPResponseHandler)onSuccess
                                   errorHandler:(HTTPErrorHandler)onError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:[NSData data]];

    return [[HTTPConnection alloc] initWithRequest:request
                                   responseHandler:onSuccess
                                      errorHandler:onError];
}


+ (HTTPConnection *) JSONPostConnectionWithURL:(NSURL *)url
                                          body:(NSData *)body
                               responseHandler:(HTTPResponseHandler)onSuccess
                                  errorHandler:(HTTPErrorHandler)onError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:body];

    return [[HTTPConnection alloc] initWithRequest:request
                                   responseHandler:onSuccess
                                      errorHandler:onError];
}


- (id) initWithRequest:(NSURLRequest *)request
       responseHandler:(HTTPResponseHandler)onSuccess
          errorHandler:(HTTPErrorHandler)onError
{
    if (self = [super init]) {
        self.active = YES;

        self.request      = request;
        self.responseInfo = nil;
        self.responseData = [NSMutableData data];

        self.urlConnection = [NSURLConnection connectionWithRequest:request delegate:self];

        self.onSuccess = onSuccess;
        self.onError   = onError;

        if (! self.urlConnection) {
            NSError *error = [[NSError alloc] initWithDomain:@"HTTPConnection"
                                                        code:0
                                                    userInfo:@{NSLocalizedDescriptionKey: @"Unable to initialize connection."}];
            [self reportError:error];
        }
    }
    return self;
}


- (void) reportResponse
{
    self.active = NO;
    if (self.onSuccess) {
        self.onSuccess(self);
    }
}


- (void) reportError:(NSError *)error
{
    self.active = NO;
    if (self.onError) {
        self.onError(self, error);
    }
}


@end



@implementation HTTPConnection (NSConnectionDelegate)


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    if (! [connection isEqual:self.urlConnection]) {
        NSLog(@"Got response from unknown connection?!?!");
        return;
    }

    NSString *whyIDontLikeThisResponse = nil;

    if (! [response isKindOfClass:NSHTTPURLResponse.class]) {
        whyIDontLikeThisResponse = [NSString stringWithFormat:@"Unexpected (non-HTTP) response: %@", response];
    }
    else if (response.statusCode != 200) {
        whyIDontLikeThisResponse = [NSString stringWithFormat:@"Unexpected response code from server: %ld", response.statusCode];
    }
    else if (! [response.MIMEType isEqualToString:@"application/json"]) {
        whyIDontLikeThisResponse = [NSString stringWithFormat:@"Unexpected (non-JSON) MIME type: %@", response.MIMEType];
    }

    if (whyIDontLikeThisResponse) {
        self.responseData = nil;

        NSError *error = [[NSError alloc] initWithDomain:@"HTTPConnection"
                                                    code:response.statusCode
                                                userInfo:@{NSLocalizedDescriptionKey: whyIDontLikeThisResponse}];

        [self reportError:error];
    }
    else {
        [(NSMutableData *)self.responseData setLength:0];
    }
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (! [connection isEqual:self.urlConnection]) {
        NSLog(@"Got data from unknown connection?!?!");
        return;
    }

    [(NSMutableData *)self.responseData appendData:data];
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (! [connection isEqual:self.urlConnection]) {
        NSLog(@"Got error from unknown connection?!?!");
        return;
    }

    self.urlConnection = nil;
    self.responseData = nil;

    [self reportError:error];
}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (! [connection isEqual:self.urlConnection]) {
        NSLog(@"Got success from unknown connection?!?!");
        return;
    }

    [self reportResponse];
}


@end
