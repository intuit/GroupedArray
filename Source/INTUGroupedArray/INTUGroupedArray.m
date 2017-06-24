//
//  INTUGroupedArray.m
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
#import "INTUGroupedArraySectionContainer.h"
#import "INTUMutableGroupedArray.h"
#import "INTUIndexPair.h"
#import "INTUGroupedArrayInternal.h"
#import "INTUMutableGroupedArrayInternal.h"

#pragma mark - INTUGroupedArraySectionEnumerator

@interface INTUGroupedArraySectionEnumerator : NSEnumerator <INTUGroupedArraySectionEnumerator>
{
@private
    /** The grouped array that is enumerated. */
    INTUGroupedArray *_groupedArray;
    /** Whether the enumeration should be done in reverse. */
    BOOL _reverse;
    /** Holds the internal state of the enumerator instance, so that successive calls to nextObject or fast enumeration loops
     continue to return objects sequentially in the correct order. */
    NSFastEnumerationState _internalState;
    /** The value that the mutations pointer points to, set before starting enumeration. This will be compared to the current
     value that the mutations pointer points to, to detect if the grouped array is mutated during enumeration. */
    unsigned long _mutationsValue;
}

/** Factory method to create a new section enumerator. */
+ (instancetype)sectionEnumeratorForGroupedArray:(INTUGroupedArray *)groupedArray reverse:(BOOL)reverse;

@end

@implementation INTUGroupedArraySectionEnumerator

+ (instancetype)sectionEnumeratorForGroupedArray:(INTUGroupedArray *)groupedArray reverse:(BOOL)reverse
{
    INTUGroupedArraySectionEnumerator *enumerator = [[self alloc] init];
    enumerator->_groupedArray = groupedArray;
    enumerator->_reverse = reverse;
    return enumerator;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    /* NSFastEnumerationState struct fields (the below constants are used when accessing the values in extra[] for readability) */
    //                                          state->state     0 the first call, 1 for all subsequent calls
    const int kNumberOfSectionsReturned = 0; // state->extra[0]  A running total of the number of sections returned
    const int kLastReturnedSectionIndex = 1; // state->extra[1]  The index of the last-returned section
    const int kTotalSectionCount        = 2; // state->extra[2]  The total section count
    
    NSUInteger numberOfSectionsToReturn;
    unsigned long currentSectionIndex;
    unsigned long totalSectionCount;
    
    // Point the mutationsPtr to the _mutations ivar to detect mutations during enumeration
    if (!_internalState.mutationsPtr) {
        unsigned long *mutationsPtr = [_groupedArray _mutationsPtr];
        _internalState.mutationsPtr = mutationsPtr;
        if (mutationsPtr) {
            _mutationsValue = *mutationsPtr;
        }
    }
    if (!state->mutationsPtr) {
        state->mutationsPtr = [_groupedArray _mutationsPtr];
    }
    
    if (_internalState.state && _internalState.mutationsPtr && (_mutationsValue != *_internalState.mutationsPtr)) {
        // Enumeration has started, and the mutations value has changed indicating that the grouped array was mutated
        NSAssert(nil, @"Collection <%@: %p> was mutated while being enumerated.", NSStringFromClass([_groupedArray class]), _groupedArray);
        return 0;
    }
    
    if (state != &_internalState) {
        // If the state parameter is not the same as the _internalState ivar state (which tracks the real state of the enumeration),
        // make sure the state parameter's state is set to 1 every call to indicate enumeration has started
        state->state = 1;
    }
    
    if (_internalState.state == 0) {
        // It's the first call, do initial configuration of the state
        _internalState.state = 1;
        
        totalSectionCount = [_groupedArray countAllSections];
        _internalState.extra[kTotalSectionCount] = totalSectionCount;
        
        // If there are no sections, we're done
        if (totalSectionCount == 0) {
            return 0;
        }
        
        // Set the initial section index
        if (_reverse) {
            currentSectionIndex = totalSectionCount - 1;
        } else {
            currentSectionIndex = 0;
        }
    } else {
        // Not the first call, first check to see if we're done (having enumerated all sections)
        totalSectionCount = _internalState.extra[kTotalSectionCount];
        unsigned long numberOfSectionsReturned = _internalState.extra[kNumberOfSectionsReturned];
        if (numberOfSectionsReturned == totalSectionCount) {
            return 0;
        }
        
        // Still have at least 1 more section to return, figure out the index for it
        unsigned long lastReturnedSectionIndex = _internalState.extra[kLastReturnedSectionIndex];
        if (_reverse) {
            currentSectionIndex = lastReturnedSectionIndex - 1;
        } else {
            currentSectionIndex = lastReturnedSectionIndex + 1;
        }
    }
    
    // We can only return 1 section at a time when using fast enumeration on an enumerator, to make sure that if the user breaks out of the
    // fast enumeration loop early, and then calls nextObject on the enumerator, that it will return the correct next section. (If we returned
    // more than 1 section, it's possible the user could break out of the loop before seeing all the sections in the buffer, and these sections
    // will be "lost" from the enumeration.)
    numberOfSectionsToReturn = MIN(len, 1);
    
    // Prepare the sections to return
    for (NSUInteger i = 0; i < numberOfSectionsToReturn; i++) {
        if (_reverse) {
            buffer[i] = [_groupedArray sectionAtIndex:currentSectionIndex - i];
        } else {
            buffer[i] = [_groupedArray sectionAtIndex:currentSectionIndex + i];
        }
    }
    state->itemsPtr = &buffer[0]; // only the itemsPtr for the state passed in as the parameter matters (the _internalState one is not used)
    
    // Store the section index for this section that we're about to return
    if (_reverse) {
        _internalState.extra[kLastReturnedSectionIndex] = currentSectionIndex - numberOfSectionsToReturn + 1;
    } else {
        _internalState.extra[kLastReturnedSectionIndex] = currentSectionIndex + numberOfSectionsToReturn - 1;
    }
    
    _internalState.extra[kNumberOfSectionsReturned] += numberOfSectionsToReturn; // increment the counter of sections returned
    return numberOfSectionsToReturn;
}

- (id)nextObject
{
    return [self nextSection];
}

- (NSArray *)allObjects
{
    return [self allSections];
}

- (id)nextSection
{
    id buffer;
    id __unsafe_unretained unsafeBuffer = buffer;
    NSUInteger returnedCount = [self countByEnumeratingWithState:&_internalState objects:&unsafeBuffer count:1];
    return (returnedCount == 0) ? nil : _internalState.itemsPtr[0];
}

- (NSArray *)allSections
{
    NSMutableArray *sections = [NSMutableArray new];
    for (id section in self) {
        [sections addObject:section];
    }
    return sections;
}

@end


#pragma mark - INTUGroupedArrayObjectEnumerator

@interface INTUGroupedArrayObjectEnumerator : NSEnumerator
{
    @private
    /** The grouped array that is enumerated. */
    INTUGroupedArray *_groupedArray;
    /** Whether the enumeration should be done in reverse. */
    BOOL _reverse;
    /** Holds the internal state of the enumerator instance, so that successive calls to nextObject or fast enumeration loops
        continue to return objects sequentially in the correct order. */
    NSFastEnumerationState _internalState;
    /** The value that the mutations pointer points to, set before starting enumeration. This will be compared to the current
        value that the mutations pointer points to, to detect if the grouped array is mutated during enumeration. */
    unsigned long _mutationsValue;
}

