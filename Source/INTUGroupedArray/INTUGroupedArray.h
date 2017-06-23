//
//  INTUGroupedArray.h
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

#import <Foundation/Foundation.h>
#import "INTUGroupedArrayDefines.h"

GA__INTU_ASSUME_NONNULL_BEGIN


#pragma mark - INTUGroupedArraySectionEnumerator

/** A protocol for an enumerator that will enumerate over sections in a grouped array. */
@protocol INTUGroupedArraySectionEnumerator <NSObject>

/** Returns the next section from the grouped array being enumerated. Returns nil when all sections have been enumerated. */
- (GA__INTU_NULLABLE id)nextSection;

/** Returns an array of all sections from the grouped array that have not yet been enumerated. */
- (NSArray *)allSections;

@end


#pragma mark - INTUGroupedArray

/**
 A collection that holds an array of sections and each section contains an array of objects. Both sections
 and objects can be instances of any class. INTUGroupedArray works particularly well as a backing store for
 a table view.
 
 INTUGroupedArray guarantees that there will never be empty sections - all sections will contain at least
 one object.
 
 Instances of INTUGroupedArray are thread safe, however subclasses may not be (for instance, 
 INTUMutableGroupedArray is NOT thread safe).
 
 Regular INTUGroupedArray instances act like standard collections and will raise exceptions if assertions are
 enabled when attempting to access sections or objects that don't exist in the grouped array. However, if
 assertions are disabled, INTUGroupedArray will fail gracefully.
 */
@interface GA__INTU_GENERICS(INTUGroupedArray, SectionType, ObjectType) : NSObject <NSCopying, NSMutableCopying, NSCoding, NSFastEnumeration>
{
@protected
    /** A token that is incremented on every mutation. */
    unsigned long _mutations;
}

/** Helper method to create an index path when the UIKit category on NSIndexPath is not available. */
+ (NSIndexPath *)indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section;


#pragma mark Class Factory Methods

/** Creates and returns a new empty grouped array. */
+ (instancetype)groupedArray;
/** Creates and returns a new grouped array with a single section ([NSObject new]) containing the objects in the array. */
+ (instancetype)groupedArrayWithArray:(GA__INTU_NULLABLE NSArray *)array;

/** Creates and returns a grouped array from the literal syntax.
    Syntax: @[section1, @[object1A, object1B, ...], section2, @[object2A, object2B, ...], ...] */
+ (instancetype)literal:(NSArray *)groupedArrayLiteral;


#pragma mark Initializers

/** Creates and returns a new grouped array with the contents of a given grouped array. */
- (instancetype)initWithGroupedArray:(INTUGroupedArray *)groupedArray;
/** Creates and returns a new grouped array with the contents of a given grouped array, optionally copying the sections & objects. */
- (instancetype)initWithGroupedArray:(INTUGroupedArray *)groupedArray copyItems:(BOOL)copyItems;


#pragma mark Access Methods

/** Returns the section at the index. */
- (GA__INTU_GENERICS_TYPE(SectionType))sectionAtIndex:(NSUInteger)index;
/** Returns the number of sections. */
- (NSUInteger)countAllSections;
/** Returns an array of all the sections. */
- (GA__INTU_GENERICS(NSArray, SectionType) *)allSections;
/** Returns whether the section exists. */
- (BOOL)containsSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Returns the index for the section. */
- (NSUInteger)indexOfSection:(GA__INTU_GENERICS_TYPE(SectionType))section;

/** Returns the object at the index in the section. */
- (GA__INTU_GENERICS_TYPE(ObjectType))objectAtIndex:(NSUInteger)index inSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Returns the object at the index path. */
- (GA__INTU_GENERICS_TYPE(ObjectType))objectAtIndexPath:(NSIndexPath *)indexPath;
/** Returns the first object in the first section. */
- (GA__INTU_NULLABLE GA__INTU_GENERICS_TYPE(ObjectType))firstObject;
/** Returns the last object in the last section. */
- (GA__INTU_NULLABLE GA__INTU_GENERICS_TYPE(ObjectType))lastObject;
/** Returns whether the object exists in any section. */
- (BOOL)containsObject:(GA__INTU_GENERICS_TYPE(ObjectType))object;
/** Returns the index path of the first instance of the object across all sections. */
- (NSIndexPath *)indexPathOfObject:(GA__INTU_GENERICS_TYPE(ObjectType))object;
/** Returns whether the object exists in the section. */
- (BOOL)containsObject:(GA__INTU_GENERICS_TYPE(ObjectType))object inSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Returns the index of the first instance of the object in the section. */
- (NSUInteger)indexOfObject:(GA__INTU_GENERICS_TYPE(ObjectType))object inSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Returns the number of objects in the section. */
- (NSUInteger)countObjectsInSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Returns the number of objects in the section at the index. */
- (NSUInteger)countObjectsInSectionAtIndex:(NSUInteger)index;
/** Returns the objects in the section. */
- (GA__INTU_GENERICS(NSArray, ObjectType) *)objectsInSection:(GA__INTU_GENERICS_TYPE(SectionType))section;
/** Returns the objects in the section at the index. */
- (GA__INTU_GENERICS(NSArray, ObjectType) *)objectsInSectionAtIndex:(NSUInteger)index;
/** Returns the total number of objects in all sections. */
- (NSUInteger)countAllObjects;
/** Returns an array of all objects in all sections. */
- (GA__INTU_GENERICS(NSArray, ObjectType) *)allObjects;

