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

@property (strong) NSURLConnection *loadIncidentsConnection;
@property (strong) NSMutableData   *loadIncidentsData;

@property (strong) NSURLConnection *loadRangersConnection;
@property (strong) NSMutableData   *loadRangersData;

@property (strong) NSURLConnection *loadIncidentTypesConnection;
@property (strong) NSMutableData   *loadIncidentTypesData;

@property (strong,readonly) NSDictionary *allIncidentsByNumber;

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
    return self.allIncidentsByNumber.allValues;
}


- (BOOL) load
{
    [self loadIncidentTypes];
    [self loadRangers];
    [self loadIncidents];

    return NO;
}


- (Incident *) incidentWithNumber:(NSNumber *)number
{
    return self.allIncidentsByNumber[number];
}


- (Incident *) createNewIncident
{
    NSNumber *temporaryNumber = @-1;

    while (self.allIncidentsByNumber[temporaryNumber]) {
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
//    self.allIncidentsByNumber[incident.number] = incident;
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


- (NSURLConnection *) getJSONConnectionForPath:(NSString *)path
{
    NSURL *url = [self.url URLByAppendingPathComponent:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:[NSData data]];
    
    return [NSURLConnection connectionWithRequest:request delegate:self];
}


@synthesize allIncidentsByNumber;


- (void) loadIncidents
{
    @synchronized(self) {
        if (! self.loadIncidentsConnection) {
            NSURLConnection *connection = [self getJSONConnectionForPath:@"incidents/"];
            
            if (connection) {
                self.loadIncidentsConnection = connection;
                self.loadIncidentsData = [NSMutableData data];
            }
        }
    }
}


- (NSDictionary *) allIncidentsByNumber
{
    if (! allIncidentsByNumber) {
        [self loadIncidents];
    }
    return allIncidentsByNumber;
}


@synthesize allRangersByHandle;


- (void) loadRangers {
    @synchronized(self) {
        if (! self.loadRangersConnection) {
            NSURLConnection *connection = [self getJSONConnectionForPath:@"rangers/"];

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


@synthesize allIncidentTypes;


- (void) loadIncidentTypes
{
    @synchronized(self) {
        NSURLConnection *connection = [self getJSONConnectionForPath:@"incident_types/"];
        
        if (connection) {
            self.loadIncidentTypesConnection = connection;
            self.loadIncidentTypesData = [NSMutableData data];
        }
    }
}


- (NSArray *) allIncidentTypes
{
    if (! allIncidentTypes) {
        [self loadIncidentTypes];
    }
    return allIncidentTypes;
}


@end



@implementation HTTPDataStore (NSConnectionDelegate)


- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (connection == self.loadIncidentsConnection) {
        NSLog(@"Load incidents request got response: %@", response);
        [self.loadIncidentsData setLength:0];
    }
    else if (connection == self.loadRangersConnection) {
        NSLog(@"Load Rangers request got response: %@", response);
        [self.loadRangersData setLength:0];
    }
    else if (connection == self.loadIncidentTypesConnection) {
        NSLog(@"Load incident types request got response: %@", response);
        [self.loadIncidentTypesData setLength:0];
    }
    else {
        NSLog(@"Unknown connection: %@", connection);
        NSLog(@"…got response: %@", response);
    }
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == self.loadIncidentsConnection) {
        NSLog(@"Load incidents request got data: %@", data);
        [self.loadIncidentsData appendData:data];
    }
    else if (connection == self.loadRangersConnection) {
        NSLog(@"Load Rangers request got data: %@", data);
        [self.loadRangersData appendData:data];
    }
    else if (connection == self.loadIncidentTypesConnection) {
        NSLog(@"Load incident types request got data: %@", data);
        [self.loadIncidentTypesData appendData:data];
    }
    else {
        NSLog(@"Unknown connection: %@", connection);
        NSLog(@"…got data: %@", data);
    }
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (connection == self.loadIncidentsConnection) {
        NSLog(@"Load incidents request failed: %@", error);
        self.loadIncidentsConnection = nil;
        self.loadIncidentsData = nil;
    }
    else if (connection == self.loadRangersConnection) {
        NSLog(@"Load Rangers request failed: %@", error);
        self.loadRangersConnection = nil;
        self.loadRangersData = nil;
    }
    else if (connection == self.loadIncidentTypesConnection) {
        NSLog(@"Load incident types request failed: %@", error);
        self.loadIncidentTypesConnection = nil;
        self.loadIncidentTypesData = nil;
    }
    else {
        NSLog(@"Unknown connection: %@", connection);
        NSLog(@"…got error: %@", error);
    }

    // FIXME: do something useful
}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    //        NSMutableDictionary *rangers = [[NSMutableDictionary alloc] initWithCapacity:self.rangers.count];
    //
    //        for (Ranger *ranger in self.rangers) {
    //            rangers[ranger.handle] = ranger;
    //        }
    //
    //        allRangersByHandle = rangers;

    if (connection == self.loadIncidentsConnection) {
        NSLog(@"Load incidents request completed.");
        self.loadIncidentsConnection = nil;
    }
    else if (connection == self.loadRangersConnection) {
        NSLog(@"Load Rangers request completed.");
        self.loadRangersConnection = nil;
    }
    else if (connection == self.loadIncidentTypesConnection) {
        NSLog(@"Load incident types request completed.");
        self.loadIncidentTypesConnection = nil;
    }
    else {
        NSLog(@"Unknown connection completed: %@", connection);
        return;
    }

    // FIXME: Do something with the data
}


@end