/** Factory method to create a new object enumerator. */
+ (instancetype)objectEnumeratorForGroupedArray:(INTUGroupedArray *)groupedArray reverse:(BOOL)reverse;

@end

@implementation INTUGroupedArrayObjectEnumerator

+ (instancetype)objectEnumeratorForGroupedArray:(INTUGroupedArray *)groupedArray reverse:(BOOL)reverse
{
    INTUGroupedArrayObjectEnumerator *enumerator = [[self alloc] init];
    enumerator->_groupedArray = groupedArray;
    enumerator->_reverse = reverse;
    return enumerator;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    /* NSFastEnumerationState struct fields (the below constants are used when accessing the values in extra[] for readability) */
    //                                          state->state     0 the first call, 1 for all subsequent calls
    const int kNumberOfObjectsReturned  = 0; // state->extra[0]  A running total of the number of objects returned
    const int kLastReturnedSectionIndex = 1; // state->extra[1]  The index of the section for the last-returned object
    const int kLastReturnedObjectIndex  = 2; // state->extra[2]  The index of the last-returned object (within its section)
    const int kNumberOfObjectsInSection = 3; // state->extra[3]  The object count of the current section
    const int kTotalObjectCount         = 4; // state->extra[4]  The total object count
    
    NSUInteger numberOfObjectsToReturn;
    unsigned long currentSectionIndex;
    unsigned long currentObjectIndex;
    unsigned long numberOfObjectsInSection;
    
    // Point the mutationsPtr to the _mutations ivar to detect mutations during enumeration
    if (!_internalState.mutationsPtr) {
        unsigned long *mutationsPtr = [_groupedArray _mutationsPtr];
        _internalState.mutationsPtr = mutationsPtr;
        if (mutationsPtr) {
            _mutationsValue = *mutationsPtr;
        }
    }
    if (!state->mutationsPtr) {
        state->mutationsPtr = [_groupedArray _mutationsPtr];
    }
    
    if (_internalState.state && _internalState.mutationsPtr && (_mutationsValue != *_internalState.mutationsPtr)) {
        // Enumeration has started, and the mutations value has changed indicating that the grouped array was mutated
        NSAssert(nil, @"Collection <%@: %p> was mutated while being enumerated.", NSStringFromClass([_groupedArray class]), _groupedArray);
        return 0;
    }
    
    if (state != &_internalState) {
        // If the state parameter is not the same as the _internalState ivar state (which tracks the real state of the enumeration),
        // make sure the state parameter's state is set to 1 every call to indicate enumeration has started
        state->state = 1;
    }
    
    if (_internalState.state == 0) {
        // It's the first call, do initial configuration of the state
        _internalState.state = 1;
        
        unsigned long totalObjectCount = [_groupedArray countAllObjects];
        _internalState.extra[kTotalObjectCount] = totalObjectCount;
        
        // If there are no objects, we're done
        if (totalObjectCount == 0) {
            return 0;
        }
        
        // There is at least one object, so we know there is also at least one section
        unsigned long sectionCount = 0;
        if (_reverse) {
            sectionCount = [_groupedArray countAllSections];
            numberOfObjectsInSection = [_groupedArray countObjectsInSectionAtIndex:sectionCount - 1];
        } else {
            numberOfObjectsInSection = [_groupedArray countObjectsInSectionAtIndex:0];
        }
        _internalState.extra[kNumberOfObjectsInSection] = numberOfObjectsInSection;
        
        // Set the initial section and object indicies
        if (_reverse) {
            currentSectionIndex = sectionCount - 1;
            currentObjectIndex = numberOfObjectsInSection - 1;
        } else {
            currentSectionIndex = 0;
            currentObjectIndex = 0;
        }
    } else {
        // Not the first call, first check to see if we're done (having enumerated all objects)
        unsigned long numberOfObjectsReturned = _internalState.extra[kNumberOfObjectsReturned];
        unsigned long totalObjectCount = _internalState.extra[kTotalObjectCount];
        if (numberOfObjectsReturned == totalObjectCount) {
            return 0;
        }
        
        // Still have at least 1 more object to return, figure out the index path for it
        unsigned long lastReturnedObjectIndex = _internalState.extra[kLastReturnedObjectIndex];
        numberOfObjectsInSection = _internalState.extra[kNumberOfObjectsInSection];
        if (_reverse) {
            if (lastReturnedObjectIndex == 0) {
                // We need to go to the previous section
                currentSectionIndex = _internalState.extra[kLastReturnedSectionIndex] - 1;
                numberOfObjectsInSection = [_groupedArray countObjectsInSectionAtIndex:currentSectionIndex];
                currentObjectIndex = numberOfObjectsInSection - 1;
            } else {
                // Still more objects in the current section
                currentSectionIndex = _internalState.extra[kLastReturnedSectionIndex];
                currentObjectIndex = _internalState.extra[kLastReturnedObjectIndex] - 1;
            }
        } else {
            if (lastReturnedObjectIndex == numberOfObjectsInSection - 1) {
                // We need to go to the next section
                currentSectionIndex = _internalState.extra[kLastReturnedSectionIndex] + 1;
                currentObjectIndex = 0;
                numberOfObjectsInSection = [_groupedArray countObjectsInSectionAtIndex:currentSectionIndex];
                _internalState.extra[kNumberOfObjectsInSection] = numberOfObjectsInSection;
            } else {
                // Still more objects in the current section
                currentSectionIndex = _internalState.extra[kLastReturnedSectionIndex];
                currentObjectIndex = _internalState.extra[kLastReturnedObjectIndex] + 1;
            }
        }
    }
    
    // We can only return 1 object at a time when using fast enumeration on an enumerator, to make sure that if the user breaks out of the
    // fast enumeration loop early, and then calls nextObject on the enumerator, that it will return the correct next object. (If we returned
    // more than 1 object, it's possible the user could break out of the loop before seeing all the objects in the buffer, and these objects
    // will be "lost" from the enumeration.)
    numberOfObjectsToReturn = MIN(len, 1);
    
    // Prepare the objects to return
    for (NSUInteger i = 0; i < numberOfObjectsToReturn; i++) {
        if (_reverse) {
            buffer[i] = [_groupedArray _objectAtIndexPair:INTUIndexPairMake(currentSectionIndex, currentObjectIndex - i)];
        } else {
            buffer[i] = [_groupedArray _objectAtIndexPair:INTUIndexPairMake(currentSectionIndex, currentObjectIndex + i)];
        }
    }
    state->itemsPtr = &buffer[0]; // only the itemsPtr for the state passed in as the parameter matters (the _internalState one is not used)
    
    // Store the section index and object index for this object that we're about to return
    _internalState.extra[kLastReturnedSectionIndex] = currentSectionIndex;
    if (_reverse) {
        _internalState.extra[kLastReturnedObjectIndex] = currentObjectIndex - numberOfObjectsToReturn + 1;
    } else {
        _internalState.extra[kLastReturnedObjectIndex] = currentObjectIndex + numberOfObjectsToReturn - 1;
    }
    
    _internalState.extra[kNumberOfObjectsReturned] += numberOfObjectsToReturn; // increment the counter of objects returned
    return numberOfObjectsToReturn;
}

