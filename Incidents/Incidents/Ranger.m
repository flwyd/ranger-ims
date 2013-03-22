////
// Ranger.m
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



@interface Ranger ()
@end



@implementation Ranger


- (id) initWithHandle:(NSString *)handle
{
    if (self = [super init]) {
        self.handle = handle;
    }
    return self;
}


- (id) copyWithZone:(NSZone *)zone
{
    Ranger *copy;
    if ((copy = [[self class] allocWithZone:zone])) {
        copy = [copy initWithHandle:self.handle];
    }
    return copy;
}


- (BOOL) isEqual:(id)other
{
    if ([other isKindOfClass: [self class]])
    {
        Ranger *otherRanger = (Ranger *)other;

        if ([self.handle isEqualToString:otherRanger.handle]) {
            return YES;
        }
    }

    return NO;
}


- (NSUInteger) hash
{
    return self.handle.hash;
}


- (NSComparisonResult) compare:(Ranger *)other
{
    return [self.handle compare:other.handle];
}


- (NSString *) description
{
    return self.handle;
}


@end
