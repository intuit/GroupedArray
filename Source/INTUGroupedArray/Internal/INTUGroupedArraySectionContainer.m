//
//  INTUGroupedArraySectionContainer.h
//  https://github.com/intuit/GroupedArray
//
//  Copyright (c) 2014-2015 Intuit Inc.
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "INTUGroupedArraySectionContainer.h"

@implementation INTUGroupedArraySectionContainer

/**
 Returns a new section container with the given section.
 */
+ (instancetype)sectionContainerWithSection:(id)section
{
    INTUGroupedArraySectionContainer *sectionContainer = [self new];
    sectionContainer.section = section;
    sectionContainer.objects = [NSArray new];
    return sectionContainer;
}

/**
 Perform a shallow copy of the section container, so that the section and objects are not copied.
 */
- (instancetype)copyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [[[self class] allocWithZone:zone] init];
    copy.section = self.section;
    copy.objects = [[NSArray allocWithZone:zone] initWithArray:self.objects copyItems:NO];
    return copy;
}

/**
 Perform a shallow copy of the section container, so that the section and objects are not copied.
 */
- (instancetype)mutableCopyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [[[self class] allocWithZone:zone] init];
    copy.section = self.section;
    copy.objects = [[NSMutableArray allocWithZone:zone] initWithArray:self.objects copyItems:NO];
    return copy;
}

/**
 Creates and returns a new section container with the contents of a given section container, optionally copying the section & objects.
 */
- (instancetype)initWithSectionContainer:(INTUGroupedArraySectionContainer *)sectionContainer copyItems:(BOOL)copyItems
{
    __typeof(self) newSectionContainer = [[[self class] alloc] init];
    newSectionContainer.section = copyItems ? [sectionContainer.section copy] : sectionContainer.section;
    newSectionContainer.objects = [[NSArray alloc] initWithArray:sectionContainer.objects copyItems:copyItems];
    return newSectionContainer;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self) {
        self.section = [aDecoder decodeObjectForKey:@"section"];
        self.objects = [aDecoder decodeObjectForKey:@"objects"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (_section) {
        [aCoder encodeObject:_section forKey:@"section"];
    }
    if (_objects) {
        [aCoder encodeObject:_objects forKey:@"objects"];
    }
}

@end

@implementation INTUMutableGroupedArraySectionContainer

/**
 Returns a new section container with the given section.
 */
+ (instancetype)sectionContainerWithSection:(id)section
{
    INTUMutableGroupedArraySectionContainer *sectionContainer = [self new];
    sectionContainer.section = section;
    sectionContainer.objects = [NSMutableArray new];
    return sectionContainer;
}

/**
 Creates and returns a new mutable section container with the contents of a given section container, optionally copying the section & objects.
 */
- (instancetype)initWithSectionContainer:(INTUGroupedArraySectionContainer *)sectionContainer copyItems:(BOOL)copyItems
{
    __typeof(self) newSectionContainer = [[[self class] alloc] init];
    newSectionContainer.section = copyItems ? [sectionContainer.section copy] : sectionContainer.section;
    newSectionContainer.objects = [[NSMutableArray alloc] initWithArray:sectionContainer.objects copyItems:copyItems];
    return newSectionContainer;
}

- (NSMutableArray *)mutableObjects
{
    return (NSMutableArray *)[super objects];
}

- (void)setMutableObjects:(NSMutableArray *)mutableObjects
{
    [super setObjects:mutableObjects];
}

@end