- (id)nextObject
{
    id buffer;
    id __unsafe_unretained unsafeBuffer = buffer;
    NSUInteger returnedCount = [self countByEnumeratingWithState:&_internalState objects:&unsafeBuffer count:1];
    return (returnedCount == 0) ? nil : _internalState.itemsPtr[0];
}

- (NSArray *)allObjects
{
    NSMutableArray *objects = [NSMutableArray new];
    for (id object in self) {
        [objects addObject:object];
    }
    return objects;
}

@end


#pragma mark - INTUGroupedArray

@interface GA__INTU_GENERICS(INTUGroupedArray, SectionType, ObjectType) ()

// An array of INTUGroupedArraySectionContainer objects, which serves as the backing store for the grouped array.
@property (nonatomic, strong) GA__INTU_GENERICS(NSArray, GA__INTU_GENERICS(INTUGroupedArraySectionContainer, SectionType, ObjectType) *) *sectionContainers;

@end

@implementation INTUGroupedArray

/**
 Helper method to create an index path when the UIKit category on NSIndexPath is not available.
 
 @param row The row index.
 @param section The section index.
 @return An index path with the given row and section indices.
 */
+ (NSIndexPath *)indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section
{
    NSUInteger indexArr[] = {section, row};
    return [NSIndexPath indexPathWithIndexes:indexArr length:2];
}

/**
 Returns the memory address of the _mutations instance variable.
 */
- (unsigned long *)_mutationsPtr
{
    return &_mutations;
}

#pragma mark Class Factory Methods

/**
 Creates and returns a new empty grouped array.
 
 @return A new empty grouped array.
 */
+ (instancetype)groupedArray
{
    return [self new];
}

/**
 Creates and returns a new grouped array with a single section ([NSObject new]) containing the objects in the array.
 Performance: O(n), where n is the number of objects
 
 @param array The array of objects to add to the grouped array.
 @return A new grouped array with one section ([NSObject new]) containing the objects in the array,
         or a new empty grouped array (with no sections or objects) if the array is nil or empty.
 */
+ (instancetype)groupedArrayWithArray:(NSArray *)array
{
    INTUGroupedArray *groupedArray = [self new];
    if ([array count] > 0) {
        INTUGroupedArraySectionContainer *sectionContainer = [INTUGroupedArraySectionContainer sectionContainerWithSection:[NSObject new]];
        sectionContainer.objects = [array copy];
        groupedArray.sectionContainers = @[sectionContainer];
    }
    return groupedArray;
}

/**
 Creates and returns a grouped array from the literal syntax.
 
 An exception will be raised and nil returned if the literal is nil or invalid.
 Requirements include: sections must be unique, there must be an array of objects for every section,
 and the array of objects for each section must always contain at least one object (cannot be empty).
 
 Syntax:
        @[
            id section1, @[ id object1A, id object1B, ... ],
            id section2, @[ id object2A, id object2B, ... ],
            ...
         ]
 
 @return A new grouped array from the literal syntax, or nil if the literal is invalid.
 */
+ (instancetype)literal:(NSArray *)groupedArrayLiteral
{
    if (!groupedArrayLiteral) {
        NSAssert(groupedArrayLiteral, @"Grouped array literal cannot be nil.");
        return nil;
    }
    BOOL literalContainsEvenNumberOfElements = ([groupedArrayLiteral count] % 2 == 0);
    if (literalContainsEvenNumberOfElements == NO) {
        NSAssert(literalContainsEvenNumberOfElements, @"Grouped array literal is invalid. There must be an array of objects for every section.");
        return nil;
    }
    INTUGroupedArray *groupedArray = [self new];
    NSMutableArray *sectionContainers = [NSMutableArray new];
    BOOL expectingObjectsArray = NO;
    for (id element in groupedArrayLiteral) {
        if (expectingObjectsArray) {
            if ([element isKindOfClass:[NSArray class]]) {
                NSArray *objectsArray = element;
                INTUGroupedArraySectionContainer *sectionContainer = [sectionContainers lastObject];
                if ([objectsArray count] > 0) {
                    sectionContainer.objects = [[NSMutableArray alloc] initWithArray:element copyItems:NO];
                } else {
                    NSAssert([objectsArray count] > 0, @"Grouped array literal is invalid. The array of objects in a section must not be empty. Section: %@", sectionContainer.section);
                    return nil;
                }
            } else {
                NSAssert([element isKindOfClass:[NSArray class]], @"Grouped array literal is invalid. Expected an array of objects, but encountered the following object instead: %@", element);
                return nil;
            }
        } else {
            [sectionContainers addObject:[INTUGroupedArraySectionContainer sectionContainerWithSection:element]];
        }
        expectingObjectsArray = !expectingObjectsArray;
    }
    groupedArray.sectionContainers = sectionContainers;
    return groupedArray;
}

#pragma mark Initializers

/**
 Designated initializer.
 */
- (instancetype)init
{
    self = [super init];
    if (self) {
        _sectionContainers = [NSArray new];
    }
    return self;
}

/**
 Creates and returns a new grouped array with the contents of a given grouped array.
 The sections and objects will not be copied.
 
 @param groupedArray A grouped array containing the sections & objects with which to initialize the new grouped array.
 @return A new grouped array with the contents of the given grouped array.
 */
- (instancetype)initWithGroupedArray:(INTUGroupedArray *)groupedArray
{
    return [self initWithGroupedArray:groupedArray copyItems:NO];
}

/**
 Creates and returns a new grouped array with the contents of a given grouped array, optionally copying the sections & objects.
 
 @param groupedArray A grouped array containing the sections & objects with which to initialize the new grouped array.
 @param copyItems Whether the sections & objects in the grouped array should be copied.
 @return A new grouped array with the contents of the given grouped array.
 */
- (instancetype)initWithGroupedArray:(INTUGroupedArray *)groupedArray copyItems:(BOOL)copyItems
{
    __typeof(self) newGroupedArray = [[[self class] alloc] init];
    if (copyItems) {
        // Copy the sections & objects in the grouped array into the new one
        NSMutableArray *newSectionContainers = [NSMutableArray array];
        for (INTUGroupedArraySectionContainer *sectionContainer in groupedArray.sectionContainers) {
            [newSectionContainers addObject:[[INTUGroupedArraySectionContainer alloc] initWithSectionContainer:sectionContainer copyItems:YES]];
        }
        newGroupedArray.sectionContainers = newSectionContainers;
    } else {
        // Perform a shallow copy of the grouped array, without copying the sections & objects
        // The array of sectionContainers is has its INTUGroupedArraySectionContainer objects copied, but this is only a one-level-deep copy,
        // so the sections & objects in the grouped array will NOT be copied!
        newGroupedArray.sectionContainers = [[NSMutableArray alloc] initWithArray:groupedArray.sectionContainers copyItems:YES];
    }
    return newGroupedArray;
}

