////
// IncidentController.m
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

#import <Block.h>
#import "utilities.h"
#import "ReportEntry.h"
#import "Incident.h"
#import "Location.h"
#import "Ranger.h"
#import "TableView.h"
#import "DispatchQueueController.h"
#import "IncidentController.h"



static NSDateFormatter *entryDateFormatter = nil;



@interface IncidentController ()
<
    NSWindowDelegate,
    NSTableViewDataSource,
    NSTableViewDelegate,
    NSTextFieldDelegate,
    TableViewDelegate
>

@property (strong) DispatchQueueController *dispatchQueueController;

@property (unsafe_unretained) IBOutlet NSTextField   *numberField;
@property (unsafe_unretained) IBOutlet NSPopUpButton *statePopUp;
@property (unsafe_unretained) IBOutlet NSPopUpButton *priorityPopUp;
@property (unsafe_unretained) IBOutlet NSTextField   *summaryField;
@property (unsafe_unretained) IBOutlet NSTableView   *rangersTable;
@property (unsafe_unretained) IBOutlet NSTextField   *rangerToAddField;
@property (unsafe_unretained) IBOutlet NSTableView   *typesTable;
@property (unsafe_unretained) IBOutlet NSTextField   *typeToAddField;
@property (unsafe_unretained) IBOutlet NSTextField   *locationNameField;
@property (unsafe_unretained) IBOutlet NSTextField   *locationAddressField;
@property (assign)            IBOutlet NSTextView    *reportEntriesView;
@property (assign)            IBOutlet NSTextView    *reportEntryToAddView;

@property (assign) BOOL stateDidChange;
@property (assign) BOOL priorityDidChange;
@property (assign) BOOL summaryDidChange;
@property (assign) BOOL rangersDidChange;
@property (assign) BOOL typesDidChange;
@property (assign) BOOL locationDidChange;
@property (assign) BOOL reportDidChange;

@property (assign) BOOL amCompleting;
@property (assign) BOOL amBackspacing;

@end



@implementation IncidentController


- (id) initWithDispatchQueueController:(DispatchQueueController *)dispatchQueueController
                              incident:(Incident *)incident
{
    if (! incident) {
        [NSException raise:NSInvalidArgumentException format:@"incident may not be nil"];
    }

    if (self = [super initWithWindowNibName:@"IncidentController"]) {
        self.dispatchQueueController = dispatchQueueController;
        self.incident = incident;
    }
    return self;
}


- (void) dealloc
{
    self.reportEntriesView    = nil;
    self.reportEntryToAddView = nil;
}


- (void) windowDidLoad
{
    [super windowDidLoad];

    [self.reportEntryToAddView setFieldEditor:YES];

    [self reloadIncident];
}


- (void) reloadIncident
{
    if (! self.incident.number.integerValue < 0) {
        self.incident = [[self.dispatchQueueController.dataStore incidentWithNumber:self.incident.number] copy];

        self.stateDidChange    = NO;
        self.priorityDidChange = NO;
        self.summaryDidChange  = NO;
        self.rangersDidChange  = NO;
        self.typesDidChange    = NO;
        self.locationDidChange = NO;
    }
    self.window.documentEdited = NO;

    [self updateView];
}


