//
//  INTUMutableGroupedArray.h
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

#import "INTUGroupedArray.h"

GA__INTU_ASSUME_NONNULL_BEGIN


/**
 A mutable subclass of INTUGroupedArray.
 
 INTUMutableGroupedArray is NOT thread-safe (just like NSMutableArray). It should only be accessed from one thread.
 
 Calling -[copy] will return an immutable instance of INTUGroupedArray.
 */
@interface GA__INTU_GENERICS(INTUMutableGroupedArray, SectionType, ObjectType) : INTUGroupedArray

#pragma mark Adding

/** Adds an object to the section. If the section does not exist, it will be created. */
- (void)addObject:(GA__INTU_GENERICS_TYPE(ObjectType))object toSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Adds an object to the section, using the section index hint to attempt to quickly locate the section. If the section does not exist, it will be created. */
- (void)addObject:(GA__INTU_GENERICS_TYPE(ObjectType))object toSection:(GA__INTU_GENERICS_TYPE(SectionType))section withSectionIndexHint:(NSUInteger)sectionIndexHint;
/** Adds an object to an existing section at the index. */
- (void)addObject:(GA__INTU_GENERICS_TYPE(ObjectType))object toSectionAtIndex:(NSUInteger)index;
/** Adds the objects in the array to the section. If the section does not exist, it will be created. */
- (void)addObjectsFromArray:(GA__INTU_NULLABLE GA__INTU_GENERICS(NSArray, ObjectType) *)array toSection:(GA__INTU_GENERICS_TYPE(SectionType))section;

#pragma mark Inserting

/** Inserts the object at the index in the section. If the section does not exist, it will be created. */
- (void)insertObject:(GA__INTU_GENERICS_TYPE(ObjectType))object atIndex:(NSUInteger)index inSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Inserts the object at the index path. The index path must correspond to an existing section. */
- (void)insertObject:(GA__INTU_GENERICS_TYPE(ObjectType))object atIndexPath:(NSIndexPath *)indexPath;

#pragma mark Replacing

/** Replaces the section at the index with another section. */
- (void)replaceSectionAtIndex:(NSUInteger)index withSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Replaces the object at the index path with another object. */
- (void)replaceObjectAtIndexPath:(NSIndexPath *)indexPath withObject:(GA__INTU_GENERICS_TYPE(ObjectType))object;

#pragma mark Moving

/** Moves the section at the index to a new index. */
- (void)moveSectionAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex;
/** Moves the object at the index path to a new index path. The new index path must correspond to an existing section. */
- (void)moveObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

#pragma mark Exchanging

/** Exchanges the section at one index with a section at another index. */
- (void)exchangeSectionAtIndex:(NSUInteger)index1 withSectionAtIndex:(NSUInteger)index2;
/** Exchanges the object at one index path with an object at another index path. */
- (void)exchangeObjectAtIndexPath:(NSIndexPath *)indexPath1 withObjectAtIndexPath:(NSIndexPath *)indexPath2;

#pragma mark Removing

/** Removes all objects and sections. */
- (void)removeAllObjects;
/** Removes the section and all objects in it. */
- (void)removeSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Removes the section at the index and all objects in it. */
- (void)removeSectionAtIndex:(NSUInteger)index;
/** Removes all occurrences of the object across all sections. Empty sections will be removed. */
- (void)removeObject:(GA__INTU_GENERICS_TYPE(ObjectType))object;
/** Removes all occurrences of the object from the section. Empty sections will be removed. */
- (void)removeObject:(GA__INTU_GENERICS_TYPE(ObjectType))object fromSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Removes the object at the index from the section. Empty sections will be removed. */
- (void)removeObjectAtIndex:(NSUInteger)index fromSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Removes the object at the index path. Empty sections will be removed. */
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark Filtering

/** Evaluates the section & object predicates against all sections & objects and removes those that do not match. Empty sections will be removed. */
- (void)filterUsingSectionPredicate:(GA__INTU_NULLABLE NSPredicate *)sectionPredicate objectPredicate:(GA__INTU_NULLABLE NSPredicate *)objectPredicate;

#pragma mark Sorting

/** Sorts the sections using the section comparator, and the objects in each section using the object comparator. */
- (void)sortUsingSectionComparator:(GA__INTU_NULLABLE NSComparator)sectionCmptr objectComparator:(GA__INTU_NULLABLE NSComparator)objectCmptr;

@end

GA__INTU_ASSUME_NONNULL_END