#pragma mark NSCoding Protocol Methods

/**
 Decodes the grouped array.
 */
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self) {
        _sectionContainers = [aDecoder decodeObjectForKey:@"sectionContainers"];
    }
    return self;
}

/**
 Encodes the grouped array.
 */
- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (_sectionContainers) {
        [aCoder encodeObject:_sectionContainers forKey:@"sectionContainers"];
    }
}

#pragma mark NSCopying Protocol Method

/**
 Returns a reference to the same instance, which is a valid copy since this class is immutable.
 */
- (id)copyWithZone:(NSZone *)zone
{
    // No need to do any copying since this is an immutable class.
    return self;
}

/**
 Returns a mutable copy of this grouped array.
 The sections and objects contained in the grouped array are not deep copied.
 */
- (id)mutableCopyWithZone:(NSZone *)zone
{
    INTUMutableGroupedArray *copy = [[INTUMutableGroupedArray allocWithZone:zone] init];
    for (INTUGroupedArraySectionContainer *sectionContainer in self.sectionContainers) {
        [copy.mutableSectionContainers addObject:[sectionContainer mutableCopy]];
    }
    return copy;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ {\n\t%@\n}", [super description], [self descriptionForSections]];
}

/**
 Helper method that returns a string representing a description of the sections in the grouped array.
 */
- (NSString *)descriptionForSections
{
    NSMutableString *sectionsDescription = [NSMutableString new];
    NSUInteger numberOfSections = [self countAllSections];
    for (NSUInteger sectionIdx = 0; sectionIdx < numberOfSections; sectionIdx++) {
        id section = [self sectionAtIndex:sectionIdx];
        [sectionsDescription appendFormat:@"%@ : [%@]", section, [self descriptionForObjectsInSectionAtIndex:sectionIdx]];
        if (sectionIdx + 1 < numberOfSections) {
            [sectionsDescription appendString:@",\n\t"];
        }
    }
    return sectionsDescription;
}

/**
 Helper method that returns a string representing a description of the objects in the section in the grouped array.
 */
- (NSString *)descriptionForObjectsInSectionAtIndex:(NSUInteger)sectionIdx
{
    NSMutableString *objectsDescription = [NSMutableString new];
    NSUInteger numberOfObjectsInSection = [self countObjectsInSectionAtIndex:sectionIdx];
    for (NSUInteger objectIdx = 0; objectIdx < numberOfObjectsInSection; objectIdx++) {
        id object = [self _objectAtIndexPair:INTUIndexPairMake(sectionIdx, objectIdx)];
        [objectsDescription appendFormat:@"%@", object];
        if (objectIdx + 1 < numberOfObjectsInSection) {
            [objectsDescription appendString:@", "];
        }
    }
    return objectsDescription;
}

#pragma mark NSFastEnumeration Protocol Method

/**
 Implement to support fast enumeration.
 */
- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    /* NSFastEnumerationState struct fields (the below constants are used when accessing the values in extra[] for readability) */
    //                                          state->state     0 the first call, 1 for all subsequent calls
    const int kNumberOfObjectsReturned  = 0; // state->extra[0]  A running total of the number of objects returned
    const int kLastReturnedSectionIndex = 1; // state->extra[1]  The index of the section for the last-returned object
    const int kLastReturnedObjectIndex  = 2; // state->extra[2]  The index of the last-returned object (within its section)
    const int kNumberOfObjectsInSection = 3; // state->extra[3]  The object count of the current section
    const int kTotalObjectCount         = 4; // state->extra[4]  The total object count

    NSUInteger numberOfObjectsToReturn;
    unsigned long currentSectionIndex;
    unsigned long currentObjectIndex;
    unsigned long numberOfObjectsInSection;
    
    if (state->state == 0) {
        // It's the first call, do initial configuration of the state
        state->state = 1;
        
        // Point the mutationsPtr to the _mutations ivar to detect mutations during enumeration
        state->mutationsPtr = &_mutations;
        
        unsigned long totalObjectCount = [self countAllObjects];
        state->extra[kTotalObjectCount] = totalObjectCount;
        
        // If there are no objects, we're done
        if (totalObjectCount == 0) {
            return 0;
        }
        
        // There is at least one object, so we know there is also at least one section
        numberOfObjectsInSection = [self countObjectsInSectionAtIndex:0];
        state->extra[kNumberOfObjectsInSection] = numberOfObjectsInSection;
        
        // Set the initial section and object indicies to 0
        currentSectionIndex = 0;
        currentObjectIndex = 0;
    } else {
        // Not the first call, first check to see if we're done (having enumerated all objects)
        unsigned long numberOfObjectsReturned = state->extra[kNumberOfObjectsReturned];
        unsigned long totalObjectCount = state->extra[kTotalObjectCount];
        if (numberOfObjectsReturned == totalObjectCount) {
            return 0;
        }
        
        // Still have at least 1 more object to return, figure out the index path for it
        unsigned long lastReturnedObjectIndex = state->extra[kLastReturnedObjectIndex];
        numberOfObjectsInSection = state->extra[kNumberOfObjectsInSection];
        if (lastReturnedObjectIndex == numberOfObjectsInSection - 1) {
            // We need to go to the next section
            currentSectionIndex = state->extra[kLastReturnedSectionIndex] + 1;
            currentObjectIndex = 0;
            numberOfObjectsInSection = [self countObjectsInSectionAtIndex:currentSectionIndex];
            state->extra[kNumberOfObjectsInSection] = numberOfObjectsInSection;
        } else {
            // Still more objects in the current section
            currentSectionIndex = state->extra[kLastReturnedSectionIndex];
            currentObjectIndex = state->extra[kLastReturnedObjectIndex] + 1;
        }
    }
    
    // We'll return as many objects as: will fit in the buffer OR have not yet been returned from this section, whichever is less
    numberOfObjectsToReturn = MIN(len, numberOfObjectsInSection - currentObjectIndex);
    
    // Prepare the objects to return
    for (NSUInteger i = 0; i < numberOfObjectsToReturn; i++) {
        buffer[i] = [self _objectAtIndexPair:INTUIndexPairMake(currentSectionIndex, currentObjectIndex + i)];
    }
    state->itemsPtr = &buffer[0];
    
    // Store the section index and object index for this object that we're about to return
    state->extra[kLastReturnedSectionIndex] = currentSectionIndex;
    state->extra[kLastReturnedObjectIndex] = currentObjectIndex + numberOfObjectsToReturn - 1;
    
    state->extra[kNumberOfObjectsReturned] += numberOfObjectsToReturn; // increment the counter of objects returned
    return numberOfObjectsToReturn;
}

#pragma mark Accessing Sections

/**
 Returns the section at the index.
 An exception will be raised if the index is out of bounds.
 Performance: O(1)
 
 @param index The index of the section to return.
 @return The section at the index, or nil if the index is out of bounds.
 */
- (id)sectionAtIndex:(NSUInteger)index
{
    if (index >= [self.sectionContainers count]) {
        NSAssert(index < [self.sectionContainers count], @"Index out of bounds!");
        return nil;
    }
    INTUGroupedArraySectionContainer *sectionContainer = self.sectionContainers[index];
    return sectionContainer.section;
}