- (void) updateView
{
    Incident *incident = self.incident;

    NSLog(@"Displaying: %@", incident);

    NSString *summaryFromReport = incident.summaryFromReport;

    NSString *numberToDisplay;
    if (incident.number.integerValue < 0) {
        numberToDisplay = @"(new)";
    } else {
        numberToDisplay = incident.number.stringValue;
    }

    if (self.window) {
        self.window.title = [NSString stringWithFormat:
                                @"%@: %@",
                                numberToDisplay,
                                summaryFromReport];
    }
    else {
        performAlert(@"No window?");
    }

    NSTextField *numberField = self.numberField;
    if (numberField) {
        numberField.stringValue = numberToDisplay;
    }
    else {
        performAlert(@"No numberField?");
    }

    NSPopUpButton *statePopUp = self.statePopUp;
    if (statePopUp) {
        NSInteger stateTag;

        if      (incident.closed    ) { stateTag = 4; }
        else if (incident.onScene   ) { stateTag = 3; }
        else if (incident.dispatched) { stateTag = 2; }
        else if (incident.created   ) { stateTag = 1; }
        else {
            performAlert(@"Unknown incident state.");
            stateTag = 0;
        }
        [statePopUp selectItemWithTag:stateTag];

        void (^enableState)(NSInteger, BOOL) = ^(NSInteger tag, BOOL enabled) {
            [[statePopUp itemAtIndex: [statePopUp indexOfItemWithTag:tag]] setEnabled:enabled];
        };

        void (^enableStates)(BOOL, BOOL, BOOL, BOOL) = ^(BOOL one, BOOL two, BOOL three, BOOL four) {
            enableState(1, one);
            enableState(2, two);
            enableState(3, three);
            enableState(4, four);
        };

        if      (stateTag == 1) { enableStates(YES, YES, YES, YES); }
        else if (stateTag == 2) { enableStates(YES, YES, YES, YES); }
        else if (stateTag == 3) { enableStates(NO , YES, YES, YES); }
        else if (stateTag == 4) { enableStates(YES, NO , NO , YES); }
    }
    else {
        performAlert(@"No statePopUp?");
    }

    NSPopUpButton *priorityPopUp = self.priorityPopUp;
    if (priorityPopUp) {
        [priorityPopUp selectItemWithTag:incident.priority.integerValue];
    }
    else {
        performAlert(@"No priorityPopUp?");
    }

    NSTextField *summaryField = self.summaryField;
    if (summaryField) {
        if (incident.summary && incident.summary.length) {
            summaryField.stringValue = incident.summary;
        }
        else {
            if (! [summaryField.stringValue isEqualToString:@""]) {
                summaryField.stringValue = @"";
            }
            if (! [[summaryField.cell placeholderString] isEqualToString:summaryFromReport]) {
                [summaryField.cell setPlaceholderString:summaryFromReport];
            }
        }
    }
    else {
        performAlert(@"No summaryField?");
    }

    NSTableView *rangersTable = self.rangersTable;
    if (rangersTable) {
        [rangersTable reloadData];
    }
    else {
        performAlert(@"No rangersTable?");
    }

    NSTableView *typesTable = self.typesTable;
    if (typesTable) {
        [typesTable reloadData];
    }
    else {
        performAlert(@"No typesTable?");
    }

    NSTextField *locationNameField = self.locationNameField;
    if (locationNameField) {
        locationNameField.stringValue = incident.location.name ? incident.location.name : @"";
    }
    else {
        performAlert(@"No locationNameField?");
    }

    NSTextField *locationAddressField = self.locationAddressField;
    if (locationAddressField) {
        locationAddressField.stringValue = incident.location.address ? incident.location.address : @"";
    }
    else {
        performAlert(@"No locationAddressField?");
    }

    NSTextView *reportEntriesView = self.reportEntriesView;
    if (reportEntriesView) {
        [reportEntriesView.textStorage
            setAttributedString:[self formattedReport]];

        NSRange end = NSMakeRange([[reportEntriesView string] length],0);
        [reportEntriesView scrollRangeToVisible:end];
    }
    else {
        performAlert(@"No reportEntriesView?");
    }
}


