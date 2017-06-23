//
//  INTUMutableGroupedArray.m
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

#import "INTUMutableGroupedArray.h"
#import "INTUGroupedArraySectionContainer.h"
#import "INTUGroupedArrayInternal.h"

@interface GA__INTU_GENERICS(INTUMutableGroupedArray, SectionType, ObjectType) ()

// A mutable array of INTUMutableGroupedArraySectionContainer objects, which serves as the backing store for the grouped array.
// Note that this property does not have its own backing instance variable; it uses the superclass sectionContainers property for storage.
@property (nonatomic) GA__INTU_GENERICS(NSMutableArray, GA__INTU_GENERICS(INTUMutableGroupedArraySectionContainer, SectionType, ObjectType) *) *mutableSectionContainers;

@end

@implementation INTUMutableGroupedArray


#pragma mark Overrides

+ (instancetype)groupedArrayWithArray:(NSArray *)array
{
    INTUMutableGroupedArray *groupedArray = [self new];
    if ([array count] > 0) {
        INTUMutableGroupedArraySectionContainer *sectionContainer = [INTUMutableGroupedArraySectionContainer sectionContainerWithSection:[NSObject new]];
        sectionContainer.mutableObjects = [array mutableCopy];
        groupedArray.mutableSectionContainers = [NSMutableArray arrayWithObject:sectionContainer];
    }
    return groupedArray;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mutableSectionContainers = [NSMutableArray new];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    INTUGroupedArray *copy = [[INTUGroupedArray allocWithZone:zone] init];
    // The array of sectionContainers is deep copied so that the INTUGroupedArraySectionContainer objects it holds are also copied,
    // but since this is only a one level deep copy, the sections & objects in the grouped array will NOT be deep copied!
    copy.sectionContainers = [[NSMutableArray allocWithZone:zone] initWithArray:self.sectionContainers copyItems:YES];
    return copy;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [[[self class] allocWithZone:zone] init];
    for (INTUGroupedArraySectionContainer *sectionContainer in self.sectionContainers) {
        [copy.mutableSectionContainers addObject:[sectionContainer mutableCopy]];
    }
    return copy;
}

- (NSMutableArray *)mutableSectionContainers
{
    return (NSMutableArray *)[super sectionContainers];
}

- (void)setMutableSectionContainers:(NSMutableArray *)mutableSectionContainers
{
    [super setSectionContainers:mutableSectionContainers];
}


#pragma mark Adding

/**
 Adds an object to the section. If the section does not exist, it will be created.
 Performance: O(n), where n is the number of sections
 
 @param object The object to add to the grouped array.
 @param section The section to add the object to.
 */
- (void)addObject:(id)object toSection:(id)section
{
    [self addObject:object toSection:section withSectionIndexHint:NSNotFound];
}

/**
 Adds an object to the section, using the section index hint to attempt to quickly locate the section. If the section does
 not exist, it will be created. Passing an accurate hint for the section index will dramatically accelerate performance
 when there are a large number of sections, as it will avoid having to call -[self indexOfSection:] to find the section.
 Performance: O(1) assuming an accurate section index hint; otherwise O(n), where n is the number of sections
 
 @param object The object to add to the grouped array.
 @param section The section to add the object to.
 @param sectionIndexHint An optional hint to the index of the section. (Pass NSNotFound to ignore the hint.)
 */
- (void)addObject:(id)object toSection:(id)section withSectionIndexHint:(NSUInteger)sectionIndexHint
{
    if (!object || !section) {
        NSAssert(object, @"Object should not be nil.");
        NSAssert(section, @"Section should not be nil.");
        return;
    }
    
    NSMutableArray *objectsArray = [self _objectsArrayForSection:section withSectionIndexHint:sectionIndexHint];
    if (objectsArray == nil) {
        // Section does not exist yet, we need to create it
        INTUMutableGroupedArraySectionContainer *sectionContainer = [INTUMutableGroupedArraySectionContainer sectionContainerWithSection:section];
        [self.mutableSectionContainers addObject:sectionContainer];
        objectsArray = sectionContainer.mutableObjects;
    }
    
    [objectsArray addObject:object];
    _mutations++;
}