/**
 Returns the number of sections.
 Performance: O(1)
 
 @return The number of sections in the grouped array.
 */
- (NSUInteger)countAllSections
{
    return [self.sectionContainers count];
}

/**
 Returns an array of all the sections.
 Performance: O(n), where n is the number of sections
 
 @return A new array of all the sections in the grouped array.
 */
- (NSArray *)allSections
{
    NSMutableArray *allSections = [NSMutableArray array];
    NSUInteger sectionCount = [self countAllSections];
    for (NSUInteger i = 0; i < sectionCount; i++) {
        [allSections addObject:[self sectionAtIndex:i]];
    }
    return allSections;
}

/**
 Returns whether the section exists.
 Performance: O(n), where n is the number of sections
 
 @param section The section to test for.
 @return Whether or not the section exists in the grouped array.
 */
- (BOOL)containsSection:(id)section
{
    return [self indexOfSection:section] != NSNotFound;
}

/**
 Returns the index for the section.
 Performance: O(n), where n is the number of sections
 
 @param section The section to locate.
 @return The index of the section in the grouped array, or NSNotFound if the section does not exist.
 */
- (NSUInteger)indexOfSection:(id)section
{
    if (!section) {
        NSAssert(section, @"Section should not be nil.");
        return NSNotFound;
    }
    
    // Scan the array of sections to find the one we need
    NSUInteger sectionCount = [self countAllSections];
    for (NSUInteger i = 0; i < sectionCount; i++) {
        if ([section isEqual:[self sectionAtIndex:i]]) {
            return i;
        }
    }
    return NSNotFound;
}

#pragma mark Accessing Objects

/**
 Returns the object at the index in the section.
 An exception will be raised if the index is out of bounds.
 Performance: O(n), where n is the number of sections
 
 @param index The index of the desired object in its section.
 @param section The section of the desired object.
 @return The object at the index in the section, or nil if the section does not exist or the index is out of bounds.
 */
- (id)objectAtIndex:(NSUInteger)index inSection:(id)section
{
    if (!section) {
        NSAssert(section, @"Section should not be nil.");
        return nil;
    }
    INTUIndexPair indexPair = INTUIndexPairMake([self indexOfSection:section], index);
    return [self _objectAtIndexPair:indexPair];
}

/**
 Returns the object at the index path.
 An exception will be raised if the index path is out of bounds.
 Performance: O(1)
 
 @param indexPath The index path of the object.
 @return The object at the index path, or nil if the index path is out of bounds.
 */
- (id)objectAtIndexPath:(NSIndexPath *)indexPath
{
    if (!indexPath) {
        NSAssert(indexPath, @"Index path should not be nil.");
        return nil;
    }
    
    return [self _objectAtIndexPair:INTUIndexPairConvert(indexPath)];
}

/**
 An internally exposed variant of objectAtIndexPath that takes an INTUIndexPair instead of NSIndexPath.
 This method may be called directly instead of the NSIndexPath variant in order to avoid the overhead of
 instantiating many NSIndexPath objects (e.g. during fast enumeration).
 Performance: O(1)
 
 An exception will be raised if the index pair is out of bounds.
 
 @param indexPair The index pair of the object.
 @return The object at the index pair, or nil if the index pair is out of bounds.
 */
- (id)_objectAtIndexPair:(INTUIndexPair)indexPair
{
    if (indexPair.sectionIndex >= [self.sectionContainers count]) {
        NSAssert(indexPair.sectionIndex < [self.sectionContainers count], @"Index out of bounds!");
        return nil;
    }
    INTUGroupedArraySectionContainer *sectionContainer = self.sectionContainers[indexPair.sectionIndex];
    NSArray *objectsInSection = sectionContainer.objects;
    if (indexPair.objectIndex >= [objectsInSection count]) {
        NSAssert(indexPair.objectIndex < [objectsInSection count], @"Index out of bounds!");
        return nil;
    }
    return objectsInSection[indexPair.objectIndex];
}

/**
 Returns the first object in the first section.
 Performance: O(1)
 
 @return The first object in the first section, or nil if the grouped array is empty.
 */
- (id)firstObject
{
    if ([self countAllObjects] == 0) {
        return nil;
    }
    return [self _objectAtIndexPair:INTUIndexPairMake(0, 0)];
}

/**
 Returns the last object in the last section.
 Performance: O(1)
 
 @return The last object in the last section, or nil if the grouped array is empty.
 */
- (id)lastObject
{
    if ([self countAllObjects] == 0) {
        return nil;
    }
    NSUInteger lastSectionIndex = [self countAllSections] - 1;
    NSUInteger lastObjectIndex = [self countObjectsInSectionAtIndex:lastSectionIndex] - 1;
    return [self _objectAtIndexPair:INTUIndexPairMake(lastSectionIndex, lastObjectIndex)];
}

/**
 Returns whether the object exists in any section.
 Performance: O(n), where n is the total number of objects across all sections
 
 @param object The object to test for.
 @return Whether or not the object exists in the grouped array.
 */
- (BOOL)containsObject:(id)object
{
    return [self indexPathOfObject:object] != nil;
}

/**
 Returns the index path of the first instance of the object across all sections.
 Performance: O(n), where n is the total number of objects across all sections
 
 @param object The object to locate.
 @return The index path of the first instance of the object, or nil if the object does not exist.
 */
- (NSIndexPath *)indexPathOfObject:(id)object
{
    if (!object) {
        NSAssert(object, @"Object should not be nil.");
        return nil;
    }
    
    // Scan the grouped array to find the object
    NSUInteger sectionCount = [self countAllSections];
    for (NSUInteger sectionIdx = 0; sectionIdx < sectionCount; sectionIdx++) {
        NSUInteger objectCount = [self countObjectsInSectionAtIndex:sectionIdx];
        for (NSUInteger objectIdx = 0; objectIdx < objectCount; objectIdx++) {
            if ([object isEqual:[self _objectAtIndexPair:INTUIndexPairMake(sectionIdx, objectIdx)]]) {
                return [INTUGroupedArray indexPathForRow:objectIdx inSection:sectionIdx];
            }
        }
    }
    return nil;
}

/**
 Returns whether the object exists in the section.
 Performance: O(n+m), where n is the number of sections, and m is the number of objects in the section
 
 @param object The object to test for.
 @param section The section to test for the object in.
 @return Whether or not the object exists in the section of the grouped array.
 */
- (BOOL)containsObject:(id)object inSection:(id)section
{
    return [self indexOfObject:object inSection:section] != NSNotFound;
}

/**
 Returns the index of the first instance of the object in the section.
 Performance: O(n+m), where n is the number of sections, and m is the number of objects in the section
 
 @param object The object to locate.
 @param section The section to locate the object in.
 @return The index of the first instance of the object in the section, or NSNotFound if the object does not exist in the section.
 */