/** Executes the block for each section in the grouped array. */
- (void)enumerateSectionsUsingBlock:(void (^)(GA__INTU_GENERICS_TYPE(SectionType) section, NSUInteger index, BOOL *stop))block;
/** Executes the block for each section in the grouped array with the specified enumeration options. */
- (void)enumerateSectionsWithOptions:(NSEnumerationOptions)options usingBlock:(void (^)(GA__INTU_GENERICS_TYPE(SectionType) section, NSUInteger index, BOOL *stop))block;
/** Executes the block for each object in the grouped array. */
- (void)enumerateObjectsUsingBlock:(void (^)(GA__INTU_GENERICS_TYPE(ObjectType) object, NSIndexPath *indexPath, BOOL *stop))block;
/** Executes the block for each object in the grouped array with the specified enumeration options. */
- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)options usingBlock:(void (^)(GA__INTU_GENERICS_TYPE(ObjectType) object, NSIndexPath *indexPath, BOOL *stop))block;
/** Executes the block for each object in the section at the index. */
- (void)enumerateObjectsInSectionAtIndex:(NSUInteger)sectionIndex usingBlock:(void (^)(GA__INTU_GENERICS_TYPE(ObjectType) object, NSIndexPath *indexPath, BOOL *stop))block;
/** Executes the block for each object in the section at the index with the specified enumeration options. */
- (void)enumerateObjectsInSectionAtIndex:(NSUInteger)sectionIndex withOptions:(NSEnumerationOptions)options usingBlock:(void (^)(GA__INTU_GENERICS_TYPE(ObjectType) object, NSIndexPath *indexPath, BOOL *stop))block;

/** Returns an enumerator that will access each section in the grouped array, starting with the first section. */
- (NSEnumerator<INTUGroupedArraySectionEnumerator> *)sectionEnumerator;
/** Returns an enumerator that will access each section in the grouped array, starting with the last section. */
- (NSEnumerator<INTUGroupedArraySectionEnumerator> *)reverseSectionEnumerator;
/** Returns an enumerator that will access each object in the grouped array, starting with the first section. */
- (NSEnumerator *)objectEnumerator;
/** Returns an enumerator that will access each object in the grouped array, starting with the last section. */
- (NSEnumerator *)reverseObjectEnumerator;

/** Returns the index of the first section in the grouped array that passes the test. */
- (NSUInteger)indexOfSectionPassingTest:(BOOL (^)(GA__INTU_GENERICS_TYPE(SectionType) section, NSUInteger index, BOOL *stop))block;
/** Returns the index path of the first object in the grouped array that passes the test. */
- (NSIndexPath *)indexPathOfObjectPassingTest:(BOOL (^)(GA__INTU_GENERICS_TYPE(ObjectType) object, NSIndexPath *indexPath, BOOL *stop))block;

/** Returns whether the contents of this grouped array are equal to the contents of another grouped array. */
- (BOOL)isEqualToGroupedArray:(GA__INTU_NULLABLE INTUGroupedArray *)otherGroupedArray;

/** Returns a new grouped array filtered by evaluating the section & object predicates against all sections & objects and removing those that do not match. Empty sections will be removed. */
- (GA__INTU_GENERICS(INTUGroupedArray, SectionType, ObjectType) *)filteredGroupedArrayUsingSectionPredicate:(GA__INTU_NULLABLE NSPredicate *)sectionPredicate objectPredicate:(GA__INTU_NULLABLE NSPredicate *)objectPredicate;

/** Returns a new grouped array with the sections sorted using the section comparator, and the objects in each section sorted using the object comparator. */
- (GA__INTU_GENERICS(INTUGroupedArray, SectionType, ObjectType) *)sortedGroupedArrayUsingSectionComparator:(GA__INTU_NULLABLE NSComparator)sectionCmptr objectComparator:(GA__INTU_NULLABLE NSComparator)objectCmptr;

@end

GA__INTU_ASSUME_NONNULL_END