- (void) commitIncident
{
    if (self.incident.number.integerValue < 0) {
        // New incident

        performAlert(@"commitIncident: unimplemented for new incidents.");
    }
    else {
        // Edited incident
        BOOL edited = NO;

        NSArray  *rangers    = nil; if (self.rangersDidChange  ) { edited = YES; rangers    = self.incident.rangersByHandle.allValues; }
        NSArray  *types      = nil; if (self.typesDidChange    ) { edited = YES; types      = self.incident.types;                     }
        NSString *summary    = nil; if (self.summaryDidChange  ) { edited = YES; summary    = self.incident.summary;                   }
        NSDate   *created    = nil; if (self.stateDidChange    ) { edited = YES; created    = self.incident.created;                   }
        NSDate   *dispatched = nil; if (self.stateDidChange    ) { edited = YES; dispatched = self.incident.dispatched;                }
        NSDate   *onScene    = nil; if (self.stateDidChange    ) { edited = YES; onScene    = self.incident.onScene;                   }
        NSDate   *closed     = nil; if (self.stateDidChange    ) { edited = YES; closed     = self.incident.closed;                    }
        NSNumber *priority   = nil; if (self.priorityDidChange ) { edited = YES; priority   = self.incident.priority;                  }

        Location *location = nil;
        if (self.locationDidChange) {
            edited = YES;
            location = [[Location alloc] initWithName:self.incident.location.name
                                              address:self.incident.location.address];
        }

        NSArray *reportEntries = nil;
        if (self.reportDidChange) {
            edited = YES;
            reportEntries = @[self.incident.reportEntries.lastObject];
        }

        if (edited) {
            Incident *incidentToCommit = [[Incident alloc] initInDataStore:self.incident.dataStore
                                                                withNumber:self.incident.number
                                                                   rangers:rangers
                                                                  location:location
                                                                     types:types
                                                                   summary:summary
                                                             reportEntries:reportEntries
                                                                   created:created
                                                                dispatched:dispatched
                                                                   onScene:onScene
                                                                    closed:closed
                                                                  priority:priority];

            [self.dispatchQueueController.dataStore updateIncident:incidentToCommit];
        }

        //[self reloadIncident];
    }
}


- (NSAttributedString *) formattedReport
{
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@""];

    for (ReportEntry *entry in self.incident.reportEntries) {
        NSAttributedString *text = [self formattedReportEntry:entry];
        [result appendAttributedString:text];
    }

    return result;
}


- (NSAttributedString *) formattedReportEntry:(ReportEntry *)entry
{
    NSAttributedString *newline = [[NSAttributedString alloc] initWithString:@"\n"];
    NSMutableAttributedString *result = [[NSMutableAttributedString alloc] initWithString:@""];

    // Prepend a date stamp.
    NSAttributedString *dateStamp = [self dateStampForReportEntry:entry];

    [result appendAttributedString:dateStamp];

    // Append the entry text.
    NSAttributedString *text = [self textForReportEntry:entry];

    [result appendAttributedString:text];
    [result appendAttributedString:newline];

    // Add (another) newline if text didn't end in newline
    NSUInteger length = [text length];
    unichar lastCharacter = [[text string] characterAtIndex:length-1];

    if (lastCharacter != '\n') {
        [result appendAttributedString:newline];
    }

    return result;
}


- (NSAttributedString *) dateStampForReportEntry:(ReportEntry *)entry
{
    if (!entryDateFormatter) {
        entryDateFormatter = [[NSDateFormatter alloc] init];
        [entryDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    }

    NSString *dateFormatted = [entryDateFormatter stringFromDate:entry.createdDate];
    NSString *dateStamp = [NSString stringWithFormat:@"%@, %@:\n", dateFormatted, @"<Name of Operator>"];
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont fontWithName:@"Menlo-Bold" size:0],
    };

    return [[NSAttributedString alloc] initWithString:dateStamp
                                           attributes:attributes];
}


- (NSAttributedString *) textForReportEntry:(ReportEntry *)entry
{
    NSDictionary *attributes = @{
        NSFontAttributeName: [NSFont fontWithName:@"Menlo" size:0],
    };
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:entry.text
                                                               attributes:attributes];

    return text;
}