/**
 Adds an object to an existing section at the index.
 An exception will be raised if the index is out of bounds.
 Performance: O(1)
 
 @param object The object to add to the grouped array.
 @param index The index of the section to add the object to.
 */
- (void)addObject:(id)object toSectionAtIndex:(NSUInteger)index
{
    if (index >= [self countAllSections]) {
        NSAssert(index < [self countAllSections], @"Index out of bounds!");
        return;
    }
    
    INTUMutableGroupedArraySectionContainer *sectionContainer = self.sectionContainers[index];
    NSMutableArray *objectsArray = sectionContainer.mutableObjects;
    [objectsArray addObject:object];
    _mutations++;
}

/**
 Adds the objects in the array to the section. If the section does not exist, it will be created.
 If the array is nil or empty, this method will do nothing.
 Performance: O(n+m), where n is the number of sections, and m is the number of objects to add
 
 @param array The array of objects to add to the grouped array.
 @param section The section to add the objects to.
 */
- (void)addObjectsFromArray:(NSArray *)array toSection:(id)section
{
    NSUInteger sectionIndex = [self indexOfSection:section];
    for (id obj in array) {
        [self addObject:obj toSection:section withSectionIndexHint:sectionIndex];
    }
}

#pragma mark Inserting

/**
 Inserts the object at the index in the section. If the section does not exist, it will be created.
 Performance: O(n+m), where n is the number of sections, and m is the number of objects in the section
 
 @param object The object to add to the grouped array.
 @param index The index to insert the object at in the section. Must not be greater than the current number
              of objects in the section.
 @param section The section to add the object to.
 */
- (void)insertObject:(id)object atIndex:(NSUInteger)index inSection:(id)section
{
    if (!object || !section) {
        NSAssert(object, @"Object should not be nil.");
        NSAssert(section, @"Section should not be nil.");
        return;
    }
    
    NSMutableArray *objectsArray = [self _objectsArrayForSection:section withSectionIndexHint:NSNotFound];
    if (objectsArray == nil) {
        // Section does not exist yet, we need to create it
        INTUMutableGroupedArraySectionContainer *sectionContainer = [INTUMutableGroupedArraySectionContainer sectionContainerWithSection:section];
        [self.mutableSectionContainers addObject:sectionContainer];
        objectsArray = sectionContainer.mutableObjects;
    }
    
    if (index > [objectsArray count]) {
        NSAssert(index <= [objectsArray count], @"Index out of bounds!");
        return;
    }
    
    [objectsArray insertObject:object atIndex:index];
    _mutations++;
}

/**
 Inserts the object at the index path. The index path must correspond to an existing section.
 Performance: O(n), where n is the number of objects in the section
 
 @param object The object to add to the grouped array.
 @param indexPath The index path to insert the object at. The section component must be less than the current number of sections,
                  and the row component must not be greater than the current number of objects in the section.
 */
- (void)insertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{
    if (!object || !indexPath) {
        NSAssert(object, @"Object should not be nil.");
        NSAssert(indexPath, @"Index path should not be nil.");
        return;
    }
    
    NSUInteger sectionIndex = [indexPath indexAtPosition:0];
    NSUInteger objectIndex = [indexPath indexAtPosition:1];
    
    if (sectionIndex >= [self countAllSections]) {
        NSAssert(sectionIndex < [self countAllSections], @"Section index out of bounds!");
        return;
    }
    
    INTUMutableGroupedArraySectionContainer *sectionContainer = self.sectionContainers[sectionIndex];
    NSMutableArray *objectsArray = sectionContainer.mutableObjects;
    
    if (objectIndex > [objectsArray count]) {
        NSAssert(objectIndex <= [objectsArray count], @"Object index out of bounds!");
        return;
    }
    
    [objectsArray insertObject:object atIndex:objectIndex];
    _mutations++;
}

#pragma mark Replacing

/**
 Replaces the section at the index with another section.
 Performance: O(1)
 
 @param index The index of the section to replace.
 @param section The section with which to replace the existing section at the given index.
 */
- (void)replaceSectionAtIndex:(NSUInteger)index withSection:(id)section
{
    if (!section) {
        NSAssert(section, @"Section should not be nil.");
        return;
    }
    
    NSUInteger sectionCount = [self countAllSections];
    if (index >= sectionCount) {
        NSAssert(index < sectionCount, @"Index out of bounds!");
        return;
    }
    
    INTUGroupedArraySectionContainer *sectionContainer = self.sectionContainers[index];
    sectionContainer.section = section;
    _mutations++;
}

