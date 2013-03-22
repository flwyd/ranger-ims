////
// DispatchQueueController.m
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

#import "FileDataStore.h"
#import "HTTPDataStore.h"
#import "HTTPConnectionInfo.h"
#import "Location.h"
#import "ReportEntry.h"
#import "Incident.h"
#import "TableView.h"
#import "AppDelegate.h"
#import "IncidentController.h"
#import "DispatchQueueController.h"



NSString *formattedDateTimeLong(NSDate *date);
NSString *formattedDateTimeShort(NSDate *date);



@interface DispatchQueueController ()
<
    NSWindowDelegate,
    NSTableViewDataSource,
    NSTableViewDelegate,
    TableViewDelegate,
    DataStoreDelegate
>

@property (unsafe_unretained) AppDelegate *appDelegate;

@property (unsafe_unretained) IBOutlet NSSearchField       *searchField;
@property (unsafe_unretained) IBOutlet NSTableView         *dispatchTable;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *loadingIndicator;
@property (unsafe_unretained) IBOutlet NSButton            *showClosed;
@property (unsafe_unretained) IBOutlet NSTextField         *updatedLabel;

@property (strong) NSMutableDictionary *incidentControllers;

@property (strong,nonatomic) NSArray *sortedIncidents;
@property (strong,nonatomic) NSArray *sortedOpenIncidents;

@end



@implementation DispatchQueueController


- (id) initWithAppDelegate:(AppDelegate *)appDelegate
{
    if (self = [super initWithWindowNibName:@"DispatchQueueController"]) {
        self.appDelegate = appDelegate;
        self.incidentControllers = [NSMutableDictionary dictionary];
        self.sortedIncidents = nil;
        self.sortedOpenIncidents = nil;
    }
    return self;
}


- (void) windowDidLoad
{
    [super windowDidLoad];

    NSTableView *dispatchTable = self.dispatchTable;
    dispatchTable.doubleAction = @selector(openClickedIncident);
    
    [self load];
}


- (void) load
{
    NSLog(@"Updating dispatch queue...");
    
    // Spin the progress indicator...
    NSProgressIndicator *loadingIndicator = self.loadingIndicator;
    if (loadingIndicator) {
        [loadingIndicator startAnimation:self];
    }
    else {
        NSLog(@"loadingIndicator is not connected.");
    }

    // Load queue data from server
    if (! self.dataStore) {
        id <DataStoreProtocol> dataStore;

#if 0
        dataStore = [[FileDataStore alloc] init];
#else
        HTTPConnectionInfo *connectionInfo = self.appDelegate.connectionInfo;
        NSString *host = [NSString stringWithFormat:@"%@:%lu",
                          connectionInfo.serverName,
                          (unsigned long)connectionInfo.serverPort];
        NSURL* url = [[NSURL alloc] initWithScheme:@"http" host:host path:@"/"];
        dataStore = [[HTTPDataStore alloc] initWithURL:url];
#endif

        dataStore.delegate = self;
        self.dataStore = dataStore;

        [dataStore load];
    }
    
    // Populate dispatch table
    [self loadTable];

    // Display the update time
    NSTextField *updatedLabel = self.updatedLabel;
    if (updatedLabel) {
        updatedLabel.stringValue = [NSString stringWithFormat: @"Last updated: %@", formattedDateTimeLong([NSDate date])];
    }
    else {
        NSLog(@"updatedLabel is not connected.");
    }

    // Stop the progress indicator.
    if (loadingIndicator) {
        [loadingIndicator stopAnimation:self];
    }
}


- (void) loadTable
{
    self.sortedIncidents = nil;
    self.sortedOpenIncidents = nil;

    NSTableView *dispatchTable = self.dispatchTable;
    if (dispatchTable) {
        //[dispatchTable noteNumberOfRowsChanged];
        [dispatchTable reloadData];
    }
    else {
        NSLog(@"dispatchTable is not connected.");
    }
}


- (Incident *) selectedIncident {
    NSTableView *dispatchTable = self.dispatchTable;
    NSInteger rowIndex = dispatchTable.selectedRow;

    return [self incidentForTableRow:rowIndex];
}


- (void) openSelectedIncident:(id)sender
{
    [self openIncident:[self selectedIncident]];
}