- (IBAction) save:(id)sender
{
    // Flush the text fields
    [self editSummary:self];
    //[self editState:self];
    //[self editPriority:self];
    [self editLocationName:self];
    [self editLocationAddress:self];

    // Get any added report text
    NSCharacterSet *whiteSpace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSTextView *reportEntryToAddView = self.reportEntryToAddView;
    NSString* reportTextToAdd = reportEntryToAddView.textStorage.string;
    reportTextToAdd = [reportTextToAdd stringByTrimmingCharactersInSet:whiteSpace];

    // Add a report entry
    if (reportTextToAdd.length > 0) {
        ReportEntry *entry = [[ReportEntry alloc] initWithText:reportTextToAdd];
        [self.incident addEntryToReport:entry];

        self.reportDidChange = YES;
        self.window.documentEdited = YES;
    }

    // Commit the change
    [self commitIncident];

    // Clear the report entry view
    reportEntryToAddView.textStorage.attributedString = [[NSAttributedString alloc] initWithString:@""];
}


- (IBAction) editSummary:(id)sender {
    Incident *incident = self.incident;
    NSTextField *summaryField = self.summaryField;
    NSString *summary = summaryField.stringValue;

    if (! [summary isEqualToString:incident.summary ? incident.summary : @""]) {
        incident.summary = summary;
        self.summaryDidChange = YES;
        self.window.documentEdited = YES;
    }
}


- (IBAction) editState:(id)sender {
    Incident *incident = self.incident;
    NSPopUpButton *statePopUp = self.statePopUp;
    NSInteger stateTag = statePopUp.selectedItem.tag;

    if (stateTag == 1) {
        incident.dispatched = nil;
        incident.onScene    = nil;
        incident.closed     = nil;
    }
    else if (stateTag == 2) {
        if (! incident.dispatched) { incident.dispatched = [NSDate date]; }

        incident.onScene = nil;
        incident.closed  = nil;
    }
    else if (stateTag == 3) {
        if (! incident.dispatched) { incident.dispatched = [NSDate date]; }
        if (! incident.onScene   ) { incident.onScene    = [NSDate date]; }

        incident.closed  = nil;
    }
    else if (stateTag == 4) {
        if (! incident.dispatched) { incident.dispatched = [NSDate date]; }
        if (! incident.onScene   ) { incident.onScene    = [NSDate date]; }
        if (! incident.closed    ) { incident.closed     = [NSDate date]; }
    }
    else {
        performAlert(@"Unknown state tag: %ld", stateTag);
        return;
    }

    self.stateDidChange = YES;
    self.window.documentEdited = YES;
}


- (IBAction) editPriority:(id)sender {
    Incident *incident = self.incident;
    NSPopUpButton *priorityPopUp = self.priorityPopUp;
    NSNumber *priority = [NSNumber numberWithInteger:priorityPopUp.selectedItem.tag];

    if (! [priority isEqualToNumber:incident.priority]) {
        NSLog(@"Priority edited.");
        incident.priority = priority;
        self.priorityDidChange = YES;
        self.window.documentEdited = YES;
    }
}


- (IBAction) editLocationName:(id)sender {
    Incident *incident = self.incident;
    NSTextField *locationNameField = self.locationNameField;
    NSString *locationName = locationNameField.stringValue;

    if (! [locationName isEqualToString:incident.location.name ? incident.location.name : @""]) {
        NSLog(@"Location name edited.");
        incident.location.name = locationName;
        self.locationDidChange = YES;
        self.window.documentEdited = YES;
    }
}


- (IBAction) editLocationAddress:(id)sender {
    Incident *incident = self.incident;
    NSTextField *locationAddressField = self.locationAddressField;
    NSString *locationAddress = locationAddressField.stringValue;

    if (! [locationAddress isEqualToString:incident.location.address ? incident.location.address : @""]) {
        NSLog(@"Location address edited.");
        incident.location.address = locationAddress;
        self.locationDidChange = YES;
        self.window.documentEdited = YES;
    }
}