/**
 Replaces the object at the index path with another object.
 Performance: O(1)
 
 @param indexPath The index path of the object to replace.
 @param object The object with which to replace the existing object at the given index path.
 */
- (void)replaceObjectAtIndexPath:(NSIndexPath *)indexPath withObject:(id)object
{
    if (!object || !indexPath) {
        NSAssert(object, @"Object should not be nil.");
        NSAssert(indexPath, @"Index path should not be nil.");
        return;
    }
    
    NSUInteger sectionIndex = [indexPath indexAtPosition:0];
    NSUInteger objectIndex = [indexPath indexAtPosition:1];
    
    if (sectionIndex >= [self countAllSections]) {
        NSAssert(sectionIndex < [self countAllSections], @"Section index out of bounds!");
        return;
    }
    
    INTUMutableGroupedArraySectionContainer *sectionContainer = self.sectionContainers[sectionIndex];
    NSMutableArray *objectsArray = sectionContainer.mutableObjects;
    
    if (objectIndex >= [objectsArray count]) {
        NSAssert(objectIndex < [objectsArray count], @"Object index out of bounds!");
        return;
    }
    
    [objectsArray replaceObjectAtIndex:objectIndex withObject:object];
    _mutations++;
}

#pragma mark Moving

/**
 Moves the section at the index to a new index.
 Performance: O(n), where n is the number of sections
 
 @param fromIndex The index of the section to move.
 @param toIndex The index to move the section to.
 */
- (void)moveSectionAtIndex:(NSUInteger)fromIndex toIndex:(NSUInteger)toIndex
{
    NSUInteger sectionCount = [self countAllSections];
    if (fromIndex >= sectionCount || toIndex >= sectionCount) {
        NSAssert(fromIndex < sectionCount, @"From index out of bounds!");
        NSAssert(toIndex < sectionCount, @"To index out of bounds!");
        return;
    }
    
    INTUGroupedArraySectionContainer *sectionContainer = self.sectionContainers[fromIndex];
    [self.mutableSectionContainers removeObjectAtIndex:fromIndex];
    [self.mutableSectionContainers insertObject:sectionContainer atIndex:toIndex];
    _mutations++;
}

/**
 Moves the object at the index path to a new index path. The new index path must correspond to an existing section.
 Performance: O(n+m), where n is the number of sections, and m is the number of objects in the two sections
 
 @param fromIndexPath The index path of the object to move.
 @param toIndexPath The index path to move the object to.
 */
- (void)moveObjectAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    if (!fromIndexPath || !toIndexPath) {
        NSAssert(fromIndexPath, @"From index path should not be nil!");
        NSAssert(toIndexPath, @"To index path should not be nil!");
        return;
    }
    
    NSUInteger fromSectionIndex = [fromIndexPath indexAtPosition:0];
    NSUInteger fromObjectIndex = [fromIndexPath indexAtPosition:1];
    NSUInteger toSectionIndex = [toIndexPath indexAtPosition:0];
    NSUInteger toObjectIndex = [toIndexPath indexAtPosition:1];
    
    NSUInteger sectionCount = [self countAllSections];
    if (fromSectionIndex >= sectionCount || toSectionIndex >= sectionCount) {
        NSAssert(fromSectionIndex < sectionCount, @"From index path section out of bounds!");
        NSAssert(toSectionIndex < sectionCount, @"To index path section out of bounds!");
        return;
    }
    
    NSUInteger fromObjectCount = [self countObjectsInSectionAtIndex:fromSectionIndex];
    NSUInteger toObjectCount;
    if (fromSectionIndex == toSectionIndex) {
        toObjectCount = fromObjectCount;
    } else {
        toObjectCount = [self countObjectsInSectionAtIndex:toSectionIndex] + 1; // add 1 to the current count since moving the object to the section will increase this
    }
    if (fromObjectIndex >= fromObjectCount || toObjectIndex >= toObjectCount) {
        NSAssert(fromObjectIndex < fromObjectCount, @"From index path row out of bounds!");
        NSAssert(toObjectIndex < toObjectCount, @"To index path row out of bounds!");
        return;
    }
    
    id object = [self objectAtIndexPath:fromIndexPath];
    // Don't use [self removeObjectAtIndexPath:] here because we need to finish the insert before checking if the from section is empty
    INTUMutableGroupedArraySectionContainer *sectionContainer = self.sectionContainers[fromSectionIndex];
    NSMutableArray *objectsArray = sectionContainer.mutableObjects;
    [objectsArray removeObjectAtIndex:fromObjectIndex];
    [self insertObject:object atIndexPath:toIndexPath];
    // Check if moving this object left its section empty; if so, remove it
    if ([objectsArray count] == 0) {
        [self removeSectionAtIndex:fromSectionIndex];
    }
    _mutations++;
}

