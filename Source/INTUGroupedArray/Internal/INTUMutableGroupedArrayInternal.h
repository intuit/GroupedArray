//
//  INTUMutableGroupedArrayInternal.h
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

#ifndef INTUMutableGroupedArrayInternal_h
#define INTUMutableGroupedArrayInternal_h

#import "INTUMutableGroupedArray.h"

GA__INTU_ASSUME_NONNULL_BEGIN

/**
 A category on INTUMutableGroupedArray that exposes some private internal properties and methods for
 subclasses to access.
 */
@interface GA__INTU_GENERICS(INTUMutableGroupedArray, SectionType, ObjectType) (Internal)

// A mutable array of INTUMutableGroupedArraySectionContainer objects.
@property (nonatomic) GA__INTU_GENERICS(NSMutableArray, GA__INTU_GENERICS(INTUMutableGroupedArraySectionContainer, SectionType, ObjectType) *) *mutableSectionContainers;

- (GA__INTU_GENERICS(NSMutableArray, ObjectType) *)_objectsArrayForSection:(GA__INTU_GENERICS_TYPE(SectionType))section withSectionIndexHint:(NSUInteger)sectionIndexHint;

@end

GA__INTU_ASSUME_NONNULL_END

#endif /* INTUMutableGroupedArrayInternal_h */