- (NSArray *) sourceForTableView:(NSTableView *)tableView
{
    if (tableView == self.rangersTable) {
        return self.incident.rangersByHandle.allValues;
    }
    else if (tableView == self.typesTable) {
        return self.incident.types;
    }
    else {
        performAlert(@"Table view unknown to IncidentController: %@", tableView);
        return nil;
    }
}


- (NSArray *) sortedSourceArrayForTableView:(NSTableView *)tableView
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@""
                                                                 ascending:YES];

    NSArray *source = [self sourceForTableView:tableView];

    return [source sortedArrayUsingDescriptors:@[descriptor]];
}


- (id) itemFromTableView:(NSTableView *)tableView row:(NSInteger)rowIndex
{
    if (rowIndex < 0) {
        return nil;
    }

    NSArray *sourceArray = [self sortedSourceArrayForTableView: tableView];

    if (rowIndex > (NSInteger)sourceArray.count) {
        NSLog(@"IncidentController got out of bounds rowIndex: %ld", rowIndex);
        return nil;
    }

    return sourceArray[(NSUInteger)rowIndex];
}



@end



@implementation IncidentController (NSWindowDelegate)


- (BOOL) windowShouldClose:(id)sender {
    return YES;
}


- (void) windowWillClose:(NSNotification *)notification {
    if (notification.object != self.window) {
        return;
    }

    [self reloadIncident];
}


@end



@implementation IncidentController (NSTableViewDataSource)


- (NSUInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.rangersTable) {
        return self.incident.rangersByHandle.count;
    }
    else if (tableView == self.typesTable) {
        return self.incident.types.count;
    }
    else {
        performAlert(@"Table view unknown to IncidentController: %@", tableView);
        return 0;
    }
}


- (id)            tableView:(NSTableView *)tableView
  objectValueForTableColumn:(NSTableColumn *)column
                        row:(NSInteger)rowIndex {
    return [self itemFromTableView:tableView row:rowIndex];
}


@end



@implementation IncidentController (NSTableViewDelegate)
@end



@implementation IncidentController (TableViewDelegate)


- (void) deleteFromTableView:(NSTableView *)tableView
{
    NSInteger rowIndex = tableView.selectedRow;

    id objectToDelete = [self itemFromTableView:tableView row:rowIndex];

    if (objectToDelete) {
        NSLog(@"Removing: %@", objectToDelete);

        if (tableView == self.rangersTable) {
            [self.incident removeRanger:objectToDelete];
            self.rangersDidChange = YES;
        }
        else if (tableView == self.typesTable) {
            [self.incident.types removeObject:objectToDelete];
            self.typesDidChange = YES;
        }
        else {
            performAlert(@"Table view unknown to IncidentController: %@", tableView);
            return;
        }
        self.window.documentEdited = YES;

        [self updateView];
    }
}


- (void) openFromTableView:(NSTableView *)tableView
{
}


@end



@implementation IncidentController (NSTextFieldDelegate)


- (NSArray *) completionSourceForControl:(NSControl *)control
{
    if (control == self.rangerToAddField) {
        return self.dispatchQueueController.dataStore.allRangersByHandle.allKeys;
    }

    if (control == self.typeToAddField) {
        return self.dispatchQueueController.dataStore.allIncidentTypes;
    }

    return nil;
}


- (NSArray *) completionsForWord:(NSString *)word
                      fromSource:(NSArray *)source
{
    if (! [word isEqualToString:@"?"]) {
        BOOL(^startsWithFilter)(NSString *, NSDictionary *) = ^(NSString *text, NSDictionary *bindings) {
            NSRange range = [text rangeOfString:word options:NSAnchoredSearch|NSCaseInsensitiveSearch];

            return (BOOL)(range.location != NSNotFound);
        };
        NSPredicate *predicate = [NSPredicate predicateWithBlock:startsWithFilter];

        // FIXME: This doesn't work because completion rewrites the entered text
//        BOOL(^containsFilter)(NSString *, NSDictionary *) = ^(NSString *text, NSDictionary *bindings) {
//            NSRange range = [text rangeOfString:word options:NSCaseInsensitiveSearch];
//
//            return (BOOL)(range.location != NSNotFound);
//        };
//        NSPredicate *predicate = [NSPredicate predicateWithBlock:containsFilter];

        source = [source filteredArrayUsingPredicate:predicate];
    }
    source = [source sortedArrayUsingSelector:NSSelectorFromString(@"localizedCaseInsensitiveCompare:")];

    return source;
}


