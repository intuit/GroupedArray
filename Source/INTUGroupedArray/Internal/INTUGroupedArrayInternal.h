//
//  INTUGroupedArrayInternal.h
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

#ifndef INTUGroupedArrayInternal_h
#define INTUGroupedArrayInternal_h

#import "INTUGroupedArray.h"
#import "INTUIndexPair.h"
#import "INTUGroupedArraySectionContainer.h"

GA__INTU_ASSUME_NONNULL_BEGIN

/**
 A category on INTUGroupedArray that exposes some private internal properties and methods for
 subclasses to access.
 */
@interface GA__INTU_GENERICS(INTUGroupedArray, SectionType, ObjectType) (Internal)

// An array of INTUGroupedArraySectionContainer objects.
@property (nonatomic, strong) GA__INTU_GENERICS(NSArray, GA__INTU_GENERICS(INTUGroupedArraySectionContainer, SectionType, ObjectType) *) *sectionContainers;

/**
 Returns the memory address of the _mutations instance variable.
 */
- (unsigned long *)_mutationsPtr;

/**
 An internally exposed variant of objectAtIndexPath that takes an INTUIndexPair instead of NSIndexPath.
 This method may be called directly instead of the NSIndexPath variant in order to avoid the overhead of
 instantiating many NSIndexPath objects (e.g. during fast enumeration).
 
 An exception will be raised if the index pair is out of bounds.
 
 @param indexPair The index pair of the object.
 @return The object at the index pair, or nil if the index pair is out of bounds.
 */
- (GA__INTU_GENERICS_TYPE(ObjectType))_objectAtIndexPair:(INTUIndexPair)indexPair;

@end

GA__INTU_ASSUME_NONNULL_END

#endif /* INTUGroupedArrayInternal_h */
