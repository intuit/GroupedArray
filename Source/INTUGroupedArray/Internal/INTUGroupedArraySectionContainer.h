//
//  INTUGroupedArraySectionContainer.h
//  https://github.com/intuit/GroupedArray
//
//  Copyright (c) 2014 Intuit Inc.
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

#import <Foundation/Foundation.h>

/**
 A helper object used to encapsulate the section and its associated array of objects.
 */
@interface INTUGroupedArraySectionContainer : NSObject <NSCopying, NSMutableCopying, NSCoding>

@property (nonatomic, strong) id section;
@property (nonatomic, strong) NSArray *objects;

/** Returns a new section container with the given section. */
+ (instancetype)sectionContainerWithSection:(id)section;

/** Returns a new section container that is a deep copy of the section container, copying the section and objects. */
- (instancetype)initWithSectionContainer:(INTUGroupedArraySectionContainer *)sectionContainer copyItems:(BOOL)copyItems;

@end


/**
 A helper object used to encapsulate the section and its associated mutable array of objects.
 */
@interface INTUMutableGroupedArraySectionContainer : INTUGroupedArraySectionContainer

/** Exposes the superclass objects instance variable typecast to NSMutableArray. */
@property (nonatomic) NSMutableArray *mutableObjects;

@end