- (void) openClickedIncident
{
    NSTableView *dispatchTable = self.dispatchTable;
    NSInteger rowIndex = dispatchTable.clickedRow;
    Incident *incident = [self incidentForTableRow:rowIndex];

    [self openIncident:incident];
}


- (void) openNewIncident:(id)sender
{
    Incident *incident = [self.dataStore createNewIncident];

    if (! incident) {
        NSLog(@"Unable to create new incident?");
        return;
    }

    [self openIncident:incident];
}


- (void) openIncident:(Incident *)incident
{
    if (! incident) {
        NSLog(@"Unable to open nil incident.");
        return;
    }

    // See if we already have an open controller for this incident
    IncidentController *incidentController = self.incidentControllers[incident.number];

    // …or create one if necessary.
    if (! incidentController) {
        incidentController = [[IncidentController alloc] initWithDispatchQueueController:self
                                                                                incident:incident];

        self.incidentControllers[incident.number] = incidentController;
    }

    [incidentController showWindow:self];
    [incidentController.window makeKeyAndOrderFront:self];
}


- (NSArray *) sortedIncidents {
    if (! _sortedIncidents) {
        // FIXME: If the table has no sort descriptors,
        // default to something useful.

        NSTableView *dispatchTable = self.dispatchTable;
        _sortedIncidents =
            [self.dataStore.incidents sortedArrayUsingDescriptors:dispatchTable.sortDescriptors];
    }

    if (! _sortedOpenIncidents) {
        BOOL(^openFilter)(Incident *, NSDictionary *) = ^(Incident *incident, NSDictionary *bindings) {
            if (incident.closed) { return NO ; }
            else                 { return YES; }
        };
        NSPredicate *openPredicate = [NSPredicate predicateWithBlock:openFilter];
        _sortedOpenIncidents = [_sortedIncidents filteredArrayUsingPredicate:openPredicate];
    }

    NSArray *result;
    NSButton *showClosed = self.showClosed;
    if (showClosed.state == NSOffState) {
        result = _sortedOpenIncidents;
    }
    else {
        result = _sortedIncidents;
    }

    NSSearchField *searchField = self.searchField;
    NSSearchFieldCell *searchFieldCell = searchField.cell;
    NSString *searchText = searchFieldCell.stringValue;

    if (searchText.length) {
        BOOL(^searchFilter)(Incident *, NSDictionary *) = ^(Incident *incident, NSDictionary *bindings) {
            //
            // Set up an array of sources that we will search in
            //
            NSMutableArray *sources = [NSMutableArray array];

            if (incident.summary         ) [sources addObject:incident.summary         ];
            if (incident.location.name   ) [sources addObject:incident.location.name   ];
            if (incident.location.address) [sources addObject:incident.location.address];

            for (NSArray *array in @[
                incident.rangersByHandle.allKeys,
                incident.types,
            ]) {
                for (NSString *rangerHandle in array) {
                    [sources addObject:rangerHandle];
                }
            }

            for (ReportEntry *entry in incident.reportEntries) {
                [sources addObject:entry.text];
            }

            //
            // Tokeninze the seach field text
            //
            NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
            NSArray *tokens = [searchText componentsSeparatedByCharactersInSet:whiteSpace];

            //
            // Search sources for each token
            //
            for (NSString *token in tokens) {
                if (token.length == 0) {
                    continue;
                }

                BOOL found = NO;

                for (NSString *source in sources) {
                    if (source) {
                        NSRange range = [source rangeOfString:token options:NSCaseInsensitiveSearch];
                        if (range.location != NSNotFound && range.length != 0) {
                            found = YES;
                        }
                    }
                }

                if (! found) {
                    return NO;
                }
            }
            return YES;
        };
        NSPredicate *searchPredicate = [NSPredicate predicateWithBlock:searchFilter];
        result = [result filteredArrayUsingPredicate:searchPredicate];
    }

    return result;
}


- (Incident *) incidentForTableRow:(NSInteger)rowIndex {
    NSArray *incidents = self.sortedIncidents;

    if (rowIndex < 0) {
        return nil;
    }

    if (rowIndex >= (NSInteger)incidents.count) {
        NSLog(@"incidentForTableRow: got out of bounds rowIndex: %ld",
              rowIndex);
        return nil;
    }
    
    return incidents[(NSUInteger)rowIndex];
}