- (NSUInteger)indexOfObject:(id)object inSection:(id)section
{
    if (!object || !section) {
        NSAssert(object, @"Object should not be nil.");
        NSAssert(section, @"Section should not be nil.");
        return NSNotFound;
    }
    
    NSUInteger sectionIndex = [self indexOfSection:section];
    if (sectionIndex == NSNotFound) {
        return NSNotFound;
    }
    
    NSUInteger objectCount = [self countObjectsInSectionAtIndex:sectionIndex];
    for (NSUInteger objectIndex = 0; objectIndex < objectCount; objectIndex++) {
        if ([[self _objectAtIndexPair:INTUIndexPairMake(sectionIndex, objectIndex)] isEqual:object]) {
            return objectIndex;
        }
    }
    return NSNotFound;
}

/**
 Returns the number of objects in the section.
 Performance: O(n), where n is the number of sections
 
 @param section The section to count the number of objects in.
 @return The number of objects in the section, or zero if the section does not exist.
 */
- (NSUInteger)countObjectsInSection:(id)section
{
    if (!section) {
        NSAssert(section, @"Section should not be nil.");
        return 0;
    }
    NSUInteger sectionIndex = [self indexOfSection:section];
    if (sectionIndex == NSNotFound) {
        return 0;
    }
    return [self countObjectsInSectionAtIndex:sectionIndex];
}

/**
 Returns the number of objects in the section at the index.
 An exception will be raised if the index is out of bounds.
 Performance: O(1)
 
 @param index The index of the section to count the number of objects in.
 @return The number of objects in the section at the index, or 0 if the index is out of bounds.
 */
- (NSUInteger)countObjectsInSectionAtIndex:(NSUInteger)index
{
    if (index >= [self.sectionContainers count]) {
        NSAssert(index < [self.sectionContainers count], @"Index out of bounds!");
        return 0;
    }
    INTUGroupedArraySectionContainer *sectionContainer = self.sectionContainers[index];
    return [sectionContainer.objects count];
}

/**
 Returns the objects in the section.
 Performance: O(n+m), where n is the number of sections, and m is the number of objects in the section
 
 @param section The section to get the objects of.
 @return A new array of all the objects in the section, or nil if the section does not exist.
 */
- (NSArray *)objectsInSection:(id)section
{
    if (!section) {
        NSAssert(section, @"Section should not be nil.");
        return nil;
    }
    
    NSUInteger sectionIndex = [self indexOfSection:section];
    if (sectionIndex == NSNotFound) {
        return nil;
    }
    return [self objectsInSectionAtIndex:sectionIndex];
}

/**
 Returns the objects in the section at the index.
 An exception will be raised if the index is out of bounds.
 Performance: O(n), where n is the number of objects in the section
 
 @param index The index of the section to get the objects of.
 @return A new array of all the objects in the section, or nil if the index is out of bounds.
 */
- (NSArray *)objectsInSectionAtIndex:(NSUInteger)index
{
    if (index >= [self countAllSections]) {
        NSAssert(index < [self countAllSections], @"Index out of bounds!");
        return nil;
    }
    
    NSUInteger objectCount = [self countObjectsInSectionAtIndex:index];
    NSMutableArray *objectsInSection = [NSMutableArray arrayWithCapacity:objectCount];
    for (NSUInteger objectIdx = 0; objectIdx < objectCount; objectIdx++) {
        [objectsInSection addObject:[self _objectAtIndexPair:INTUIndexPairMake(index, objectIdx)]];
    }
    return objectsInSection;
}

/**
 Returns the total number of objects in all sections.
 Performance: O(n), where n is the number of sections
 
 @return The number of objects in all sections of the grouped array.
 */
- (NSUInteger)countAllObjects
{
    NSUInteger count = 0;
    NSUInteger sectionCount = [self countAllSections];
    for (NSUInteger i = 0; i < sectionCount; i++) {
        count += [self countObjectsInSectionAtIndex:i];
    }
    return count;
}

/**
 Returns an array of all objects in all sections.
 Performance: O(n), where n is the total number of objects across all sections
 
 @return A new array of all objects in all sections of the grouped array.
 */
- (NSArray *)allObjects
{
    NSMutableArray *allObjects = [NSMutableArray array];
    NSUInteger sectionCount = [self countAllSections];
    for (NSUInteger sectionIdx = 0; sectionIdx < sectionCount; sectionIdx++) {
        NSUInteger objectCount = [self countObjectsInSectionAtIndex:sectionIdx];
        for (NSUInteger objectIdx = 0; objectIdx < objectCount; objectIdx++) {
            [allObjects addObject:[self _objectAtIndexPair:INTUIndexPairMake(sectionIdx, objectIdx)]];
        }
    }
    return allObjects;
}

/**
 Executes the block for each section in the grouped array.
 
 @param block A block taking three parameters:
                id section: The section
                NSUInteger index: the index of the section
                BOOL *stop: a pointer to a BOOL which will stop the enumeration if set to YES
 */
- (void)enumerateSectionsUsingBlock:(void (^)(id section, NSUInteger index, BOOL *stop))block
{
    [self enumerateSectionsWithOptions:0 usingBlock:block];
}

/**
 Executes the block for each section in the grouped array with the specified enumeration options.
 
 @param options The enumeration options to use.
 @param block A block taking three parameters:
                id section: The section
                NSUInteger index: the index of the section
                BOOL *stop: a pointer to a BOOL which will stop the enumeration if set to YES
 
 @discussion When NSEnumerationConcurrent is used, setting the stop BOOL reference passed into the block to YES will have no effect.
 */
- (void)enumerateSectionsWithOptions:(NSEnumerationOptions)options usingBlock:(void (^)(id section, NSUInteger index, BOOL *stop))block
{
    if (!block) {
        NSAssert(block, @"Block cannot be nil.");
        return;
    }
    
    BOOL concurrent = (options & NSEnumerationConcurrent);
    BOOL reverse = (options & NSEnumerationReverse);
    
    NSOperationQueue *concurrentQueue = nil;
    if (concurrent) {
        concurrentQueue = [[NSOperationQueue alloc] init];
    }
    
    unsigned long mutationValue = _mutations;
    NSUInteger sectionCount = [self countAllSections];
    for (NSUInteger i = 0; i < sectionCount; i++) {
        if (mutationValue != _mutations) {
            NSAssert(mutationValue == _mutations, @"Collection <%@: %p> was mutated while being enumerated.", NSStringFromClass([self class]), self);
            return;
        }
        __block BOOL stop = NO;
        NSUInteger sectionIndex = reverse ? sectionCount - 1 - i : i;
        id section = [self sectionAtIndex:sectionIndex];
        if (concurrent) {
            [concurrentQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                block(section, sectionIndex, &stop);
            }]];
        } else {
            block(section, sectionIndex, &stop);
            if (stop) {
                return;
            }
        }
    }
    [concurrentQueue waitUntilAllOperationsAreFinished];
}

/**
 Executes the block for each object in the grouped array.
 
 @param block A block taking three parameters:
                id object: The object
                NSIndexPath *indexPath: the index path of the object
                BOOL *stop: a pointer to a BOOL which will stop the enumeration if set to YES
 */
- (void)enumerateObjectsUsingBlock:(void (^)(id object, NSIndexPath *indexPath, BOOL *stop))block
{
    [self enumerateObjectsWithOptions:0 usingBlock:block];
}