- (NSArray *) control:(NSControl *)control
             textView:(NSTextView *)textView
          completions:(NSArray *)words
  forPartialWordRange:(NSRange)charRange
  indexOfSelectedItem:(NSInteger *)index
{
    NSArray *source = [self completionSourceForControl:control];

    if (! source) {
        performAlert(@"Completion request from unknown control: %@", control);
        return @[];
    }

    return [self completionsForWord:textView.string fromSource:source];
}


- (void) controlTextDidChange:(NSNotification *)notification
{
    if (self.amBackspacing) {
        self.amBackspacing = NO;
        return;
    }

    if (! self.amCompleting) {
        self.amCompleting = YES;

        NSTextView *fieldEditor = [[notification userInfo] objectForKey:@"NSFieldEditor"];
        [fieldEditor complete:nil];

        self.amCompleting = NO;
    }
}


- (void)      control:(NSControl *)control
             textView:(NSTextView *)textView
  doCommandBySelector:(SEL)command
{
    if (control == self.rangerToAddField || control == self.typeToAddField) {
        if (command == NSSelectorFromString(@"deleteBackward:")) {
            self.amBackspacing = YES;
        }
        else if (command == NSSelectorFromString(@"insertNewline:")) {
            if (control == self.rangerToAddField) {
                NSTextField *rangerToAddField = self.rangerToAddField;
                NSString *rangerHandle = rangerToAddField.stringValue;

                if (rangerHandle.length > 0) {
                    Ranger *ranger = self.incident.rangersByHandle[rangerHandle];
                    if (! ranger) {
                        ranger = self.dispatchQueueController.dataStore.allRangersByHandle[rangerHandle];
                        if (ranger) {
                            NSLog(@"Ranger added: %@", ranger);
                            [self.incident addRanger:ranger];
                            self.rangersDidChange = YES;
                            self.window.documentEdited = YES;
                            rangerToAddField.stringValue = @"";
                            [self updateView];
                        }
                        else {
                            NSLog(@"Unknown Ranger: %@", rangerHandle);
                            NSBeep();
                        }
                    }
                }
            }
            else if (control == self.typeToAddField) {
                NSTextField *typeToAddField = self.typeToAddField;
                NSString *type = typeToAddField.stringValue;

                if (type.length > 0) {
                    if (! [self.incident.types containsObject:type]) {
                        if ([self.dispatchQueueController.dataStore.allIncidentTypes containsObject:type]) {
                            NSLog(@"Type added: %@", type);
                            [self.incident.types addObject:type];
                            self.typesDidChange = YES;
                            self.window.documentEdited = YES;
                            typeToAddField.stringValue = @"";
                            [self updateView];
                        }
                        else {
                            NSLog(@"Unknown incident type: %@", type);
                            NSBeep();
                        }
                    }
                }
            }
        }
        else {
            NSLog(@"Do command: %@", NSStringFromSelector(command));
        }
    }
}


- (BOOL) textView:(NSTextView *)textView doCommandBySelector:(SEL)selector
{
    if (textView == self.reportEntryToAddView) {
	if (selector == NSSelectorFromString(@"insertNewline:")) {
            NSTextView *reportEntryToAddView = self.reportEntryToAddView;
            [reportEntryToAddView insertNewlineIgnoringFieldEditor:self];
            return YES;
        }
    }
    return NO;
}


@end