- (void) commitIncident:(Incident *)incident
{
    NSLog(@"Committing incident: %@", incident);

    NSNumber *oldNumber = incident.number;
    [self.dataStore commitIncident:incident];
    NSNumber *newNumber = incident.number;

    [self loadTable];

    IncidentController *controller = self.incidentControllers[oldNumber];
    if (controller) {
        if (! [newNumber isEqualToNumber:oldNumber]) {
            [self.incidentControllers removeObjectForKey:oldNumber];
            self.incidentControllers[newNumber] = controller;
        }
        [controller reloadIncident];
    }
}


- (IBAction) loadTable:(id)sender
{
    [self loadTable];
}


- (void) findIncident:(id)sender
{
    [self.window makeKeyAndOrderFront:self];
    [self.window makeFirstResponder:self.searchField];
}


@end



@implementation DispatchQueueController (NSTableViewDataSource)


- (NSUInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.sortedIncidents.count;
}


- (id)            tableView:(NSTableView *)tableView
  objectValueForTableColumn:(NSTableColumn *)column
                        row:(NSInteger)rowIndex
{
    Incident *incident = [self incidentForTableRow:rowIndex];

    if (! incident) {
        NSLog(@"Invalid table row: %ld", rowIndex);
        return nil;
    }
    
    NSString *identifier = [column identifier];

    if ([identifier isEqualToString:@"number"]) {
        return incident.number;
    }
    else if ([identifier isEqualToString:@"priority"]) {
        return incident.priority;
    }
    else if ([identifier isEqualToString:@"created"]) {
        return formattedDateTimeShort(incident.created);
    }
    else if ([identifier isEqualToString:@"dispatched"]) {
        return formattedDateTimeShort(incident.dispatched);
    }
    else if ([identifier isEqualToString:@"onScene"]) {
        return formattedDateTimeShort(incident.onScene);
    }
    else if ([identifier isEqualToString:@"closed"]) {
        return formattedDateTimeShort(incident.closed);
    }
    else if ([identifier isEqualToString:@"rangers"]) {
        return [self joinedStrings:incident.rangersByHandle.allKeys withSeparator:@", "];
    }
    else if ([identifier isEqualToString:@"locationName"]) {
        return incident.location.name;
    }
    else if ([identifier isEqualToString:@"locationAddress"]) {
        return incident.location.address;
    }
    else if ([identifier isEqualToString:@"types"]) {
        return [self joinedStrings:incident.types withSeparator:@", "];
    }
    else if ([identifier isEqualToString:@"summary"]) {
        return incident.summaryFromReport;
    }

    NSLog(@"Unknown column identifier: %@", identifier);
    return nil;
}


- (NSString*) joinedStrings:(NSArray*)strings withSeparator:(NSString*)separator
{
//    return [strings componentsJoinedByString:separator];

    NSString *result = nil;
    for (NSString *string in strings) {
        if (result) {
            result = [result stringByAppendingString:separator];
        }
        else {
            result = @"";
        }
        result = [result stringByAppendingString:string];
    }
    return result;
}


@end



@implementation DispatchQueueController (NSTableViewDelegate)


- (void)         tableView:(NSTableView *)tableView
  sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [self loadTable];
}


@end


@implementation DispatchQueueController (TableViewDelegate)


- (void) deleteFromTableView:(NSTableView *)tableView
{
}


- (void) openFromTableView:(NSTableView *)tableView
{
    [self openIncident:[self selectedIncident]];
}


@end



static NSDateFormatter *longDayTimeFormatter  = nil;
static NSDateFormatter *shortDayTimeFormatter = nil;

NSString *formattedDateTimeLong(NSDate *date)
{
    if (! longDayTimeFormatter) {
        longDayTimeFormatter = [[NSDateFormatter alloc] init];
        [longDayTimeFormatter setDateFormat:@"EEEE, MMMM d, yyyy HH:mm:ss zzz"];
    }
    return [longDayTimeFormatter stringFromDate:date];
}


NSString *formattedDateTimeShort(NSDate *date)
{
    if (! shortDayTimeFormatter) {
        shortDayTimeFormatter = [[NSDateFormatter alloc] init];
        [shortDayTimeFormatter setDateFormat:@"EEEEE.HH:mm"];
    }
    return [shortDayTimeFormatter stringFromDate:date];
}