#pragma mark Exchanging

/**
 Exchanges the section at one index with a section at another index.
 Performance: O(1)
 
 @param index1 The index of the section to replace with the section at index2.
 @param index2 The index of the section to replace with the section at index1.
 */
- (void)exchangeSectionAtIndex:(NSUInteger)index1 withSectionAtIndex:(NSUInteger)index2
{
    NSUInteger sectionCount = [self countAllSections];
    if (index1 >= sectionCount || index2 >= sectionCount) {
        NSAssert(index1 < sectionCount, @"Index 1 out of bounds!");
        NSAssert(index2 < sectionCount, @"Index 2 out of bounds!");
        return;
    }
    [self.mutableSectionContainers exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    _mutations++;
}

/**
 Exchanges the object at one index path with an object at another index path.
 Performance: O(1)
 
 @param indexPath1 The index path of the object to replace with the object at indexPath2.
 @param indexPath2 The index path of the object to replace with the object at indexPath1.
 */
- (void)exchangeObjectAtIndexPath:(NSIndexPath *)indexPath1 withObjectAtIndexPath:(NSIndexPath *)indexPath2
{
    if (!indexPath1 || !indexPath2) {
        NSAssert(indexPath1, @"Index path 1 should not be nil!");
        NSAssert(indexPath2, @"Index path 2 should not be nil!");
        return;
    }
    
    NSUInteger sectionIndex1 = [indexPath1 indexAtPosition:0];
    NSUInteger objectIndex1 = [indexPath1 indexAtPosition:1];
    NSUInteger sectionIndex2 = [indexPath2 indexAtPosition:0];
    NSUInteger objectIndex2 = [indexPath2 indexAtPosition:1];
    
    NSUInteger sectionCount = [self countAllSections];
    if (sectionIndex1 >= sectionCount || sectionIndex2 >= sectionCount) {
        NSAssert(sectionIndex1 < sectionCount, @"Index path 1 section out of bounds!");
        NSAssert(sectionIndex2 < sectionCount, @"Index path 2 section out of bounds!");
        return;
    }
    
    NSUInteger objectCount1 = [self countObjectsInSectionAtIndex:sectionIndex1];
    NSUInteger objectCount2 = [self countObjectsInSectionAtIndex:sectionIndex2];
    if (objectIndex1 >= objectCount1 || objectIndex2 >= objectCount2) {
        NSAssert(objectIndex1 < objectCount1, @"Index path 1 row out of bounds!");
        NSAssert(objectIndex2 < objectCount2, @"Index path 2 row out of bounds!");
        return;
    }
    
    INTUMutableGroupedArraySectionContainer *sectionContainer1 = self.sectionContainers[sectionIndex1];
    INTUMutableGroupedArraySectionContainer *sectionContainer2 = self.sectionContainers[sectionIndex2];
    id object1 = sectionContainer1.objects[objectIndex1];
    sectionContainer1.mutableObjects[objectIndex1] = sectionContainer2.objects[objectIndex2];
    sectionContainer2.mutableObjects[objectIndex2] = object1;
    _mutations++;
}

#pragma mark Removing

/**
 Removes all objects and sections.
 Performance: O(n), where n is the total number of objects across all sections
 */
- (void)removeAllObjects
{
    [self.mutableSectionContainers removeAllObjects];
    _mutations++;
}

/**
 Removes the section and all objects in it.
 Performance: O(n), where n is the number of sections
 
 @param section The section to remove.
 */
- (void)removeSection:(id)section
{
    if (!section) {
        NSAssert(section, @"Section should not be nil.");
        return;
    }
    NSUInteger indexToRemove = [self indexOfSection:section];
    if (indexToRemove != NSNotFound) {
        [self removeSectionAtIndex:indexToRemove];
    }
}

/**
 Removes the section at the index and all objects in it.
 An exception will be raised if the index is out of bounds.
 Performance: O(n), where n is the number of sections
 
 @param index The index of the section to remove.
 */
- (void)removeSectionAtIndex:(NSUInteger)index
{
    if (index >= [self countAllSections]) {
        NSAssert(index < [self countAllSections], @"Index out of bounds!");
        return;
    }
    [self.mutableSectionContainers removeObjectAtIndex:index];
    _mutations++;
}

/**
 Removes all occurrences of the object across all sections. Empty sections will be removed.
 Performance: O(n), where n is the total number of objects across all sections
 
 @param object The object to remove.
 */
- (void)removeObject:(id)object
{
    if (!object) {
        NSAssert(object, @"Object should not be nil.");
        return;
    }
    NSMutableArray *arraySectionsToRemove = [NSMutableArray new];
    for (INTUMutableGroupedArraySectionContainer *sectionContainer in self.sectionContainers) {
        NSMutableArray *objectsArray = sectionContainer.mutableObjects;
        [objectsArray removeObject:object];
        if ([objectsArray count] == 0) {
            [arraySectionsToRemove addObject:sectionContainer];
        }
    }
    for (INTUGroupedArraySectionContainer *sectionContainer in arraySectionsToRemove) {
        [self.mutableSectionContainers removeObject:sectionContainer];
    }
    _mutations++;
}

/**
 Removes all occurrences of the object from the section. Empty sections will be removed.
 Performance: O(n+m), where n is the number of sections, and m is the number of objects in the section
 
 @param object The object to remove.
 @param section The section to remove the object from.
 */
- (void)removeObject:(id)object fromSection:(id)section
{
    if (!object || !section) {
        NSAssert(object, @"Object should not be nil.");
        NSAssert(section, @"Section should not be nil.");
        return;
    }
    NSMutableArray *objectsArray = [self _objectsArrayForSection:section withSectionIndexHint:NSNotFound];
    if (objectsArray == nil) {
        // Section does not exist
        return;
    }
    [objectsArray removeObject:object];
    if ([objectsArray count] == 0) {
        [self removeSection:section];
    }
    _mutations++;
}

/**
 Removes the object at the index from the section. Empty sections will be removed.
 An exception will be raised if the index is out of bounds.
 Performance: O(n+m), where n is the number of sections, and m is the number of objects in the section
 
 @param index The index of the object to remove.
 @param section The section to remove the object from.
 */
- (void)removeObjectAtIndex:(NSUInteger)index fromSection:(id)section
{
    if (!section) {
        NSAssert(section, @"Section should not be nil.");
        return;
    }
    NSMutableArray *objectsArray = [self _objectsArrayForSection:section withSectionIndexHint:NSNotFound];
    if (objectsArray == nil) {
        // Section does not exist
        return;
    }
    if (index >= [objectsArray count]) {
        NSAssert(index < [objectsArray count], @"Index out of bounds!");
        return;
    }
    [objectsArray removeObjectAtIndex:index];
    if ([objectsArray count] == 0) {
        [self removeSection:section];
    }
    _mutations++;
}

/**
 Removes the object at the index path. Empty sections will be removed.
 An exception will be raised if the index is out of bounds.
 Performance: O(n), where n is the number of objects in the section
 
 @param indexPath The index path of the object to remove.
 */
- (void)removeObjectAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath) {
        NSAssert(indexPath, @"Index path should not be nil.");
        return;
    }
    NSUInteger sectionIndex = [indexPath indexAtPosition:0];
    NSUInteger objectIndex = [indexPath indexAtPosition:1];
    if (sectionIndex >= [self countAllSections]) {
        NSAssert(sectionIndex < [self countAllSections], @"Section index out of bounds!");
        return;
    }
    INTUMutableGroupedArraySectionContainer *sectionContainer = self.sectionContainers[sectionIndex];
    NSMutableArray *objectsArray = sectionContainer.mutableObjects;
    if (objectIndex >= [objectsArray count]) {
        NSAssert(objectIndex < [objectsArray count], @"Row index out of bounds!");
        return;
    }
    [objectsArray removeObjectAtIndex:objectIndex];
    if ([objectsArray count] == 0) {
        [self removeSectionAtIndex:sectionIndex];
    }
    _mutations++;
}

