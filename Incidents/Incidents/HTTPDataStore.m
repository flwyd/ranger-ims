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

#import "utilities.h"
#import "Ranger.h"
#import "Incident.h"
#import "HTTPConnection.h"
#import "HTTPDataStore.h"



@interface HTTPDataStore ()

@property (strong) NSURL *url;

@property (assign) BOOL serverAvailable;

@property (strong) HTTPConnection *pingConnection;
@property (strong) HTTPConnection *loadIncidentNumbersConnection;
@property (strong) HTTPConnection *loadIncidentConnection;
@property (strong) HTTPConnection *loadRangersConnection;
@property (strong) HTTPConnection *loadIncidentTypesConnection;

@property (strong) NSMutableDictionary *allIncidentsByNumber;

@property (strong) NSMutableDictionary *incidentETagsByNumber;
@property (strong) NSMutableSet        *incidentsNumbersToLoad;


@end



@implementation HTTPDataStore


- (id) initWithURL:(NSURL *)url
{
    if (self = [super init]) {
        self.url = url;

        self.allIncidentsByNumber   = [NSMutableDictionary dictionary];
        self.incidentETagsByNumber  = [NSMutableDictionary dictionary];
        self.incidentsNumbersToLoad = [NSMutableSet set];

        self.serverAvailable = NO;
    }
    return self;
}


@synthesize delegate=_delegate;


- (NSArray *) incidents
{
    if (! self.allIncidentsByNumber) {
        return @[];
    }
    else {
        return self.allIncidentsByNumber.allValues;
    }
}


- (Incident *) incidentWithNumber:(NSNumber *)number
{
    if (! self.allIncidentsByNumber) {
        return nil;
    }
    else {
        return self.allIncidentsByNumber[number];
    }
}


static int nextTemporaryNumber = -1;

- (Incident *) createNewIncident
{
    if (! self.allIncidentsByNumber) {
        return nil;
    }

    NSNumber *temporaryNumber = [NSNumber numberWithInt:nextTemporaryNumber--];
    
    while (self.allIncidentsByNumber[temporaryNumber]) {
        temporaryNumber = [NSNumber numberWithInteger:temporaryNumber.integerValue-1];
    }
    
    return [[Incident alloc] initInDataStore:self withNumber:temporaryNumber];
}


- (void) updateIncident:(Incident *)incident
{
    if (! incident || ! incident.number) {
        performAlert(@"Cannot commit invalid incident: %@", incident);
        return;
    }

    // Option: NSJSONWritingPrettyPrinted
    NSData *body;
    {
        NSError *error;
        body = [NSJSONSerialization dataWithJSONObject:[incident asJSON] options:0 error:&error];
        if (! body) {
            performAlert(@"Unable to serialize to incident %@ to JSON: %@", incident, error);
            return;
        }
    }

    NSURL *url = [[self.url URLByAppendingPathComponent:@"incidents/"] URLByAppendingPathComponent:incident.number.stringValue];

    HTTPResponseHandler onSuccess = ^(HTTPConnection *connection) {
        NSLog(@"Incident #%@ edit request completed.", incident.number);

        if (connection.responseData.length != 0) {
            NSLog(@"Incident #%@ edit request got response data (not expected): %@", incident.number, self.pingConnection.responseData);
        }

        if (connection.responseInfo.statusCode != 200) {
            performAlert(@"Incident #%@ edit request got status %ld, expected 200.", incident.number, connection.responseInfo.statusCode);
            return;
        }

        [self loadIncidentNumber:incident.number];
    };

    HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
        self.serverAvailable = NO;

        performAlert(@"Incident #%@ edit request failed: %@", incident.number, error.localizedDescription);
        NSLog(@"Unable to connect to server: %@", error);
    };

    [HTTPConnection JSONPostConnectionWithURL:url
                                         body:body
                              responseHandler:onSuccess
                                 errorHandler:onError];
}


- (BOOL) serverAvailable {
    return _serverAvailable;
}
@synthesize serverAvailable=_serverAvailable;


- (void) setServerAvailable:(BOOL)available
{
    if (available != _serverAvailable) {
        _serverAvailable = available;

        if (available) {
            NSLog(@"Server connection is available.");
            [self loadIncidentTypes];
            [self loadRangers];
            [self loadIncidents];
        }
        else {
            NSLog(@"Server connection is no longer available.");
        }
    }
}