/**
 Executes the block for each object in the grouped array with the specified enumeration options.
 
 @param options The enumeration options to use.
 @param block A block taking three parameters:
                id object: The object
                NSIndexPath *indexPath: the index path of the object
                BOOL *stop: a pointer to a BOOL which will stop the enumeration if set to YES
 
 @discussion When NSEnumerationConcurrent is used, setting the stop BOOL reference passed into the block to YES will have no effect.
 */
- (void)enumerateObjectsWithOptions:(NSEnumerationOptions)options usingBlock:(void (^)(id object, NSIndexPath *indexPath, BOOL *stop))block
{
    if (!block) {
        NSAssert(block, @"Block cannot be nil.");
        return;
    }
    
    BOOL concurrent = (options & NSEnumerationConcurrent);
    BOOL reverse = (options & NSEnumerationReverse);
    
    NSOperationQueue *concurrentQueue = nil;
    if (concurrent) {
        concurrentQueue = [[NSOperationQueue alloc] init];
    }
    
    unsigned long mutationValue = _mutations;
    NSUInteger sectionCount = [self countAllSections];
    for (NSUInteger i = 0; i < sectionCount; i++) {
        NSUInteger sectionIndex = reverse ? sectionCount - 1 - i : i;
        NSUInteger objectCount = [self countObjectsInSectionAtIndex:sectionIndex];
        for (NSUInteger j = 0; j < objectCount; j++) {
            if (mutationValue != _mutations) {
                NSAssert(mutationValue == _mutations, @"Collection <%@: %p> was mutated while being enumerated.", NSStringFromClass([self class]), self);
                return;
            }
            __block BOOL stop = NO;
            NSUInteger objectIndex = reverse ? objectCount - 1 - j : j;
            NSIndexPath *indexPath = [INTUGroupedArray indexPathForRow:objectIndex inSection:sectionIndex];
            id object = [self objectAtIndexPath:indexPath];
            if (concurrent) {
                [concurrentQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                    block(object, indexPath, &stop);
                }]];
            } else {
                block(object, indexPath, &stop);
                if (stop) {
                    return;
                }
            }
        }
    }
    [concurrentQueue waitUntilAllOperationsAreFinished];
}

/**
 Executes the block for each object in the section at the index.
 
 @param block A block taking three parameters:
                id object: The object
                NSIndexPath *indexPath: the index path of the object
                BOOL *stop: a pointer to a BOOL which will stop the enumeration if set to YES
 */
- (void)enumerateObjectsInSectionAtIndex:(NSUInteger)sectionIndex usingBlock:(void (^)(id object, NSIndexPath *indexPath, BOOL *stop))block
{
    [self enumerateObjectsInSectionAtIndex:sectionIndex withOptions:0 usingBlock:block];
}

/**
 Executes the block for each object in the section at the index with the specified enumeration options.
 
 @param options The enumeration options to use.
 @param block A block taking three parameters:
                id object: The object
                NSIndexPath *indexPath: the index path of the object
                BOOL *stop: a pointer to a BOOL which will stop the enumeration if set to YES
 
 @discussion When NSEnumerationConcurrent is used, setting the stop BOOL reference passed into the block to YES will have no effect.
 */
- (void)enumerateObjectsInSectionAtIndex:(NSUInteger)sectionIndex withOptions:(NSEnumerationOptions)options usingBlock:(void (^)(id object, NSIndexPath *indexPath, BOOL *stop))block
{
    if (!block) {
        NSAssert(block, @"Block cannot be nil.");
        return;
    }
    
    BOOL concurrent = (options & NSEnumerationConcurrent);
    BOOL reverse = (options & NSEnumerationReverse);
    
    NSOperationQueue *concurrentQueue = nil;
    if (concurrent) {
        concurrentQueue = [[NSOperationQueue alloc] init];
    }
    
    unsigned long mutationValue = _mutations;
    NSUInteger sectionCount = [self countAllSections];
    if (sectionIndex >= sectionCount) {
        NSAssert(sectionIndex < sectionCount, @"Section index out of bounds!");
        return;
    }
    
    NSUInteger objectCount = [self countObjectsInSectionAtIndex:sectionIndex];
    for (NSUInteger j = 0; j < objectCount; j++) {
        if (mutationValue != _mutations) {
            NSAssert(mutationValue == _mutations, @"Collection <%@: %p> was mutated while being enumerated.", NSStringFromClass([self class]), self);
            return;
        }
        __block BOOL stop = NO;
        NSUInteger objectIndex = reverse ? objectCount - 1 - j : j;
        NSIndexPath *indexPath = [INTUGroupedArray indexPathForRow:objectIndex inSection:sectionIndex];
        id object = [self objectAtIndexPath:indexPath];
        if (concurrent) {
            [concurrentQueue addOperation:[NSBlockOperation blockOperationWithBlock:^{
                block(object, indexPath, &stop);
            }]];
        } else {
            block(object, indexPath, &stop);
            if (stop) {
                return;
            }
        }
    }
    [concurrentQueue waitUntilAllOperationsAreFinished];
}

/**
 Returns an enumerator that will access each section in the grouped array, starting with the first section.
 */
- (NSEnumerator<INTUGroupedArraySectionEnumerator> *)sectionEnumerator
{
    return [INTUGroupedArraySectionEnumerator sectionEnumeratorForGroupedArray:self reverse:NO];
}

/**
 Returns an enumerator that will access each section in the grouped array, starting with the last section.
 */
- (NSEnumerator<INTUGroupedArraySectionEnumerator> *)reverseSectionEnumerator
{
    return [INTUGroupedArraySectionEnumerator sectionEnumeratorForGroupedArray:self reverse:YES];
}

/**
 Returns an enumerator that will access each object in the grouped array, starting with the first section.
 */
- (NSEnumerator *)objectEnumerator
{
    return [INTUGroupedArrayObjectEnumerator objectEnumeratorForGroupedArray:self reverse:NO];
}

/**
 Returns an enumerator that will access each object in the grouped array, starting with the last section.
 */
- (NSEnumerator *)reverseObjectEnumerator
{
    return [INTUGroupedArrayObjectEnumerator objectEnumeratorForGroupedArray:self reverse:YES];
}

/**
 Returns the index of the first section in the grouped array that passes the test (causing the block to return YES),
 or NSNotFound if no object causes the test to pass or if enumeration is stopped early before a section passes the test.
 
 @param block A block taking three parameters:
        id section: The section
        NSUInteger index: the index of the section
        BOOL *stop: a pointer to a BOOL which will stop the enumeration if set to YES
        The block should return YES if the section passes the test, otherwise it should return NO.
 */
- (NSUInteger)indexOfSectionPassingTest:(BOOL (^)(id section, NSUInteger index, BOOL *stop))block
{
    if (!block) {
        NSAssert(block, @"Block cannot be nil.");
        return NSNotFound;
    }
    
    unsigned long mutationValue = _mutations;
    NSUInteger sectionCount = [self countAllSections];
    for (NSUInteger sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
        if (mutationValue != _mutations) {
            NSAssert(mutationValue == _mutations, @"Collection <%@: %p> was mutated while being enumerated.", NSStringFromClass([self class]), self);
            return NSNotFound;
        }
        BOOL stop = NO;
        BOOL testPassed = block([self sectionAtIndex:sectionIndex], sectionIndex, &stop);
        if (testPassed) {
            return sectionIndex;
        } else if (stop) {
            return NSNotFound;
        }
    }
    
    return NSNotFound;
}

