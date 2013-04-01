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

@property (strong) NSURLConnection *loadIncidentNumbersConnection;
@property (strong) NSMutableData   *loadIncidentNumbersData;

@property (strong) NSURLConnection *loadRangersConnection;
@property (strong) NSMutableData   *loadRangersData;

@property (strong) NSURLConnection *loadIncidentTypesConnection;
@property (strong) NSMutableData   *loadIncidentTypesData;

@property (strong,readonly) NSDictionary *allIncidentsByNumber;
@property (strong,readonly) NSDictionary *allIncidentETagsByNumber;

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


@synthesize allIncidentETagsByNumber;
@synthesize allIncidentsByNumber;


- (void) loadIncidents
{
    @synchronized(self) {
        if (! self.loadIncidentNumbersConnection) {
            NSURLConnection *connection = [self getJSONConnectionForPath:@"incidents/"];
            
            if (connection) {
                self.loadIncidentNumbersConnection = connection;
                self.loadIncidentNumbersData = [NSMutableData data];
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
    if (! [response isKindOfClass:NSHTTPURLResponse.class]) {
        NSLog(@"Unexpected (non-HTTP) response: %@", response);
        NSLog(@"…for connection: %@", connection);
        return;
    }
    
    BOOL(^happyResponse)(void) = ^(void) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        BOOL result = YES;
        
        if (httpResponse.statusCode != 200) {
            NSLog(@"Unexpected response code: %ld", httpResponse.statusCode);
            result = NO;
        }
        
        if (! [httpResponse.MIMEType isEqualToString:@"application/json"]) {
            NSLog(@"Unexpected (non-JSON) MIME type: %@", httpResponse.MIMEType);
            result = NO;
        }
        
        return result;
    };
    
    if (connection == self.loadIncidentNumbersConnection) {
        //NSLog(@"Load incident numbers request got response: %@", response);
        if (happyResponse()) {
            [self.loadIncidentNumbersData setLength:0];
        }
        else {
            NSLog(@"Unable to load incident numbers data.");
            self.loadIncidentNumbersData = nil;
        }
    }
    else if (connection == self.loadRangersConnection) {
        //NSLog(@"Load Rangers request got response: %@", response);
        if (happyResponse()) {
            [self.loadRangersData setLength:0];
        }
        else {
            NSLog(@"Unable to load Rangers data.");
            self.loadRangersData = nil;
        }
    }
    else if (connection == self.loadIncidentTypesConnection) {
        //NSLog(@"Load incident types request got response: %@", response);
        if (happyResponse()) {
            [self.loadIncidentTypesData setLength:0];
        }
        else {
            NSLog(@"Unable to load incident types data.");
            self.loadIncidentTypesData = nil;
        }
    }
    else {
        NSLog(@"Unknown connection: %@", connection);
        NSLog(@"…got response: %@", response);
    }
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (connection == self.loadIncidentNumbersConnection) {
        //NSLog(@"Load incident numbers request got data: %@", data);
        [self.loadIncidentNumbersData appendData:data];
    }
    else if (connection == self.loadRangersConnection) {
        //NSLog(@"Load Rangers request got data: %@", data);
        [self.loadRangersData appendData:data];
    }
    else if (connection == self.loadIncidentTypesConnection) {
        //NSLog(@"Load incident types request got data: %@", data);
        [self.loadIncidentTypesData appendData:data];
    }
    else {
        NSLog(@"Unknown connection: %@", connection);
        NSLog(@"…got data: %@", data);
    }
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (connection == self.loadIncidentNumbersConnection) {
        NSLog(@"Load incident numbers request failed: %@", error);
        self.loadIncidentNumbersConnection = nil;
        self.loadIncidentNumbersData = nil;
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
    if (connection == self.loadIncidentNumbersConnection) {
        NSLog(@"Load incident numbers request completed.");
        self.loadIncidentNumbersConnection = nil;
        if (self.loadIncidentNumbersData) {
            NSError *error = nil;
            NSArray *jsonNumbers = [NSJSONSerialization JSONObjectWithData:self.loadIncidentNumbersData options:0 error:&error];
            
            if (! jsonNumbers || ! [jsonNumbers isKindOfClass:[NSArray class]]) {
                NSLog(@"Got JSON for incident numbers: %@", jsonNumbers);
                NSLog(@"JSON object for incident numbers must be an array.  Unable to read incident numbers from server.");
                return;
            }
            
            NSMutableDictionary *etags = [[NSMutableDictionary alloc] initWithCapacity:jsonNumbers.count];
            for (NSArray *jsonNumber in jsonNumbers) {
                if (! jsonNumber || ! [jsonNumber isKindOfClass:[NSArray class]] || [jsonNumber count] < 2) {
                    NSLog(@"Got JSON for incident number: %@", jsonNumber);
                    NSLog(@"JSON object for incident number must be an array of two items.  Unable to read incident number from server.");
                    return;
                }
                etags[jsonNumber[0]] = jsonNumber[1]; // jsonNumber is (number, etag)
            }
            allIncidentETagsByNumber = etags;
            
            self.loadIncidentNumbersData = nil;
        }
    }
    else if (connection == self.loadRangersConnection) {
        NSLog(@"Load Rangers request completed.");
        self.loadRangersConnection = nil;
        if (self.loadRangersData) {
            NSError *error = nil;
            NSArray *jsonRangers = [NSJSONSerialization JSONObjectWithData:self.loadRangersData options:0 error:&error];
            
            if (! jsonRangers || ! [jsonRangers isKindOfClass:[NSArray class]]) {
                NSLog(@"Got JSON for Rangers: %@", jsonRangers);
                NSLog(@"JSON object for Rangers must be an array.  Unable to read Rangers from server.");
                return;
            }
            
            NSMutableDictionary *rangers = [[NSMutableDictionary alloc] initWithCapacity:jsonRangers.count];
            for (NSDictionary *jsonRanger in jsonRangers) {
                Ranger *ranger = [Ranger rangerFromJSON:jsonRanger error:&error];
                if (ranger) {
                    rangers[ranger.handle] = ranger;
                }
                else {
                    NSLog(@"Got JSON for Ranger: %@", jsonRanger);
                    NSLog(@"Invalid JSON: %@", error);
                }
            }
            allRangersByHandle = rangers;
            
            self.loadRangersData = nil;
        }
    }
    else if (connection == self.loadIncidentTypesConnection) {
        NSLog(@"Load incident types request completed.");
        self.loadIncidentTypesConnection = nil;
        if (self.loadIncidentTypesData) {
            NSError *error = nil;
            NSArray *jsonIncidentTypes = [NSJSONSerialization JSONObjectWithData:self.loadIncidentTypesData options:0 error:&error];
            
            if (! jsonIncidentTypes || ! [jsonIncidentTypes isKindOfClass:[NSArray class]]) {
                NSLog(@"Got JSON for incident types: %@", jsonIncidentTypes);
                NSLog(@"JSON object for incident types must be an array.  Unable to read incident types from server.");
                return;
            }
            
            NSMutableArray *incidentTypes = [[NSMutableArray alloc] initWithCapacity:jsonIncidentTypes.count];
            for (NSString *incidentType in jsonIncidentTypes) {
                if (incidentType && [incidentType isKindOfClass:[NSString class]]) {
                    [incidentTypes addObject:incidentType];
                }
                else {
                    NSLog(@"Got JSON for incident type: %@", incidentType);
                    NSLog(@"Invalid JSON: %@", error);
                }
            }
            allIncidentTypes = incidentTypes;
            
            self.loadIncidentTypesData = nil;
        }
    }
    else {
        NSLog(@"Unknown connection completed: %@", connection);
        return;
    }
}


@end