- (void) pingServer
{
    @synchronized(self) {
        if (! self.pingConnection.active) {
            NSURL *url = [self.url URLByAppendingPathComponent:@"ping/"];

            HTTPResponseHandler onSuccess = ^(HTTPConnection *connection) {
                if (connection != self.pingConnection) {
                    performAlert(@"Ping response from unknown connection!?");
                    return;
                }

                //NSLog(@"Ping request completed.");

                NSError *error = nil;
                NSString *jsonACK = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&error];

                if (jsonACK) {
                    if ([jsonACK isEqualToString:@"ack"]) {
                        self.serverAvailable = YES;
                    }
                    else {
                        performAlert(@"Unexpected response to ping: %@", jsonACK);
                        self.serverAvailable = NO;
                    }
                }
                else {
                    performAlert(@"Unable to deserialize ping response: %@", error);
                }
            };

            HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                if (connection != self.pingConnection) {
                    performAlert(@"Ping error from unknown connection!?");
                    return;
                }

                self.serverAvailable = NO;

                performAlert(@"Unable to connect to server: %@", error.localizedDescription);
                NSLog(@"Unable to connect to server: %@", error);
            };

            self.pingConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                             responseHandler:onSuccess
                                                                errorHandler:onError];
        }
    }
}


- (BOOL) load
{
    [self pingServer];

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


- (void) loadIncidents
{
    @synchronized(self) {
        if (! self.loadIncidentNumbersConnection.active) {
            NSURL *url = [self.url URLByAppendingPathComponent:@"incidents/"];

            HTTPResponseHandler onSuccess = ^(HTTPConnection *connection) {
                if (connection != self.loadIncidentNumbersConnection) {
                    performAlert(@"Load incident numbers response from unknown connection!?");
                    return;
                }

                //NSLog(@"Load incident numbers request completed.");

                NSError *error = nil;
                NSArray *jsonNumbers = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                       options:0
                                                                         error:&error];

                if (! jsonNumbers || ! [jsonNumbers isKindOfClass:[NSArray class]]) {
                    NSLog(@"JSON object for incident numbers must be an array: %@", jsonNumbers);
                    performAlert(@"Unable to read incident numbers from server.");
                    return;
                }

                for (NSArray *jsonNumber in jsonNumbers) {
                    if (! jsonNumber || ! [jsonNumber isKindOfClass:[NSArray class]] || [jsonNumber count] < 2) {
                        NSLog(@"JSON object for incident number must be an array of two items: %@", jsonNumber);
                        performAlert(@"Unable to read incident number from server.");
                        return;
                    }
                    // jsonNumber is (number, etag)
                    if (! [jsonNumber[1] isEqualToString: self.incidentETagsByNumber[jsonNumber[0]]]) {
                        [self.incidentsNumbersToLoad addObject:jsonNumber[0]];
                    }
                }

                // FIXME: Run through self.allIncidentsByNumber and verify that all are in self.incidentsNumbersToLoad.
                //    …if not, that's an error of some sort, since we don't remove incidents.
                    
                [self loadQueuedIncidents];
            };

            HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                if (connection != self.loadIncidentNumbersConnection) {
                    performAlert(@"Load incident numbers error from unknown connection!?");
                    return;
                }

                performAlert(@"Load incident numbers request failed: %@", error);
            };

            self.loadIncidentNumbersConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                                            responseHandler:onSuccess
                                                                               errorHandler:onError];
        }
    }
}


- (void) loadIncidentNumber:(NSNumber *)number {
    @synchronized(self) {
        [self.incidentsNumbersToLoad addObject:number];
        [self loadQueuedIncidents];
    }
}

- (void) loadQueuedIncidents {
    @synchronized(self) {
        if (self.serverAvailable) {
            if (self.loadIncidentConnection.active) {
                //
                // This shouldn't happen given how this code is wired up.
                // Logging here in case that cases accidentally, in case it's a performance oopsie.
                //
                NSLog(@"Already loading incidents... we shouldn't be here.");
            }
            else {
                NSString *path = nil;
                for (NSNumber *number in self.incidentsNumbersToLoad) {
                    //NSLog(@"Loading queued incident: %@", number);

                    path = [NSString stringWithFormat:@"incidents/%@", number];
                    NSURL *url = [self.url URLByAppendingPathComponent:path];

                    HTTPResponseHandler onSuccess = ^(HTTPConnection *connection) {
                        if (connection != self.loadIncidentConnection) {
                            performAlert(@"Load incident #%@ request from unknown connection!?", number);
                            return;
                        }

                        //NSLog(@"Load incident request completed.");

                        NSError *error = nil;
                        NSDictionary *jsonIncident = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                                     options:0
                                                                                       error:&error];
                        Incident *incident = [Incident incidentInDataStore:self fromJSON:jsonIncident error:&error];

                        if (incident) {
                            if ([incident.number isEqualToNumber:number]) {
                                // FIXME: Acquire from connection.response.headers
                                NSString *loadIncidentETag = @"*** WE SHOULD SET THIS HERE ***";

                                self.allIncidentsByNumber[number] = incident;
                                self.incidentETagsByNumber[number] = loadIncidentETag;

                                [self.delegate dataStore:self didUpdateIncident:incident];
                                NSLog(@"Loaded incident #%@.", number);
                            }
                            else {
                                performAlert(@"Got incident #%@ when I asked for incident #%@.  I'm confused.",
                                             incident.number, number);
                            }
                        }
                        else {
                            performAlert(@"Unable to deserialize incident #%@: %@", number, error);
                        }

                        // De-queue the incident
                        [self.incidentsNumbersToLoad removeObject:number];

                        [self loadQueuedIncidents];
                    };

                    HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                        if (connection != self.loadIncidentConnection) {
                            performAlert(@"Load incident #%@ error from unknown connection!?", number);
                            return;
                        }

                        performAlert(@"Load incident #%@ request failed: %@", number, error);
                    };

                    self.loadIncidentConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                                             responseHandler:onSuccess
                                                                                errorHandler:onError];

                    [self.delegate dataStoreWillUpdateIncidents:self];

                    break;
                }
                if (! path) {
                    NSLog(@"Done loading queued incidents.");
                }
            }
        }
    }
}