/**
 Returns the index path of the first object in the grouped array that passes the test (causing the block to return YES),
 or nil if no object causes the test to pass or if enumeration is stopped early before an object passes the test.
 
 @param block A block taking three parameters:
        id object: The object
        NSIndexPath *indexPath: the index path of the object
        BOOL *stop: a pointer to a BOOL which will stop the enumeration if set to YES
        The block should return YES if the object passes the test, otherwise it should return NO.
 */
- (NSIndexPath *)indexPathOfObjectPassingTest:(BOOL (^)(id object, NSIndexPath *indexPath, BOOL *stop))block
{
    if (!block) {
        NSAssert(block, @"Block cannot be nil.");
        return nil;
    }
    
    unsigned long mutationValue = _mutations;
    NSUInteger sectionCount = [self countAllSections];
    for (NSUInteger sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
        NSUInteger objectCount = [self countObjectsInSectionAtIndex:sectionIndex];
        for (NSUInteger objectIndex = 0; objectIndex < objectCount; objectIndex++) {
            if (mutationValue != _mutations) {
                NSAssert(mutationValue == _mutations, @"Collection <%@: %p> was mutated while being enumerated.", NSStringFromClass([self class]), self);
                return nil;
            }
            BOOL stop = NO;
            NSIndexPath *indexPath = [INTUGroupedArray indexPathForRow:objectIndex inSection:sectionIndex];
            BOOL testPassed = block([self objectAtIndexPath:indexPath], indexPath, &stop);
            if (testPassed) {
                return indexPath;
            } else if (stop) {
                return nil;
            }
        }
    }
    
    return nil;
}

/**
 Returns whether this grouped array is equal to the object.
 If the object also inherits from INTUGroupedArray, the isEqualToGroupedArray: method is used to determine equality.
 
 @param object The object to compare with.
 @return Whether the object is equal.
 */
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[INTUGroupedArray class]]) {
        return [self isEqualToGroupedArray:object];
    } else {
        return [super isEqual:object];
    }
}

/**
 Returns whether the contents of this grouped array are equal to the contents of another grouped array.
 
 @param otherGroupedArray The grouped array to compare contents with.
 @return Whether the contents of this grouped array are equal to the contents of otherGroupedArray.
 */
- (BOOL)isEqualToGroupedArray:(INTUGroupedArray *)otherGroupedArray
{
    if (!otherGroupedArray) {
        return NO;
    }
    if (otherGroupedArray == self) {
        return YES;
    }
    NSUInteger sectionCount = [self countAllSections];
    NSUInteger otherSectionCount = [otherGroupedArray countAllSections];
    if (sectionCount != otherSectionCount) {
        return NO;
    }
    for (NSUInteger sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++) {
        id section = [self sectionAtIndex:sectionIndex];
        id otherSection = [otherGroupedArray sectionAtIndex:sectionIndex];
        if (!section || !otherSection || ![section isEqual:otherSection]) {
            return NO;
        }
        NSUInteger objectCount = [self countObjectsInSectionAtIndex:sectionIndex];
        NSUInteger otherObjectCount = [otherGroupedArray countObjectsInSectionAtIndex:sectionIndex];
        if (objectCount != otherObjectCount) {
            return NO;
        }
        for (NSUInteger objectIndex = 0; objectIndex < objectCount; objectIndex++) {
            INTUIndexPair indexPair = INTUIndexPairMake(sectionIndex, objectIndex);
            id object = [self _objectAtIndexPair:indexPair];
            id otherObject = [otherGroupedArray _objectAtIndexPair:indexPair];
            if (!object || !otherObject || ![object isEqual:otherObject]) {
                return NO;
            }
        }
    }
    return YES;
}

/**
 Returns a new grouped array filtered by evaluating the section & object predicates against all sections & objects and removing those that do not match. Empty sections will be removed.
 
 @param sectionPredicate The predicate to evaluate against the sections.
 @param objectPredicate The predicate to evaluate against the objects.
 @return A new filtered grouped array.
 */
- (INTUGroupedArray *)filteredGroupedArrayUsingSectionPredicate:(NSPredicate *)sectionPredicate objectPredicate:(NSPredicate *)objectPredicate
{
    INTUGroupedArray *copy = [[INTUGroupedArray alloc] init];
    NSMutableArray *sectionContainersForCopy = [NSMutableArray new];
    if (sectionPredicate || objectPredicate) {
        for (INTUGroupedArraySectionContainer *sectionContainer in self.sectionContainers) {
            INTUMutableGroupedArraySectionContainer *sectionContainerCopy = [sectionContainer mutableCopy];
            if (sectionPredicate) {
                if ([sectionPredicate evaluateWithObject:sectionContainerCopy.section]) {
                    NSMutableArray *objectsArray = sectionContainerCopy.mutableObjects;
                    if (objectPredicate) {
                        [objectsArray filterUsingPredicate:objectPredicate];
                    }
                    if ([objectsArray count] > 0) {
                        [sectionContainersForCopy addObject:sectionContainerCopy];
                    }
                }
            } else if (objectPredicate) {
                NSMutableArray *objectsArray = sectionContainerCopy.mutableObjects;
                [objectsArray filterUsingPredicate:objectPredicate];
                if ([objectsArray count] > 0) {
                    [sectionContainersForCopy addObject:sectionContainerCopy];
                }
            }
        }
    }
    copy.sectionContainers = sectionContainersForCopy;
    return copy;
}

/**
 Returns a new grouped array with the sections sorted using the section comparator, and the objects in each section sorted using the object comparator.
 
 @param sectionCmptr A comparator block used to sort sections, or nil if no section sorting is desired.
 @param objectCmptr A comparator block used to sort objects in each section, or nil if no object sorting is desired.
 @return A new sorted grouped array.
 */
- (INTUGroupedArray *)sortedGroupedArrayUsingSectionComparator:(NSComparator)sectionCmptr objectComparator:(NSComparator)objectCmptr
{
    INTUGroupedArray *copy = [[INTUGroupedArray alloc] init];
    NSMutableArray *sectionContainers = [NSMutableArray new];
    for (INTUGroupedArraySectionContainer *sectionContainer in self.sectionContainers) {
        [sectionContainers addObject:[sectionContainer mutableCopy]];
    }
    if (sectionCmptr) {
        [sectionContainers sortUsingComparator:^NSComparisonResult(INTUMutableGroupedArraySectionContainer *sectionContainer1, INTUMutableGroupedArraySectionContainer *sectionContainer2) {
            return sectionCmptr(sectionContainer1.section, sectionContainer2.section);
        }];
    }
    if (objectCmptr) {
        for (INTUMutableGroupedArraySectionContainer *sectionContainer in sectionContainers) {
            [sectionContainer.mutableObjects sortUsingComparator:objectCmptr];
        }
    }
    copy.sectionContainers = sectionContainers;
    return copy;
}

@end