#pragma mark Filtering

/**
 Evaluates the section & object predicates against all sections & objects and removes those that do not match. Empty sections will be removed.
 
 @param sectionPredicate The predicate to evaluate against the sections.
 @param objectPredicate The predicate to evaluate against the objects.
 */
- (void)filterUsingSectionPredicate:(NSPredicate *)sectionPredicate objectPredicate:(NSPredicate *)objectPredicate
{
    if (sectionPredicate || objectPredicate) {
        NSMutableArray *sectionContainersToRemove = [NSMutableArray new];
        for (INTUMutableGroupedArraySectionContainer *sectionContainer in self.sectionContainers) {
            if (sectionPredicate && [sectionPredicate evaluateWithObject:sectionContainer.section] == NO) {
                [sectionContainersToRemove addObject:sectionContainer];
            } else if (objectPredicate) {
                NSMutableArray *objectsArray = sectionContainer.mutableObjects;
                [objectsArray filterUsingPredicate:objectPredicate];
                if ([objectsArray count] == 0) {
                    [sectionContainersToRemove addObject:sectionContainer];
                }
            }
        }
        for (INTUGroupedArraySectionContainer *sectionContainer in sectionContainersToRemove) {
            [self.mutableSectionContainers removeObject:sectionContainer];
        }
    }
    _mutations++;
}