- (void) loadRangers {
    @synchronized(self) {
        if (self.serverAvailable) {
            if (! self.loadRangersConnection.active) {
                NSURL *url = [self.url URLByAppendingPathComponent:@"rangers/"];

                HTTPResponseHandler onSuccess = ^(HTTPConnection *connection) {
                    if (connection != self.loadRangersConnection) {
                        performAlert(@"Load Rangers response from unknown connection!?");
                        return;
                    }

                    //NSLog(@"Load Rangers request completed.");

                    NSError *error = nil;
                    NSArray *jsonRangers = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                           options:0
                                                                             error:&error];

                    if (! jsonRangers || ! [jsonRangers isKindOfClass:[NSArray class]]) {
                        NSLog(@"JSON object for Rangers must be an array: %@", jsonRangers);
                        return;
                    }

                    NSMutableDictionary *rangers = [[NSMutableDictionary alloc] initWithCapacity:jsonRangers.count];
                    for (NSDictionary *jsonRanger in jsonRangers) {
                        Ranger *ranger = [Ranger rangerFromJSON:jsonRanger error:&error];
                        if (ranger) {
                            rangers[ranger.handle] = ranger;
                        }
                        else {
                            NSLog(@"Invalid JSON: %@", jsonRanger);
                            performAlert(@"Unable to read Rangers from server: %@", error);
                        }
                    }
                    _allRangersByHandle = rangers;
                };

                HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                    if (connection != self.loadRangersConnection) {
                        performAlert(@"Load Rangers error from unknown connection!?");
                        return;
                    }

                    performAlert(@"Load Rangers request failed: %@", error);
                };

                self.loadRangersConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                                        responseHandler:onSuccess
                                                                           errorHandler:onError];
            }
        }
    }
}


- (NSDictionary *) allRangersByHandle
{
    if (! _allRangersByHandle) {
        [self loadRangers];
    }
    return _allRangersByHandle;
}
@synthesize allRangersByHandle=_allRangersByHandle;


- (void) loadIncidentTypes
{
    @synchronized(self) {
        if (self.serverAvailable) {
            if (! self.loadIncidentTypesConnection.active) {
                NSURL *url = [self.url URLByAppendingPathComponent:@"incident_types/"];

                HTTPResponseHandler onSuccess = ^(HTTPConnection *connection) {
                    if (connection != self.loadIncidentTypesConnection) {
                        performAlert(@"Load Rangers response from unknown connection!?");
                        return;
                    }

                    //NSLog(@"Load incident types request completed.");

                    NSError *error = nil;
                    NSArray *jsonIncidentTypes = [NSJSONSerialization JSONObjectWithData:connection.responseData
                                                                                 options:0
                                                                                   error:&error];

                    if (! jsonIncidentTypes || ! [jsonIncidentTypes isKindOfClass:[NSArray class]]) {
                        NSLog(@"JSON object for incident types must be an array: %@", jsonIncidentTypes);
                        performAlert(@"Unable to read incident types from server.");
                        return;
                    }

                    NSMutableArray *incidentTypes = [[NSMutableArray alloc] initWithCapacity:jsonIncidentTypes.count];
                    for (NSString *incidentType in jsonIncidentTypes) {
                        if (incidentType && [incidentType isKindOfClass:[NSString class]]) {
                            [incidentTypes addObject:incidentType];
                        }
                        else {
                            NSLog(@"Invalid JSON: %@", incidentType);
                            performAlert(@"Unable to read incident types from server: %@", error);
                        }
                    }
                    _allIncidentTypes = incidentTypes;
                };

                HTTPErrorHandler onError = ^(HTTPConnection *connection, NSError *error) {
                    if (connection != self.loadIncidentTypesConnection) {
                        performAlert(@"Load Rangers error from unknown connection!?");
                        return;
                    }

                    performAlert(@"Load incident types request failed: %@", error);
                };

                self.loadIncidentTypesConnection = [HTTPConnection JSONQueryConnectionWithURL:url
                                                                              responseHandler:onSuccess
                                                                                 errorHandler:onError];
            }
        }
    }
}


- (NSArray *) allIncidentTypes
{
    if (! _allIncidentTypes) {
        [self loadIncidentTypes];
    }
    return _allIncidentTypes;
}
@synthesize allIncidentTypes=_allIncidentTypes;


@end
