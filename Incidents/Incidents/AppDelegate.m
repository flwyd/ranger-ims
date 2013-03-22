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

#import "DispatchQueueController.h"
#import "PreferencesController.h"
#import "AppDelegate.h"



@interface AppDelegate ()

@property (strong,nonatomic) DispatchQueueController *dispatchQueueController;
@property (strong,nonatomic) PreferencesController   *preferencesController;

@end



@implementation AppDelegate


- (DispatchQueueController *) dispatchQueueController
{
    if (! _dispatchQueueController) {
        _dispatchQueueController = [[DispatchQueueController alloc] initWithAppDelegate:self];
    }
    return _dispatchQueueController;
}


- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
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


- (PreferencesController *) preferencesController
{
    if (! _preferencesController) {
        _preferencesController = [[PreferencesController alloc] initWithAppDelegate:self];
    }
    return _preferencesController;
}


- (IBAction) showPreferences:(id)sender
{
    [self.preferencesController showWindow:self];
}


@end
