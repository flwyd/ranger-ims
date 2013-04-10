////
// AppDelegate.m
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
#import "FileDataStore.h"
#import "HTTPDataStore.h"
#import "HTTPServerInfo.h"
#import "DispatchQueueController.h"
#import "PreferencesController.h"
#import "AppDelegate.h"



@interface AppDelegate ()

@property (strong,nonatomic) DispatchQueueController *dispatchQueueController;
@property (strong,nonatomic) PreferencesController   *preferencesController;

@property (unsafe_unretained) IBOutlet NSMenuItem *httpStoreMenuItem;
@property (unsafe_unretained) IBOutlet NSMenuItem *fileStoreMenuItem;

@property (strong,nonatomic) NSString *dataStoreType;

@end



@implementation AppDelegate


- (id) init
{
    if (self = [super init]) {
        HTTPServerInfo *connectionInfo = [[HTTPServerInfo alloc] init];
        connectionInfo.serverName = @"localhost";
        connectionInfo.serverPort = 8080;

        self.connectionInfo = connectionInfo;
    }
    return self;
}


@synthesize dispatchQueueController;

- (DispatchQueueController *) dispatchQueueController
{
    if (! dispatchQueueController) {
        id <DataStoreProtocol> dataStore;

        if ([self.dataStoreType isEqualToString:@"File"]) {
            dataStore = [[FileDataStore alloc] init];
        }
        else if ([self.dataStoreType isEqualToString:@"HTTP"]) {
            HTTPServerInfo *connectionInfo = self.connectionInfo;
            NSString *host = [NSString stringWithFormat:@"%@:%lu",
                              connectionInfo.serverName,
                              (unsigned long)connectionInfo.serverPort];
            NSURL* url = [[NSURL alloc] initWithScheme:@"http" host:host path:@"/"];
            dataStore = [[HTTPDataStore alloc] initWithURL:url];
        }
        else {
            performAlert(@"Unknown data store type: %@", self.dataStoreType);
            return nil;
        }

        NSLog(@"Initialized data store: %@", dataStore);

        dispatchQueueController = [[DispatchQueueController alloc] initWithDataStore:dataStore appDelegate:self];
    }
    return dispatchQueueController;
}


@synthesize dataStoreType;

- (void) setDataStoreType:(NSString *)type
{
    if (! [dataStoreType isEqualToString:type]) {
        self.httpStoreMenuItem.state = NSOffState;
        self.fileStoreMenuItem.state = NSOffState;

        if ([self.dataStoreType isEqualToString:@"HTTP"]) {
            self.httpStoreMenuItem.state = NSOnState;
        }
        else if (! [self.dataStoreType isEqualToString:@"File"]) {
            self.fileStoreMenuItem.state = NSOnState;
        }

        dataStoreType = type;
        self.dispatchQueueController = nil;
    }
}


- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.dataStoreType = @"HTTP";

    [self showDispatchQueue:self];
}


- (IBAction) showDispatchQueue:(id)sender
{
    [self.dispatchQueueController showWindow:self];
}


- (IBAction) newIncident:(id)sender
{
    [self.dispatchQueueController openNewIncident:self];
}


- (IBAction) findIncident:(id)sender
{
    [self.dispatchQueueController findIncident:self];
}


@synthesize preferencesController;

- (PreferencesController *) preferencesController
{
    if (! preferencesController) {
        preferencesController = [[PreferencesController alloc] initWithAppDelegate:self];
    }
    return preferencesController;
}


- (IBAction) showPreferences:(id)sender
{
    [self.preferencesController showWindow:self];
}


////
// Debug Menu Actions
////


- (IBAction) showOpenIncidents:(id)sender
{
    if (self.dispatchQueueController) {
        performAlert(@"%@", self.dispatchQueueController.incidentControllers);
    }
}


- (IBAction) selectDataStore:(id)sender
{
    if (sender == self.httpStoreMenuItem) {
        self.dataStoreType = @"HTTP";
    }
    else if (sender == self.fileStoreMenuItem) {
        self.dataStoreType = @"File";
    }

    // This leads to crashing; need to wait for something first
    //[self showDispatchQueue:self];
}


- (IBAction) showAllRangers:(id)sender
{
    if (self.dispatchQueueController) {
        performAlert(@"%@", self.dispatchQueueController.dataStore.allRangersByHandle);
    }
}


- (IBAction) showAllIncidentTypes:(id)sender
{
    if (self.dispatchQueueController) {
        performAlert(@"%@", self.dispatchQueueController.dataStore.allIncidentTypes);
    }
}


- (IBAction) showAllIncidents:(id)sender
{
    if (self.dispatchQueueController) {
        performAlert(@"%@", self.dispatchQueueController.dataStore.incidents);
    }
}


@end
