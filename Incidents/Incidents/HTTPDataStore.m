////
// HTTPDataStore.m
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

#import "Ranger.h"
#import "Incident.h"
#import "HTTPDataStore.h"



@interface HTTPDataStore () <NSConnectionDelegate>

@property (strong) NSURL *url;

@property (strong) NSURLConnection *loadRangersConnection;
@property (strong) NSMutableData   *loadRangersData;

@property (strong) NSMutableDictionary *indexedIncidents;

@end



@implementation HTTPDataStore


- (id) initWithURL:(NSURL *)url
{
    if (self = [super init]) {
        self.url = url;
    }
    return self;
}


@synthesize delegate;


- (NSArray *) incidents
{
    return self.indexedIncidents.allValues;
}


- (BOOL) load
{
    [self allRangersByHandle];
    [self allIncidentTypes];

    return NO;
}


- (Incident *) incidentWithNumber:(NSNumber *)number
{
    return self.indexedIncidents[number];
}


- (Incident *) createNewIncident
{
    NSNumber *temporaryNumber = @-1;

    while (self.indexedIncidents[temporaryNumber]) {
        temporaryNumber = [NSNumber numberWithInteger:temporaryNumber.integerValue-1];
    }

    return [[Incident alloc] initInDataStore:self withNumber:temporaryNumber];
}


- (void) commitIncident:(Incident *)incident
{
    if (! incident || ! incident.number) {
        NSLog(@"Cannot commit invalid incident: %@", incident);
        return;
    }
//    if (incident.number.integerValue < 0) {
//        incident.number = [NSNumber numberWithInt:self.nextIncidentNumber++];
//    }
//    self.indexedIncidents[incident.number] = incident;
//    [self writeIncident:incident];
}


- (BOOL) writeIncident:(Incident *)incident
{
    NSError *error;

    NSLog(@"Writing incident: %@", incident);

    // Option: NSJSONWritingPrettyPrinted
    NSData *data = [NSJSONSerialization dataWithJSONObject:[incident asJSON] options:0 error:&error];
    if (! data) {
        NSLog(@"Unable to serialize to incident %@ to JSON: %@", incident, error);
        return NO;
    }

//    if (! [data writeToURL:childURL options:0 error:&error]) {
//        NSLog(@"Unable to write file: %@", error);
//        return NO;
//    }
//
//    return YES;

    return NO;
}


@synthesize allRangersByHandle;


- (void) loadRangers {
    @synchronized(self) {
        if (! self.loadRangersConnection) {
            NSURL *url = [self.url URLByAppendingPathComponent:@"rangers/"];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [request setHTTPBody:[NSData data]];

            NSURLConnection *connection = [NSURLConnection connectionWithRequest:request
                                                                        delegate:self];

            if (connection) {
                self.loadRangersConnection = connection;
                self.loadRangersData = [NSMutableData data];
            }
        }
    }
}


- (NSDictionary *) allRangersByHandle
{
    if (! allRangersByHandle) {
        [self loadRangers];
    }
    return allRangersByHandle;
}


- (NSArray *) allIncidentTypes
{
    return @[];
}


@end



@implementation HTTPDataStore (NSConnectionDelegate)


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (connection == self.loadRangersConnection) {
        NSLog(@"Load Rangers request got response: %@", response);

        [self.loadRangersData setLength:0];
    }
    else {
        NSLog(@"Unknown connection: %@", connection);
        NSLog(@"…got response: %@", response);
    }
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == self.loadRangersConnection) {
        [self.loadRangersData appendData:data];
    }
    else {
        NSLog(@"Unknown connection: %@", connection);
        NSLog(@"…got data: %@", data);
    }
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (connection == self.loadRangersConnection) {
        NSLog(@"Load Rangers request failed: %@", error);
        self.loadRangersConnection = nil;

        //        NSMutableDictionary *rangers = [[NSMutableDictionary alloc] initWithCapacity:self.rangers.count];
        //
        //        for (Ranger *ranger in self.rangers) {
        //            rangers[ranger.handle] = ranger;
        //        }
        //
        //        allRangersByHandle = rangers;
    }
    else {
        NSLog(@"Unknown connection: %@", connection);
        NSLog(@"…got error: %@", error);
    }
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (connection == self.loadRangersConnection) {
        NSLog(@"Load Rangers request completed.");
        self.loadRangersConnection = nil;
    }
    else {
        NSLog(@"Unknown connection completed: %@", connection);
    }
}


@end