#pragma mark Sorting

/**
 Sorts the sections using the section comparator, and the objects in each section using the object comparator.
 
 @param sectionCmptr A comparator block used to sort sections, or nil if no section sorting is desired.
 @param objectCmptr A comparator block used to sort objects in each section, or nil if no object sorting is desired.
 */
- (void)sortUsingSectionComparator:(NSComparator)sectionCmptr objectComparator:(NSComparator)objectCmptr
{
    if (sectionCmptr) {
        [self.mutableSectionContainers sortUsingComparator:^NSComparisonResult(INTUGroupedArraySectionContainer *arraySection1, INTUGroupedArraySectionContainer *arraySection2) {
            return sectionCmptr(arraySection1.section, arraySection2.section);
        }];
    }
    if (objectCmptr) {
        for (INTUMutableGroupedArraySectionContainer *sectionContainer in self.sectionContainers) {
            [sectionContainer.mutableObjects sortUsingComparator:objectCmptr];
        }
    }
    _mutations++;
}

#pragma mark Internal Helper Methods

/**
 Returns the objects in the section, without copying the array. Passing an accurate hint for the section index
 will dramatically accelerate performance when there are a large number of sections, as it will avoid having to
 call -[self indexOfSection:] to find the section.
 Performance: O(1) assuming an accurate section index hint; otherwise O(n), where n is the number of sections
 
 @param section The section to get the objects of.
 @param sectionIndexHint An optional hint to the index of the section. (Pass NSNotFound to ignore the hint.)
 @return The mutable array of all the objects in the section, or nil if the section does not exist.
 */
- (NSMutableArray *)_objectsArrayForSection:(id)section withSectionIndexHint:(NSUInteger)sectionIndexHint
{
    if (sectionIndexHint != NSNotFound && sectionIndexHint < [self countAllSections]) {
        // Use the hint first to see if it correctly locates the section
        id sectionAtHint = [self sectionAtIndex:sectionIndexHint];
        if ([sectionAtHint isEqual:section]) {
            // The hint worked!
            INTUMutableGroupedArraySectionContainer *sectionContainer = self.sectionContainers[sectionIndexHint];
            return sectionContainer.mutableObjects;
        }
    }
    
    // Don't have a hint to use, or the hint was out of bounds, or the hint was wrong
    NSUInteger sectionIndex = [self indexOfSection:section];
    if (sectionIndex == NSNotFound) {
        return nil;
    } else {
        INTUMutableGroupedArraySectionContainer *sectionContainer = self.sectionContainers[sectionIndex];
        return sectionContainer.mutableObjects;
    }
}

@end
