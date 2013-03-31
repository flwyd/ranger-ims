////
// PreferencesController.m
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

#import "HTTPConnectionInfo.h"
#import "AppDelegate.h"
#import "PreferencesController.h"



@interface PreferencesController ()

@property (unsafe_unretained) AppDelegate *appDelegate;

@property (unsafe_unretained) IBOutlet NSTextField *serverNameField;
@property (unsafe_unretained) IBOutlet NSTextField *serverPortField;

@end



@implementation PreferencesController


- (id) initWithAppDelegate:(AppDelegate *)appDelegate
{
    if (self = [super initWithWindowNibName:@"PreferencesController"]) {
        self.appDelegate = appDelegate;
    }
    return self;
}


- (void) windowDidLoad
{
    [super windowDidLoad];

    self.serverNameField.stringValue = self.appDelegate.connectionInfo.serverName;
    self.serverPortField.integerValue = self.appDelegate.connectionInfo.serverPort;
}


- (IBAction) editServerName:(id)sender
{
    NSTextField *field = sender;
    self.appDelegate.connectionInfo.serverName = field.stringValue;
}


- (IBAction) editServerPort:(id)sender
{
    NSTextField *field = sender;
    self.appDelegate.connectionInfo.serverPort = field.integerValue;
}


@end
