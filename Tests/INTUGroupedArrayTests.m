//
//  INTUGroupedArrayTests.m
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

#import <XCTest/XCTest.h>
#import "INTUGroupedArrayImports.h"
#import <libkern/OSAtomic.h>

// We still want to test APIs annotated as non-null for the proper behavior, so disable warnings for nullability annotations.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

@interface INTUGroupedArrayTests : XCTestCase

@property (nonatomic, strong) INTUGroupedArray *groupedArray;

@end

/**
 Unit tests for the INTUGroupedArray class.
 */
@implementation INTUGroupedArrayTests

// Some objects used across multiple unit test methods
static const NSString *objectA = @"Alfa";
static const NSString *objectB = @"Bravo";
static const NSString *objectC = @"Charlie";
static const NSString *objectD = @"Delta";
static const NSString *objectE = @"Echo";
static const NSString *objectF = @"Foxtrot";

// Some sections used across multiple unit test methods
static const NSString *sectionW = @"Whiskey";
static const NSString *sectionX = @"Xray";
static const NSString *sectionY = @"Yankee";
static const NSString *sectionZ = @"Zulu";


- (void)setUp
{
    [super setUp];
    
    // Put setup code here; it will be run before each test case.
    
    self.groupedArray = [INTUMutableGroupedArray new];
}

- (void)tearDown
{
    // Put teardown code here; it will be run after the each test case.
    
    self.groupedArray = nil;
    
    [super tearDown];
}

/**
 Helper method to add the given number of sections and number of objects in each section to the grouped array.
 */
- (void)generateSections:(NSUInteger)numberOfSections withObjects:(NSUInteger)numberOfObjects
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    for (NSUInteger section = 0; section < numberOfSections; section++) {
        for (NSUInteger object = 0; object < numberOfObjects; object++) {
            [mutableGroupedArray addObject:@(object) toSection:[NSString stringWithFormat:@"Section %lu", (unsigned long) section]];
        }
    }
    self.groupedArray = [mutableGroupedArray copy];
}

/**
 Test the grouped array's literal syntax.
 */
- (void)testLiteralSyntax
{
    INTUGroupedArray *groupedArray;
    
    // Test an empty grouped array
    groupedArray = [INTUGroupedArray literal:@[]];
    XCTAssertNotNil(groupedArray);
    XCTAssert([groupedArray isMemberOfClass:[INTUGroupedArray class]]);
    XCTAssert([groupedArray countAllSections] == 0);
    XCTAssert([groupedArray countAllObjects] == 0);
    
    // Test a valid simple grouped array
    groupedArray = [INTUGroupedArray literal:@[sectionW, @[objectA]]];
    XCTAssert([groupedArray isMemberOfClass:[INTUGroupedArray class]]);
    XCTAssert([groupedArray countAllSections] == 1);
    XCTAssert([groupedArray countAllObjects] == 1);
    XCTAssert([groupedArray sectionAtIndex:0] == sectionW);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    
    // Test a valid grouped array that has some repeating objects
    groupedArray = [INTUGroupedArray literal:@[sectionW, @[objectA],
                                               sectionX, @[objectB, objectA, objectA]
                                               ]];
    XCTAssert([groupedArray isMemberOfClass:[INTUGroupedArray class]]);
    XCTAssert([groupedArray countAllSections] == 2);
    XCTAssert([groupedArray countAllObjects] == 4);
    XCTAssert([groupedArray sectionAtIndex:0] == sectionW);
    XCTAssert([groupedArray sectionAtIndex:1] == sectionX);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]] == objectB);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:1]] == objectA);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:1]] == objectA);
    
    // Test a "dumb" but still valid grouped array
    groupedArray = [INTUGroupedArray literal:@[@[], @[objectA]]];
    XCTAssert([groupedArray isMemberOfClass:[INTUGroupedArray class]]);
    XCTAssert([groupedArray countAllSections] == 1);
    XCTAssert([groupedArray countAllObjects] == 1);
    XCTAssert([[groupedArray sectionAtIndex:0] isEqual:@[]]);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    
    NSArray *literal; // for some reason the compiler doesn't like certain literals inside the XCTAssertThrows macro
    
    // Test an invalid nil literal
    XCTAssertThrows([INTUGroupedArray literal:nil]);
    
    // Test an invalid grouped array with an empty array of objects
    literal = @[sectionW, @[]];
    XCTAssertThrows([INTUGroupedArray literal:literal]);
    
    // Test an invalid grouped array with a single section and no objects
    literal = @[sectionW];
    XCTAssertThrows([INTUGroupedArray literal:literal]);
    
    // Test an invalid grouped array with two sections and no objects array
    literal = @[sectionY, sectionW];
    XCTAssertThrows([INTUGroupedArray literal:literal]);
    
    // There used to be enforcement of unique sections by the literal API, however that has been removed.
    // Make sure that we no longer throw an exception on having two identical sections (even though this is not a good idea).
    literal = @[sectionY, @[objectA],
                sectionY, @[objectB]];
    XCTAssertNoThrow([INTUGroupedArray literal:literal]);
}

/**
 Test the grouped array's NSCoding methods.
 */
- (void)testEncodeAndDecode
{
    [self addUnsortedSectionsAndObjects];
    
    NSData *serializedGroupedArray = [NSKeyedArchiver archivedDataWithRootObject:self.groupedArray];
    INTUGroupedArray *decodedGroupedArray = [NSKeyedUnarchiver unarchiveObjectWithData:serializedGroupedArray];
    XCTAssertTrue([decodedGroupedArray countAllSections] == [self.groupedArray countAllSections], @"The decoded grouped array should have the same number of sections as the original.");
    XCTAssertTrue([decodedGroupedArray countAllObjects] == [self.groupedArray countAllObjects], @"The decoded grouped array should have the same number of objects as the original.");
    XCTAssertTrue([[decodedGroupedArray indexPathOfObject:objectA] isEqual:[self.groupedArray indexPathOfObject:objectA]], @"The decoded grouped array should have Object A at the same index path as the original.");
}

/**
 Test using fast enumeration to iterate over objects in the grouped array.
 */
- (void)testFastEnumeration
{
    NSArray *objectArray = @[objectA, objectB, objectC, objectD, objectE, objectF];
    
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArrayWithArray:objectArray];
    self.groupedArray = [mutableGroupedArray copy];
    NSUInteger i = 0;
    for (id object in self.groupedArray) {
        XCTAssertEqualObjects(object, objectArray[i], @"The objects should be equal.");
        i++;
    }
    XCTAssertTrue(i == [objectArray count], @"The fast enumeration should have iterated over all objects.");
    
    [mutableGroupedArray addObjectsFromArray:objectArray toSection:sectionZ];
    [mutableGroupedArray addObjectsFromArray:objectArray toSection:sectionX];
    [mutableGroupedArray addObjectsFromArray:objectArray toSection:sectionZ];
    self.groupedArray = [mutableGroupedArray copy];
    i = 0;
    for (id object in self.groupedArray) {
        XCTAssertEqualObjects(object, objectArray[i % [objectArray count]], @"The objects should be equal.");
        i++;
    }
    XCTAssertTrue(i == [objectArray count] * 4, @"The fast enumeration should have iterated over all objects.");
    
    // Test using a larger grouped array (where a section count should exceed the buffer size passed in to countByEnumeratingWithState:objects:count:)
    [self addUnsortedSectionsAndObjects];
    mutableGroupedArray = [self.groupedArray mutableCopy];
    [mutableGroupedArray addObject:objectB toSection:sectionW];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionW];
    [mutableGroupedArray addObject:objectC toSection:sectionW];
    [mutableGroupedArray addObject:objectB toSection:sectionW];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionW];
    [mutableGroupedArray addObject:objectC toSection:sectionW];
    [mutableGroupedArray addObject:objectB toSection:sectionW];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionW];
    [mutableGroupedArray addObject:objectC toSection:sectionW];
    [mutableGroupedArray addObject:objectB toSection:sectionX];
    [mutableGroupedArray addObject:objectF toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionW];
    [mutableGroupedArray addObject:objectC toSection:sectionW];
    [mutableGroupedArray addObject:objectB toSection:sectionX];
    [mutableGroupedArray addObject:objectA toSection:sectionX];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionZ];
    [mutableGroupedArray addObject:objectE toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionW];
    [mutableGroupedArray addObject:objectC toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    objectArray = [self.groupedArray allObjects];
    i = 0;
    for (id object in self.groupedArray) {
        XCTAssertEqualObjects(object, objectArray[i], @"The objects should be equal.");
        i++;
    }
    XCTAssertTrue(i == [objectArray count], @"The fast enumeration should have iterated over all objects.");
}

/**
 Test performing a shallow copy on the grouped array.
 */
- (void)testInitWithGroupedArray
{
    NSMutableString *object1 = [NSMutableString stringWithString:@"Object 1"];
    NSMutableString *object2 = [NSMutableString stringWithString:@"Object 2"];
    NSMutableString *section1 = [NSMutableString stringWithString:@"Section 1"];
    NSMutableString *section2 = [NSMutableString stringWithString:@"Section 2"];
    
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:object1 toSection:section1];
    [mutableGroupedArray addObject:object2 toSection:section2];
    INTUGroupedArray *groupedArray = [mutableGroupedArray copy]; // this gets us an immutable instance of INTUGroupedArray
    
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUGroupedArray *copy = [[INTUGroupedArray alloc] initWithGroupedArray:groupedArray];
    
    XCTAssert([copy isMemberOfClass:[INTUGroupedArray class]], @"The copy should be an INTUGroupedArray.");
    XCTAssertTrue(groupedArray != copy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([copy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([copy countAllObjects] == 2, @"There should be 2 objects total.");
    
    [groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        id otherSection = [copy sectionAtIndex:index];
        XCTAssertEqual(section, otherSection, @"The sections should be identical instances.");
    }];
    
    [groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        id otherObject = [copy objectAtIndexPath:indexPath];
        XCTAssertEqual(object, otherObject, @"The objects should be identical instances.");
    }];
}

/**
 Test performing a deep copy on the grouped array.
 */
- (void)testInitWithGroupedArrayCopyItems
{
    NSMutableString *object1 = [NSMutableString stringWithString:@"Object 1"];
    NSMutableString *object2 = [NSMutableString stringWithString:@"Object 2"];
    NSMutableString *section1 = [NSMutableString stringWithString:@"Section 1"];
    NSMutableString *section2 = [NSMutableString stringWithString:@"Section 2"];
    
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:object1 toSection:section1];
    [mutableGroupedArray addObject:object2 toSection:section2];
    INTUGroupedArray *groupedArray = [mutableGroupedArray copy]; // this gets us an immutable instance of INTUGroupedArray
    
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUGroupedArray *deepCopy = [[INTUGroupedArray alloc] initWithGroupedArray:groupedArray copyItems:YES];
    
    XCTAssert([deepCopy isMemberOfClass:[INTUGroupedArray class]], @"The copy should be an INTUGroupedArray.");
    XCTAssertTrue(groupedArray != deepCopy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([deepCopy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([deepCopy countAllObjects] == 2, @"There should be 2 objects total.");
    
    [groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        id otherSection = [deepCopy sectionAtIndex:index];
        XCTAssertNotEqual(section, otherSection, @"The sections should not be identical instances.");
        XCTAssertEqualObjects(section, otherSection, @"The sections should be equal.");
    }];
    
    [groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        id otherObject = [deepCopy objectAtIndexPath:indexPath];
        XCTAssertNotEqual(object, otherObject, @"The objects should not be identical instances.");
        XCTAssertEqualObjects(object, otherObject, @"The objects should be equal.");
    }];
}

/**
 Test getting an immutable copy of the grouped array.
 */
- (void)testCopy
{
    NSMutableString *object1 = [NSMutableString stringWithString:@"Object 1"];
    NSMutableString *object2 = [NSMutableString stringWithString:@"Object 2"];
    NSMutableString *section1 = [NSMutableString stringWithString:@"Section 1"];
    NSMutableString *section2 = [NSMutableString stringWithString:@"Section 2"];
    
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:object1 toSection:section1];
    [mutableGroupedArray addObject:object2 toSection:section2];
    INTUGroupedArray *groupedArray = [mutableGroupedArray copy]; // this gets us an immutable instance of INTUGroupedArray
    
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUGroupedArray *copy = [groupedArray copy];
    
    XCTAssert([copy isMemberOfClass:[INTUGroupedArray class]], @"The copy should be an INTUGroupedArray.");
    XCTAssertTrue(groupedArray == copy, @"The copy should be a reference to the same object.");
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([copy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([copy countAllObjects] == 2, @"There should be 2 objects total.");
    
    [groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        id otherSection = [copy sectionAtIndex:index];
        XCTAssertEqual(section, otherSection, @"The sections should be identical instances.");
    }];
    
    [groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        id otherObject = [copy objectAtIndexPath:indexPath];
        XCTAssertEqual(object, otherObject, @"The objects should be identical instances.");
    }];
}

/**
 Test getting a mutable copy of the grouped array.
 */
- (void)testMutableCopy
{
    NSMutableString *object1 = [NSMutableString stringWithString:@"Object 1"];
    NSMutableString *object2 = [NSMutableString stringWithString:@"Object 2"];
    NSMutableString *section1 = [NSMutableString stringWithString:@"Section 1"];
    NSMutableString *section2 = [NSMutableString stringWithString:@"Section 2"];
    
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:object1 toSection:section1];
    [mutableGroupedArray addObject:object2 toSection:section2];
    INTUGroupedArray *groupedArray = [mutableGroupedArray copy]; // this gets us an immutable instance of INTUGroupedArray
    
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUGroupedArray *mutableCopy = [groupedArray mutableCopy];
    
    XCTAssert([mutableCopy isMemberOfClass:[INTUMutableGroupedArray class]], @"The copy should be an INTUMutableGroupedArray.");
    XCTAssertTrue(groupedArray != mutableCopy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([mutableCopy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([mutableCopy countAllObjects] == 2, @"There should be 2 objects total.");
    
    [groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        id otherSection = [mutableCopy sectionAtIndex:index];
        XCTAssertEqual(section, otherSection, @"The sections should be identical instances.");
    }];
    
    [groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        id otherObject = [mutableCopy objectAtIndexPath:indexPath];
        XCTAssertEqual(object, otherObject, @"The objects should be identical instances.");
    }];
}

/**
 Test copying the grouped array, then modifying one of the objects and checking that both the original and copy still refer to the same modified object.
 */
- (void)testCopyMutate
{
    NSMutableString *object1 = [NSMutableString stringWithString:@"Object 1"];
    NSMutableString *object2 = [NSMutableString stringWithString:@"Object 2"];
    NSMutableString *section1 = [NSMutableString stringWithString:@"Section 1"];
    NSMutableString *section2 = [NSMutableString stringWithString:@"Section 2"];
    
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:object1 toSection:section1];
    [mutableGroupedArray addObject:object2 toSection:section2];
    INTUGroupedArray *groupedArray = [mutableGroupedArray copy]; // this gets us an immutable instance of INTUGroupedArray
    
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUGroupedArray *copy = [groupedArray copy];
    
    XCTAssertTrue(groupedArray == copy, @"The copy should be a reference to the same object.");
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([copy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([copy countAllObjects] == 2, @"There should be 2 objects total.");
    
    // Mutate the object1 object and make sure this change is visible from both the original and the copy.
    [object1 appendString:@" Mutated"];
    
    XCTAssertEqualObjects(object1, @"Object 1 Mutated", @"The object1 object should now be 'Object 1 Mutated'.");
    XCTAssertTrue([[groupedArray objectAtIndex:0 inSection:section1] isEqual:object1], @"The first object of the original should now be named 'Object 1 Mutated'.");
    XCTAssertTrue([[copy objectAtIndex:0 inSection:section1] isEqual:object1], @"The first section of the copy should now be named 'Object 1 Mutated'.");
    XCTAssertEqual([groupedArray objectAtIndex:0 inSection:section1], [copy objectAtIndex:0 inSection:section1], @"The original and copy should reference the same object.");
    
    // Mutate the section1 object and make sure this affects the first section in both the original and the copy.
    [section1 appendString:@" Mutated"];
    
    XCTAssertEqualObjects(section1, @"Section 1 Mutated", @"The section1 object should now be 'Section 1 Mutated'.");
    XCTAssertEqual([groupedArray sectionAtIndex:0], section1, @"The first section of the original should be 'Section 1 Mutated'.");
    XCTAssertEqual([copy sectionAtIndex:0], section1, @"The first section of the original should be 'Section 1 Mutated'.");
    XCTAssertEqual([groupedArray sectionAtIndex:0], [copy sectionAtIndex:0], @"The first section of the original and the copy should be the same object.");
    XCTAssertTrue([groupedArray containsSection:section1], @"The original should have a section 'Section 1 Mutated'.");
    XCTAssertTrue([copy containsSection:section1], @"The copy should have a section 'Section 1 Mutated'.");
    
    INTUGroupedArray *mutableCopy = [groupedArray mutableCopy];
    
    XCTAssertTrue(groupedArray != mutableCopy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([mutableCopy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([mutableCopy countAllObjects] == 2, @"There should be 2 objects total.");
    
    // Mutate the object1 object and make sure this change is visible from both the original and the copy.
    [object1 appendString:@" Again"];
    
    XCTAssertEqualObjects(object1, @"Object 1 Mutated Again", @"The section1 object should now be 'Object 1 Mutated Again'.");
    XCTAssertTrue([[groupedArray objectAtIndex:0 inSection:section1] isEqual:object1], @"The first object of the original should now be named 'Object 1 Mutated'.");
    XCTAssertTrue([[mutableCopy objectAtIndex:0 inSection:section1] isEqual:object1], @"The first section of the copy should now be named 'Object 1 Mutated'.");
    XCTAssertEqual([groupedArray objectAtIndex:0 inSection:section1], [mutableCopy objectAtIndex:0 inSection:section1], @"The original and copy should reference the same object.");
    
    // Mutate the section1 object and make sure this affects the first section in both the original and the copy.
    [section1 appendString:@" Again"];
    
    XCTAssertEqualObjects(section1, @"Section 1 Mutated Again", @"The section1 object should now be 'Section 1 Mutated Again'.");
    XCTAssertEqual([groupedArray sectionAtIndex:0], section1, @"The first section of the original should be 'Section 1 Mutated'.");
    XCTAssertEqual([mutableCopy sectionAtIndex:0], section1, @"The first section of the original should be 'Section 1 Mutated'.");
    XCTAssertEqual([groupedArray sectionAtIndex:0], [mutableCopy sectionAtIndex:0], @"The first section of the original and the copy should be the same object.");
    XCTAssertTrue([groupedArray containsSection:section1], @"The original should have a section 'Section 1 Mutated'.");
    XCTAssertTrue([mutableCopy containsSection:section1], @"The copy should have a section 'Section 1 Mutated'.");
}

/**
 Adds some sections and objects to the index array in an unsorted fashion.
 */
- (void)addUnsortedSectionsAndObjects
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    self.groupedArray = [mutableGroupedArray copy];
    
    XCTAssertEqual(objectE, [self.groupedArray objectAtIndex:0 inSection:sectionY], @"Objects should not be sorted.");
    XCTAssertEqual(objectB, [self.groupedArray objectAtIndex:1 inSection:sectionY], @"Objects should not be sorted.");
    XCTAssertEqual(objectA, [self.groupedArray objectAtIndex:2 inSection:sectionY], @"Objects should not be sorted.");
    XCTAssertEqual(objectC, [self.groupedArray objectAtIndex:3 inSection:sectionY], @"Objects should not be sorted.");
    
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    XCTAssertEqual(sectionY, [self.groupedArray sectionAtIndex:0], @"Sections should not be sorted.");
    XCTAssertEqual(sectionW, [self.groupedArray sectionAtIndex:1], @"Sections should not be sorted.");
    XCTAssertEqual(sectionX, [self.groupedArray sectionAtIndex:2], @"Sections should not be sorted.");
    XCTAssertEqual(sectionZ, [self.groupedArray sectionAtIndex:3], @"Sections should not be sorted.");    
}

- (void)testFirstObject
{
    XCTAssert([self.groupedArray countAllObjects] == 0, @"The grouped array should be empty.");
    XCTAssertNil([self.groupedArray firstObject], @"Calling firstObject should return nil on an empty grouped array.");
    
    [self addUnsortedSectionsAndObjects];
    
    XCTAssert([self.groupedArray firstObject] == objectE, @"The first object should be Object E.");
}

- (void)testLastObject
{
    XCTAssert([self.groupedArray countAllObjects] == 0, @"The grouped array should be empty.");
    XCTAssertNil([self.groupedArray lastObject], @"Calling lastObject should return nil on an empty grouped array.");
    
    [self addUnsortedSectionsAndObjects];
    
    XCTAssert([self.groupedArray lastObject] == objectD, @"The last object should be Object D.");
}

/**
 Test the indexOfObject:inSection: and indexPathOfObject: methods.
 */
- (void)testIndexOfSectionAndIndexPathOfObject
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectB toSection:sectionX];
    [mutableGroupedArray addObject:objectF toSection:sectionZ];
    [mutableGroupedArray addObject:objectE toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    XCTAssertTrue([self.groupedArray indexOfObject:objectA inSection:sectionY] == 0, @"Object A in Section Y should be at index 0.");
    XCTAssertTrue([self.groupedArray indexOfObject:objectB inSection:sectionY] == 1, @"Object B in Section Y should be at index 1.");
    XCTAssertTrue([self.groupedArray indexOfObject:objectC inSection:sectionY] == 2, @"Object C in Section Y should be at index 2.");
    XCTAssertTrue([self.groupedArray indexOfObject:objectA inSection:sectionW] == 0, @"Object A in Section W should be at index 0.");
    XCTAssertTrue([self.groupedArray indexOfObject:objectE inSection:sectionW] == 1, @"Object E in Section W should be at index 1.");
    
    XCTAssertEqualObjects([self.groupedArray indexPathOfObject:objectA], [INTUGroupedArray indexPathForRow:0 inSection:0], @"Object A should be at index path {Section 0, Row 0}.");
    XCTAssertEqualObjects([self.groupedArray indexPathOfObject:objectB], [INTUGroupedArray indexPathForRow:1 inSection:0], @"Object B should be at index path {Section 0, Row 1}.");
    XCTAssertEqualObjects([self.groupedArray indexPathOfObject:objectE], [INTUGroupedArray indexPathForRow:1 inSection:1], @"Object E should be at index path {Section 1, Row 1}.");
    XCTAssertEqualObjects([self.groupedArray indexPathOfObject:objectF], [INTUGroupedArray indexPathForRow:0 inSection:3], @"Object E should be at index path {Section 3, Row 0}.");
    
    // Remove the first Object A in the first section.
    [mutableGroupedArray removeObjectAtIndex:0 fromSection:sectionY];
    self.groupedArray = [mutableGroupedArray copy];
    
    XCTAssertTrue([self.groupedArray indexOfObject:objectA inSection:sectionY] == 2, @"Object A in Section Y should be at index 2.");
    XCTAssertEqualObjects([self.groupedArray indexPathOfObject:objectA], [INTUGroupedArray indexPathForRow:2 inSection:0], @"Object A should be at index path {Section 0, Row 2}.");
    
    // Now remove all instances of Object A in the grouped array
    [mutableGroupedArray removeObject:objectA];
    self.groupedArray = [mutableGroupedArray copy];
    
    XCTAssertTrue([self.groupedArray indexOfObject:objectA inSection:sectionY] == NSNotFound, @"Object A should not exist in Section Y.");
    XCTAssertTrue([self.groupedArray indexPathOfObject:objectA] == nil, @"Object A should not exist in any section.");
}

/**
 Test the enumerateSectionsUsingBlock: method.
 */
- (void)testEnumerateSectionsUsingBlock
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    __block NSUInteger count = 0;
    [self.groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        XCTAssertTrue(index == count, @"Index should always equal the number of times this block has executed.");
        switch (count) {
            case 0:
                XCTAssertTrue(section == sectionY, @"The first section should be Section Y");
                break;
            case 1:
                XCTAssertTrue(section == sectionW, @"The second section should be Section W");
                break;
            case 2:
                XCTAssertTrue(section == sectionX, @"The third section should be Section X");
                break;
            case 3:
                XCTAssertTrue(section == sectionZ, @"The fourth section should be Section Z");
                break;
            default:
                XCTAssertNotNil(nil, @"Control should not reach this.");
                break;
        }
        count++;
    }];
    XCTAssertTrue(count == [self.groupedArray countAllSections], @"The block should have executed once for each section.");
    
    
    // Try dereferencing the pointer to the stop BOOL and setting it to YES, making sure enumeration halts
    count = 0;
    [self.groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        *stop = YES;
        count++;
    }];
    XCTAssertTrue(count == 1, @"The block should have executed only once, because a stop was requested.");
    
    // Test using an empty grouped array
    count = 0;
    [[INTUGroupedArray groupedArray] enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        count++;
    }];
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
}


/**
 Test the enumerateSectionsWithOptions:usingBlock: method, passing option NSEnumerationReverse.
 */
- (void)testEnumerateSectionsWithOptionReverse
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    __block NSUInteger count = 0;
    NSUInteger sectionCount = [self.groupedArray countAllSections];
    [self.groupedArray enumerateSectionsWithOptions:NSEnumerationReverse usingBlock:^(id section, NSUInteger index, BOOL *stop) {
        XCTAssertTrue(index == sectionCount - 1 - count, @"Index should always equal the section count minus one minus the number of times this block has executed.");
        switch (count) {
            case 0:
                XCTAssertTrue(section == sectionZ, @"The first section should be Section Z");
                break;
            case 1:
                XCTAssertTrue(section == sectionX, @"The second section should be Section X");
                break;
            case 2:
                XCTAssertTrue(section == sectionW, @"The third section should be Section W");
                break;
            case 3:
                XCTAssertTrue(section == sectionY, @"The fourth section should be Section Y");
                break;
            default:
                XCTAssertNotNil(nil, @"Control should not reach this.");
                break;
        }
        count++;
    }];
    XCTAssertTrue(count == [self.groupedArray countAllSections], @"The block should have executed once for each section.");
    
    
    // Try dereferencing the pointer to the stop BOOL and setting it to YES, making sure enumeration halts
    count = 0;
    [self.groupedArray enumerateSectionsWithOptions:NSEnumerationReverse usingBlock:^(id section, NSUInteger index, BOOL *stop) {
        *stop = YES;
        count++;
    }];
    XCTAssertTrue(count == 1, @"The block should have executed only once, because a stop was requested.");
    
    // Test using an empty grouped array
    count = 0;
    [[INTUGroupedArray groupedArray] enumerateSectionsWithOptions:NSEnumerationReverse usingBlock:^(id section, NSUInteger index, BOOL *stop) {
        count++;
    }];
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
}

/**
 Test the enumerateSectionsWithOptions:usingBlock: method, passing option NSEnumerationConcurrent.
 */
- (void)testEnumerateSectionsWithOptionConcurrent
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    __block int32_t count = 0;
    [self.groupedArray enumerateSectionsWithOptions:NSEnumerationConcurrent usingBlock:^(id section, NSUInteger index, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countAllSections], @"The block should have executed once for each section.");
    count = 0;
    [self.groupedArray enumerateSectionsWithOptions:NSEnumerationConcurrent | NSEnumerationReverse usingBlock:^(id section, NSUInteger index, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countAllSections], @"The block should have executed once for each section.");
    
    // Try dereferencing the pointer to the stop BOOL and setting it to YES - this should have no impact
    count = 0;
    [self.groupedArray enumerateSectionsWithOptions:NSEnumerationConcurrent usingBlock:^(id section, NSUInteger index, BOOL *stop) {
        *stop = YES;
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countAllSections], @"The stop request should have been ignored.");
    count = 0;
    [self.groupedArray enumerateSectionsWithOptions:NSEnumerationConcurrent | NSEnumerationReverse usingBlock:^(id section, NSUInteger index, BOOL *stop) {
        *stop = YES;
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countAllSections], @"The stop request should have been ignored.");
    
    // Test using an empty grouped array
    count = 0;
    [[INTUGroupedArray groupedArray] enumerateSectionsWithOptions:NSEnumerationConcurrent usingBlock:^(id section, NSUInteger index, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
    count = 0;
    [[INTUGroupedArray groupedArray] enumerateSectionsWithOptions:NSEnumerationConcurrent | NSEnumerationReverse usingBlock:^(id section, NSUInteger index, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
}

/**
 Test the enumerateObjectsUsingBlock: method.
 */
- (void)testEnumerateObjectsUsingBlock
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    __block NSUInteger count = 0;
    [self.groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        switch (count) {
            case 0:
                XCTAssertTrue(object == objectE, @"The first object should be Object E");
                break;
            case 1:
                XCTAssertTrue(object == objectB, @"The second object should be Object B");
                break;
            case 2:
                XCTAssertTrue(object == objectA, @"The third object should be Object A");
                break;
            case 3:
                XCTAssertTrue(object == objectC, @"The fourth object should be Object C");
                break;
            case 4:
                XCTAssertTrue(object == objectA, @"The fifth object should be Object A");
                break;
            case 5:
                XCTAssertTrue(object == objectD, @"The sixth object should be Object D");
                break;
            case 6:
                XCTAssertTrue(object == objectF, @"The seventh object should be Object F");
                break;
            case 7:
                XCTAssertTrue(object == objectD, @"The eighth object should be Object D");
                break;
            default:
                XCTAssertNotNil(nil, @"Control should not reach this.");
                break;
        }
        count++;
    }];
    XCTAssertTrue(count == [self.groupedArray countAllObjects], @"The block should have executed once for each object.");
    
    // Try dereferencing the pointer to the stop BOOL and setting it to YES, making sure enumeration halts
    count = 0;
    [self.groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        *stop = YES;
        count++;
    }];
    XCTAssertTrue(count == 1, @"The block should have executed only once, because a stop was requested.");
    
    // Test using an empty grouped array
    count = 0;
    [[INTUGroupedArray groupedArray] enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        count++;
    }];
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
}

/**
 Test the enumerateObjectsWithOptions:usingBlock: method, passing option NSEnumerationReverse.
 */
- (void)testEnumerateObjectsWithOptionReverse
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    __block NSUInteger count = 0;
    [self.groupedArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        switch (count) {
            case 0:
                XCTAssertTrue(object == objectD, @"The first object should be Object D");
                break;
            case 1:
                XCTAssertTrue(object == objectF, @"The second object should be Object F");
                break;
            case 2:
                XCTAssertTrue(object == objectD, @"The third object should be Object D");
                break;
            case 3:
                XCTAssertTrue(object == objectA, @"The fourth object should be Object A");
                break;
            case 4:
                XCTAssertTrue(object == objectC, @"The fifth object should be Object C");
                break;
            case 5:
                XCTAssertTrue(object == objectA, @"The sixth object should be Object A");
                break;
            case 6:
                XCTAssertTrue(object == objectB, @"The seventh object should be Object B");
                break;
            case 7:
                XCTAssertTrue(object == objectE, @"The eighth object should be Object E");
                break;
            default:
                XCTAssertNotNil(nil, @"Control should not reach this.");
                break;
        }
        count++;
    }];
    XCTAssertTrue(count == [self.groupedArray countAllObjects], @"The block should have executed once for each object.");
    
    // Try dereferencing the pointer to the stop BOOL and setting it to YES, making sure enumeration halts
    count = 0;
    [self.groupedArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        *stop = YES;
        count++;
    }];
    XCTAssertTrue(count == 1, @"The block should have executed only once, because a stop was requested.");
    
    // Test using an empty grouped array
    count = 0;
    [[INTUGroupedArray groupedArray] enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        count++;
    }];
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
}

/**
 Test the enumerateObjectsWithOptions:usingBlock: method, passing option NSEnumerationConcurrent.
 */
- (void)testEnumerateObjectsWithOptionConcurrent
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    __block int32_t count = 0;
    [self.groupedArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countAllObjects], @"The block should have executed once for each object.");
    count = 0;
    [self.groupedArray enumerateObjectsWithOptions:NSEnumerationConcurrent | NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countAllObjects], @"The block should have executed once for each object.");
    
    // Try dereferencing the pointer to the stop BOOL and setting it to YES - this should have no impact
    count = 0;
    [self.groupedArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        *stop = YES;
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countAllObjects], @"The stop request should have been ignored.");
    count = 0;
    [self.groupedArray enumerateObjectsWithOptions:NSEnumerationConcurrent | NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        *stop = YES;
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countAllObjects], @"The stop request should have been ignored.");
    
    // Test using an empty grouped array
    count = 0;
    [[INTUGroupedArray groupedArray] enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
    count = 0;
    [[INTUGroupedArray groupedArray] enumerateObjectsWithOptions:NSEnumerationConcurrent | NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
}

/**
 Test the enumerateObjectsInSectionAtIndex:usingBlock: method.
 */
- (void)testEnumerateObjectsInSectionAtIndexUsingBlock
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    __block NSUInteger count = 0;
    [self.groupedArray enumerateObjectsInSectionAtIndex:0 usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        switch (count) {
            case 0:
                XCTAssertTrue(object == objectE, @"The first object should be Object E");
                break;
            case 1:
                XCTAssertTrue(object == objectB, @"The second object should be Object B");
                break;
            case 2:
                XCTAssertTrue(object == objectA, @"The third object should be Object A");
                break;
            case 3:
                XCTAssertTrue(object == objectC, @"The fourth object should be Object C");
                break;
            default:
                XCTAssertNotNil(nil, @"Control should not reach this.");
                break;
        }
        count++;
    }];
    XCTAssertTrue(count == [self.groupedArray countObjectsInSectionAtIndex:0], @"The block should have executed once for each object in the first section.");
    
    // Try dereferencing the pointer to the stop BOOL and setting it to YES, making sure enumeration halts
    count = 0;
    [self.groupedArray enumerateObjectsInSectionAtIndex:1 usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        *stop = YES;
        count++;
    }];
    XCTAssertTrue(count == 1, @"The block should have executed only once, because a stop was requested.");
    
    // Test using an empty grouped array
    count = 0;
    XCTAssertThrows([[INTUGroupedArray groupedArray] enumerateObjectsInSectionAtIndex:0 usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        count++;
    }], @"An empty grouped array should throw a section index out of bounds exception.");
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
}

/**
 Test the enumerateObjectsInSectionAtIndex:withOptions:usingBlock: method, passing option NSEnumerationReverse.
 */
- (void)testEnumerateObjectsInSectionAtIndexWithOptionReverse
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    __block NSUInteger count = 0;
    [self.groupedArray enumerateObjectsInSectionAtIndex:0 withOptions:NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        switch (count) {
            case 0:
                XCTAssertTrue(object == objectC, @"The fifth object should be Object C");
                break;
            case 1:
                XCTAssertTrue(object == objectA, @"The sixth object should be Object A");
                break;
            case 2:
                XCTAssertTrue(object == objectB, @"The seventh object should be Object B");
                break;
            case 3:
                XCTAssertTrue(object == objectE, @"The eighth object should be Object E");
                break;
            default:
                XCTAssertNotNil(nil, @"Control should not reach this.");
                break;
        }
        count++;
    }];
    XCTAssertTrue(count == [self.groupedArray countObjectsInSectionAtIndex:0], @"The block should have executed once for each object in the first section.");
    
    // Try dereferencing the pointer to the stop BOOL and setting it to YES, making sure enumeration halts
    count = 0;
    [self.groupedArray enumerateObjectsInSectionAtIndex:1 withOptions:NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        *stop = YES;
        count++;
    }];
    XCTAssertTrue(count == 1, @"The block should have executed only once, because a stop was requested.");
    
    // Test using an empty grouped array
    count = 0;
    XCTAssertThrows([[INTUGroupedArray groupedArray] enumerateObjectsInSectionAtIndex:1 withOptions:NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        count++;
    }], @"An empty grouped array should throw a section index out of bounds exception.");
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
}

/**
 Test the enumerateObjectsInSectionAtIndex:withOptions:usingBlock: method, passing option NSEnumerationConcurrent.
 */
- (void)testEnumerateObjectsInSectionAtIndexWithOptionConcurrent
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    __block int32_t count = 0;
    [self.groupedArray enumerateObjectsInSectionAtIndex:0 withOptions:NSEnumerationConcurrent usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countObjectsInSectionAtIndex:0], @"The block should have executed once for each object in the first section.");
    count = 0;
    [self.groupedArray enumerateObjectsInSectionAtIndex:0 withOptions:NSEnumerationConcurrent | NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countObjectsInSectionAtIndex:0], @"The block should have executed once for each object in the first section.");
    
    // Try dereferencing the pointer to the stop BOOL and setting it to YES - this should have no impact
    count = 0;
    [self.groupedArray enumerateObjectsInSectionAtIndex:0 withOptions:NSEnumerationConcurrent usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        *stop = YES;
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countObjectsInSectionAtIndex:0], @"The stop request should have been ignored.");
    count = 0;
    [self.groupedArray enumerateObjectsInSectionAtIndex:0 withOptions:NSEnumerationConcurrent | NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        *stop = YES;
        OSAtomicIncrement32(&count);
    }];
    XCTAssertTrue(count == [self.groupedArray countObjectsInSectionAtIndex:0], @"The stop request should have been ignored.");
    
    // Test using an empty grouped array
    count = 0;
    XCTAssertThrows([[INTUGroupedArray groupedArray] enumerateObjectsInSectionAtIndex:0 withOptions:NSEnumerationConcurrent usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }], @"An empty grouped array should throw a section index out of bounds exception.");
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
    count = 0;
    XCTAssertThrows([[INTUGroupedArray groupedArray] enumerateObjectsInSectionAtIndex:0 withOptions:NSEnumerationConcurrent | NSEnumerationReverse usingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        OSAtomicIncrement32(&count);
    }], @"An empty grouped array should throw a section index out of bounds exception.");
    XCTAssertTrue(count == 0, @"The block should have never executed because the grouped array is empty.");
}

/**
 Test the indexOfSectionPassingTest: method.
 */
- (void)testIndexOfSectionPassingTest
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    NSUInteger indexOfSection;
    
    indexOfSection = [[INTUGroupedArray groupedArray] indexOfSectionPassingTest:^BOOL(id section, NSUInteger index, BOOL *stop) {
        return YES;
    }];
    XCTAssertTrue(indexOfSection == NSNotFound, @"An empty grouped array should always return NSNotFound even when the test always passes.");
    
    indexOfSection = [self.groupedArray indexOfSectionPassingTest:^BOOL(id section, NSUInteger index, BOOL *stop) {
        return NO;
    }];
    XCTAssertTrue(indexOfSection == NSNotFound, @"NSNotFound should be returned when the test always fails.");
    
    indexOfSection = [self.groupedArray indexOfSectionPassingTest:^BOOL(id section, NSUInteger index, BOOL *stop) {
        return YES;
    }];
    XCTAssertTrue(indexOfSection == 0, @"The first section should be returned when the test always passes.");
    
    indexOfSection = [self.groupedArray indexOfSectionPassingTest:^BOOL(id section, NSUInteger index, BOOL *stop) {
        return section == sectionY;
    }];
    XCTAssertTrue(indexOfSection == 0, @"Section Y should be at index 0.");
    
    indexOfSection = [self.groupedArray indexOfSectionPassingTest:^BOOL(id section, NSUInteger index, BOOL *stop) {
        return section == sectionW;
    }];
    XCTAssertTrue(indexOfSection == 1, @"Section W should be at index 1.");
    
    indexOfSection = [self.groupedArray indexOfSectionPassingTest:^BOOL(id section, NSUInteger index, BOOL *stop) {
        return section == sectionZ;
    }];
    XCTAssertTrue(indexOfSection == 3, @"Section Z should be at index 3.");
    
    indexOfSection = [self.groupedArray indexOfSectionPassingTest:^BOOL(id section, NSUInteger index, BOOL *stop) {
        return section == sectionX;
    }];
    XCTAssertTrue(indexOfSection == 2, @"Section X should be at index 2.");
    
    // Setting stop to YES after passing the test should cause the correct index to be returned, but no further sections to be tested
    indexOfSection = [self.groupedArray indexOfSectionPassingTest:^BOOL(id section, NSUInteger index, BOOL *stop) {
        XCTAssertFalse(section == sectionX, @"Section X should never be passed in because stop is set to YES after finding Section W, which immediately precedes Section X.");
        if (section == sectionW) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];
    XCTAssertTrue(indexOfSection == 1, @"The index of Section W should be 1. (NSNotFound should not be returned because the index was found.)");
    
    // Setting stop to YES before passing the test should cause NSNotFound to be returned and no further sections to be tested
    __block NSUInteger blockExecutionCount = 0;
    indexOfSection = [self.groupedArray indexOfSectionPassingTest:^BOOL(id section, NSUInteger index, BOOL *stop) {
        blockExecutionCount++;
        *stop = YES;
        return NO;
    }];
    XCTAssertTrue(indexOfSection == NSNotFound, @"The section should not be found because the test never passed.");
    XCTAssertTrue(blockExecutionCount == 1, @"The block should only have executed once.");
}

/**
 Test the indexPathOfObjectPassingTest: method.
 */
- (void)testIndexPathOfObjectPassingTest
{
    INTUMutableGroupedArray *mutableGroupedArray = [INTUMutableGroupedArray groupedArray];
    [mutableGroupedArray addObject:objectE toSection:sectionY];
    [mutableGroupedArray addObject:objectB toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionY];
    [mutableGroupedArray addObject:objectC toSection:sectionY];
    [mutableGroupedArray addObject:objectA toSection:sectionW];
    [mutableGroupedArray addObject:objectF toSection:sectionX];
    [mutableGroupedArray addObject:objectD toSection:sectionZ];
    [mutableGroupedArray addObject:objectD toSection:sectionW];
    self.groupedArray = [mutableGroupedArray copy];
    
    NSIndexPath *indexPathOfObject;
    
    indexPathOfObject = [[INTUGroupedArray groupedArray] indexPathOfObjectPassingTest:^BOOL(id object, NSIndexPath *indexPath, BOOL *stop) {
        return YES;
    }];
    XCTAssertTrue(indexPathOfObject == nil, @"An empty grouped array should always return nil even when the test always passes.");
    
    indexPathOfObject = [self.groupedArray indexPathOfObjectPassingTest:^BOOL(id object, NSIndexPath *indexPath, BOOL *stop) {
        return NO;
    }];
    XCTAssertTrue(indexPathOfObject == nil, @"nil should be returned when the test always fails.");
    
    indexPathOfObject = [self.groupedArray indexPathOfObjectPassingTest:^BOOL(id object, NSIndexPath *indexPath, BOOL *stop) {
        return YES;
    }];
    XCTAssertEqualObjects(indexPathOfObject, [INTUGroupedArray indexPathForRow:0 inSection:0], @"The first object should be returned when the test always passes.");
    
    indexPathOfObject = [self.groupedArray indexPathOfObjectPassingTest:^BOOL(id object, NSIndexPath *indexPath, BOOL *stop) {
        return object == objectE;
    }];
    XCTAssertEqualObjects(indexPathOfObject, [INTUGroupedArray indexPathForRow:0 inSection:0], @"Object E should be at index path {Section 0, Row 0}.");
    
    indexPathOfObject = [self.groupedArray indexPathOfObjectPassingTest:^BOOL(id object, NSIndexPath *indexPath, BOOL *stop) {
        return object == objectC;
    }];
    XCTAssertEqualObjects(indexPathOfObject, [INTUGroupedArray indexPathForRow:3 inSection:0], @"Object C should be at index path {Section 0, Row 3}.");
    
    indexPathOfObject = [self.groupedArray indexPathOfObjectPassingTest:^BOOL(id object, NSIndexPath *indexPath, BOOL *stop) {
        return object == objectA;
    }];
    XCTAssertEqualObjects(indexPathOfObject, [INTUGroupedArray indexPathForRow:2 inSection:0], @"Object A should be at index path {Section 0, Row 2}.");
    
    indexPathOfObject = [self.groupedArray indexPathOfObjectPassingTest:^BOOL(id object, NSIndexPath *indexPath, BOOL *stop) {
        return object == objectD;
    }];
    XCTAssertEqualObjects(indexPathOfObject, [INTUGroupedArray indexPathForRow:1 inSection:1], @"Object D should be at index path {Section 1, Row 1}.");
    
    // Setting stop to YES after passing the test should cause the correct index path to be returned, but no further objects to be tested
    indexPathOfObject = [self.groupedArray indexPathOfObjectPassingTest:^BOOL(id object, NSIndexPath *indexPath, BOOL *stop) {
        XCTAssertFalse(object == objectA, @"Object A should never be passed in because stop is set to YES after finding Object B, which immediately precedes Object A.");
        if (object == objectB) {
            *stop = YES;
            return YES;
        } else {
            return NO;
        }
    }];
    XCTAssertEqualObjects(indexPathOfObject, [INTUGroupedArray indexPathForRow:1 inSection:0], @"Object B should be at index path {Section 0, Row 1}. (nil should not be returned because the index was found.)");
    
    // Setting stop to YES before passing the test should cause nil to be returned and no further sections to be tested
    __block NSUInteger blockExecutionCount = 0;
    indexPathOfObject = [self.groupedArray indexPathOfObjectPassingTest:^BOOL(id object, NSIndexPath *indexPath, BOOL *stop) {
        blockExecutionCount++;
        *stop = YES;
        return NO;
    }];
    XCTAssertTrue(indexPathOfObject == nil, @"The object should not be found because the test never passed.");
    XCTAssertTrue(blockExecutionCount == 1, @"The block should only have executed once.");
}

/**
 Test the isEqual: method.
 */
- (void)testIsEqual
{
    // Test passing nil
    XCTAssertFalse([self.groupedArray isEqual:nil], @"Comparing any grouped array to nil should return NO.");
    
    // Test passing instances of other classes
    XCTAssertFalse([self.groupedArray isEqual:@"Test"], @"Comparing any grouped array to a different class should return NO.");
    XCTAssertFalse([self.groupedArray isEqual:[NSArray new]], @"Comparing any grouped array to a different class should return NO.");
    XCTAssertFalse([self.groupedArray isEqual:[NSMutableDictionary new]], @"Comparing any grouped array to a different class should return NO.");
    
    // Test empty arrays
    INTUGroupedArray *otherGroupedArray = [INTUGroupedArray groupedArray];
    XCTAssert([self.groupedArray isEqual:otherGroupedArray], @"Two empty arrays should be equal.");
    XCTAssert([otherGroupedArray isEqual:self.groupedArray], @"Two empty arrays should be equal.");
    
    INTUMutableGroupedArray *mutable1 = [INTUMutableGroupedArray groupedArray];
    INTUMutableGroupedArray *mutable2 = [INTUMutableGroupedArray groupedArray];
    
    // Test different counts
    [mutable1 addObject:objectD toSection:sectionW];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssertFalse([self.groupedArray isEqual:otherGroupedArray]);
    XCTAssertFalse([otherGroupedArray isEqual:self.groupedArray]);
    
    // Test identical with single object & section
    [mutable2 addObject:objectD toSection:sectionW];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssert([self.groupedArray isEqual:otherGroupedArray]);
    XCTAssert([otherGroupedArray isEqual:self.groupedArray]);
    
    [mutable1 removeAllObjects];
    [mutable2 removeAllObjects];
    // Test same count, same object, different sections
    [mutable1 addObject:objectA toSection:sectionX];
    [mutable2 addObject:objectA toSection:sectionZ];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssertFalse([self.groupedArray isEqual:otherGroupedArray]);
    XCTAssertFalse([otherGroupedArray isEqual:self.groupedArray]);
    
    // Test same objects and sections but different section order
    [mutable1 addObject:objectA toSection:sectionZ];
    [mutable2 addObject:objectA toSection:sectionX];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssertFalse([self.groupedArray isEqual:otherGroupedArray]);
    XCTAssertFalse([otherGroupedArray isEqual:self.groupedArray]);
    
    [mutable1 removeAllObjects];
    [mutable2 removeAllObjects];
    // Test same objects and sections but different object order
    [mutable1 addObject:objectA toSection:sectionX];
    [mutable1 addObject:objectB toSection:sectionX];
    [mutable2 addObject:objectB toSection:sectionX];
    [mutable2 addObject:objectA toSection:sectionX];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssertFalse([self.groupedArray isEqual:otherGroupedArray]);
    XCTAssertFalse([otherGroupedArray isEqual:self.groupedArray]);
    
    // Test with some more random data
    [self addUnsortedSectionsAndObjects];
    otherGroupedArray = [self.groupedArray copy];
    XCTAssert([self.groupedArray isEqual:otherGroupedArray]);
    XCTAssert([otherGroupedArray isEqual:self.groupedArray]);
    
    otherGroupedArray = [self.groupedArray mutableCopy];
    otherGroupedArray = [otherGroupedArray copy];
    XCTAssert([self.groupedArray isEqual:otherGroupedArray]);
    XCTAssert([otherGroupedArray isEqual:self.groupedArray]);
}

/**
 Test the isEqualToGroupedArray: method.
 */
- (void)testIsEqualToGroupedArray
{
    // Test passing nil
    XCTAssertFalse([self.groupedArray isEqualToGroupedArray:nil], @"Comparing any grouped array to nil should return NO.");
    
    // Test empty arrays
    INTUGroupedArray *otherGroupedArray = [INTUGroupedArray groupedArray];
    XCTAssert([self.groupedArray isEqualToGroupedArray:otherGroupedArray], @"Two empty arrays should be equal.");
    XCTAssert([otherGroupedArray isEqualToGroupedArray:self.groupedArray], @"Two empty arrays should be equal.");
    
    INTUMutableGroupedArray *mutable1 = [INTUMutableGroupedArray groupedArray];
    INTUMutableGroupedArray *mutable2 = [INTUMutableGroupedArray groupedArray];
    
    // Test different counts
    [mutable1 addObject:objectD toSection:sectionW];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssertFalse([self.groupedArray isEqualToGroupedArray:otherGroupedArray]);
    XCTAssertFalse([otherGroupedArray isEqualToGroupedArray:self.groupedArray]);
    
    // Test identical with single object & section
    [mutable2 addObject:objectD toSection:sectionW];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssert([self.groupedArray isEqualToGroupedArray:otherGroupedArray]);
    XCTAssert([otherGroupedArray isEqualToGroupedArray:self.groupedArray]);
    
    [mutable1 removeAllObjects];
    [mutable2 removeAllObjects];
    // Test same count, same object, different sections
    [mutable1 addObject:objectA toSection:sectionX];
    [mutable2 addObject:objectA toSection:sectionZ];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssertFalse([self.groupedArray isEqualToGroupedArray:otherGroupedArray]);
    XCTAssertFalse([otherGroupedArray isEqualToGroupedArray:self.groupedArray]);
    
    // Test same objects and sections but different section order
    [mutable1 addObject:objectA toSection:sectionZ];
    [mutable2 addObject:objectA toSection:sectionX];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssertFalse([self.groupedArray isEqualToGroupedArray:otherGroupedArray]);
    XCTAssertFalse([otherGroupedArray isEqualToGroupedArray:self.groupedArray]);
    
    [mutable1 removeAllObjects];
    [mutable2 removeAllObjects];
    // Test same objects and sections but different object order
    [mutable1 addObject:objectA toSection:sectionX];
    [mutable1 addObject:objectB toSection:sectionX];
    [mutable2 addObject:objectB toSection:sectionX];
    [mutable2 addObject:objectA toSection:sectionX];
    self.groupedArray = [mutable1 copy];
    otherGroupedArray = [mutable2 copy];
    XCTAssertFalse([self.groupedArray isEqualToGroupedArray:otherGroupedArray]);
    XCTAssertFalse([otherGroupedArray isEqualToGroupedArray:self.groupedArray]);
    
    // Test with some more random data
    [self addUnsortedSectionsAndObjects];
    otherGroupedArray = [self.groupedArray copy];
    XCTAssert([self.groupedArray isEqualToGroupedArray:otherGroupedArray]);
    XCTAssert([otherGroupedArray isEqualToGroupedArray:self.groupedArray]);
    
    otherGroupedArray = [self.groupedArray mutableCopy];
    otherGroupedArray = [otherGroupedArray copy];
    XCTAssert([self.groupedArray isEqualToGroupedArray:otherGroupedArray]);
    XCTAssert([otherGroupedArray isEqualToGroupedArray:self.groupedArray]);
}

/**
 Test the filteredGroupedArrayUsingSectionPredicate:sectionPredicate: method.
 */
- (void)testFilteredGroupedArrayUsingSectionPredicate
{
    [self addUnsortedSectionsAndObjects];
    
    INTUGroupedArray *original = [self.groupedArray copy];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return evaluatedObject == sectionZ;
    }];
    
    XCTAssert([self.groupedArray countAllSections] == 4, @"There should be 4 sections.");
    XCTAssert([self.groupedArray countAllObjects] == 8, @"There should be 8 objects.");
    XCTAssert([self.groupedArray containsSection:sectionW], @"Section W should exist.");
    XCTAssert([self.groupedArray containsSection:sectionX], @"Section X should exist.");
    XCTAssert([self.groupedArray containsSection:sectionY], @"Section Y should exist.");
    XCTAssert([self.groupedArray containsSection:sectionZ], @"Section Z should exist.");
    
    INTUGroupedArray *filtered = [self.groupedArray filteredGroupedArrayUsingSectionPredicate:predicate objectPredicate:nil];
    
    XCTAssert([filtered countAllSections] == 1, @"There should be 1 section.");
    XCTAssert([filtered countAllObjects] == 1, @"There should be 1 object.");
    XCTAssertFalse([filtered containsSection:sectionW], @"Section Y should not exist.");
    XCTAssertFalse([filtered containsSection:sectionX], @"Section Y should not exist.");
    XCTAssertFalse([filtered containsSection:sectionY], @"Section Y should not exist.");
    XCTAssert([filtered containsSection:sectionZ], @"Section Z should exist.");
    
    XCTAssert([self.groupedArray isEqual:original], @"The original grouped array should not be modified after returning a filtered version.");
}

/**
 Test the filteredGroupedArrayUsingSectionPredicate:sectionPredicate: method.
 */
- (void)testFilteredGroupedArrayUsingObjectPredicate
{
    [self addUnsortedSectionsAndObjects];
    
    INTUGroupedArray *original = [self.groupedArray copy];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return evaluatedObject == objectA;
    }];
    
    XCTAssert([self.groupedArray countAllSections] == 4, @"There should be 4 sections.");
    XCTAssert([self.groupedArray countAllObjects] == 8, @"There should be 8 objects.");
    XCTAssert([self.groupedArray containsSection:sectionW], @"Section W should exist.");
    XCTAssert([self.groupedArray containsSection:sectionX], @"Section X should exist.");
    XCTAssert([self.groupedArray containsSection:sectionY], @"Section Y should exist.");
    XCTAssert([self.groupedArray containsSection:sectionZ], @"Section Z should exist.");
    XCTAssert([self.groupedArray containsObject:objectA], @"Object A should exist.");
    XCTAssert([self.groupedArray containsObject:objectB], @"Object B should exist.");
    XCTAssert([self.groupedArray containsObject:objectC], @"Object C should exist.");
    XCTAssert([self.groupedArray containsObject:objectD], @"Object D should exist.");
    XCTAssert([self.groupedArray containsObject:objectE], @"Object E should exist.");
    XCTAssert([self.groupedArray containsObject:objectF], @"Object F should exist.");
    
    INTUGroupedArray *filtered = [self.groupedArray filteredGroupedArrayUsingSectionPredicate:nil objectPredicate:predicate];
    
    XCTAssert([filtered countAllSections] == 2, @"There should be 2 sections.");
    XCTAssert([filtered countAllObjects] == 2, @"There should be 2 objects.");
    XCTAssert([filtered containsSection:sectionW], @"Section Y should exist.");
    XCTAssertFalse([filtered containsSection:sectionX], @"Section Y should not exist.");
    XCTAssert([filtered containsSection:sectionY], @"Section Y should exist.");
    XCTAssertFalse([filtered containsSection:sectionZ], @"Section Z should not exist.");
    XCTAssert([filtered containsObject:objectA], @"Object A should exist.");
    XCTAssertFalse([filtered containsObject:objectB], @"Object B should not exist.");
    XCTAssertFalse([filtered containsObject:objectC], @"Object C should not exist.");
    XCTAssertFalse([filtered containsObject:objectD], @"Object D should not exist.");
    XCTAssertFalse([filtered containsObject:objectE], @"Object E should not exist.");
    XCTAssertFalse([filtered containsObject:objectF], @"Object F should not exist.");
    
    XCTAssert([self.groupedArray isEqual:original], @"The original grouped array should not be modified after returning a filtered version.");
}

/**
 Test the filteredGroupedArrayUsingSectionPredicate:sectionPredicate: method.
 */
- (void)testFilteredGroupedArrayUsingUsingSectionPredicateObjectPredicate
{
    [self addUnsortedSectionsAndObjects];
    
    INTUGroupedArray *original = [self.groupedArray copy];
    
    NSPredicate *sectionPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return evaluatedObject == sectionZ;
    }];
    
    NSPredicate *objectPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return evaluatedObject == objectA;
    }];
    
    XCTAssert([self.groupedArray countAllSections] == 4, @"There should be 4 sections.");
    XCTAssert([self.groupedArray countAllObjects] == 8, @"There should be 8 objects.");
    XCTAssert([self.groupedArray containsSection:sectionW], @"Section W should exist.");
    XCTAssert([self.groupedArray containsSection:sectionX], @"Section X should exist.");
    XCTAssert([self.groupedArray containsSection:sectionY], @"Section Y should exist.");
    XCTAssert([self.groupedArray containsSection:sectionZ], @"Section Z should exist.");
    XCTAssert([self.groupedArray containsObject:objectA], @"Object A should exist.");
    XCTAssert([self.groupedArray containsObject:objectB], @"Object B should exist.");
    XCTAssert([self.groupedArray containsObject:objectC], @"Object C should exist.");
    XCTAssert([self.groupedArray containsObject:objectD], @"Object D should exist.");
    XCTAssert([self.groupedArray containsObject:objectE], @"Object E should exist.");
    XCTAssert([self.groupedArray containsObject:objectF], @"Object F should exist.");
    
    INTUGroupedArray *filtered = [self.groupedArray filteredGroupedArrayUsingSectionPredicate:sectionPredicate objectPredicate:objectPredicate];
    
    XCTAssert([filtered countAllSections] == 0);
    XCTAssert([filtered countAllObjects] == 0);
    
    XCTAssert([self.groupedArray isEqual:original], @"The original grouped array should not be modified after returning a filtered version.");
}

/**
 Test the sortedGroupedArrayUsingSectionComparator:objectComparator: method.
 */
- (void)testSortedGroupedArray
{
    [self addUnsortedSectionsAndObjects];
    
    INTUGroupedArray *sortedResult;
    
    sortedResult = [self.groupedArray sortedGroupedArrayUsingSectionComparator:nil objectComparator:nil];
    XCTAssert([self.groupedArray isEqualToGroupedArray:sortedResult]);
    
    sortedResult = [self.groupedArray sortedGroupedArrayUsingSectionComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) { return [obj1 compare:obj2]; }
                                                              objectComparator:nil];
    
    XCTAssertEqual(sectionW, [sortedResult sectionAtIndex:0], @"Sections should be sorted.");
    XCTAssertTrue([sortedResult countObjectsInSection:sectionW] == 2, @"There should be 2 objects in sectionW.");
    XCTAssertEqual(sectionX, [sortedResult sectionAtIndex:1], @"Sections should be sorted.");
    XCTAssertTrue([sortedResult countObjectsInSection:sectionX] == 1, @"There should be 1 objects in sectionX.");
    XCTAssertEqual(sectionY, [sortedResult sectionAtIndex:2], @"Sections should be sorted.");
    XCTAssertTrue([sortedResult countObjectsInSection:sectionY] == 4, @"There should be 4 objects in sectionY.");
    XCTAssertEqual(sectionZ, [sortedResult sectionAtIndex:3], @"Sections should be sorted.");
    XCTAssertTrue([sortedResult countObjectsInSection:sectionZ] == 1, @"There should be 1 objects in sectionZ.");
    
    sortedResult = [self.groupedArray sortedGroupedArrayUsingSectionComparator:nil
                                                              objectComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) { return [obj1 compare:obj2]; }];
    
    XCTAssertEqual(objectA, [sortedResult objectAtIndex:0 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectB, [sortedResult objectAtIndex:1 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectC, [sortedResult objectAtIndex:2 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectE, [sortedResult objectAtIndex:3 inSection:sectionY], @"Objects should be sorted.");
    
    sortedResult = [self.groupedArray sortedGroupedArrayUsingSectionComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) { return [obj1 compare:obj2]; }
                                                              objectComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) { return [obj1 compare:obj2]; }];
    
    XCTAssertEqual(sectionW, [sortedResult sectionAtIndex:0], @"Sections should be sorted.");
    XCTAssertTrue([sortedResult countObjectsInSection:sectionW] == 2, @"There should be 2 objects in sectionW.");
    XCTAssertEqual(sectionX, [sortedResult sectionAtIndex:1], @"Sections should be sorted.");
    XCTAssertTrue([sortedResult countObjectsInSection:sectionX] == 1, @"There should be 1 objects in sectionX.");
    XCTAssertEqual(sectionY, [sortedResult sectionAtIndex:2], @"Sections should be sorted.");
    XCTAssertTrue([sortedResult countObjectsInSection:sectionY] == 4, @"There should be 4 objects in sectionY.");
    XCTAssertEqual(sectionZ, [sortedResult sectionAtIndex:3], @"Sections should be sorted.");
    XCTAssertTrue([sortedResult countObjectsInSection:sectionZ] == 1, @"There should be 1 objects in sectionZ.");
    XCTAssertEqual(objectA, [sortedResult objectAtIndex:0 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectB, [sortedResult objectAtIndex:1 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectC, [sortedResult objectAtIndex:2 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectE, [sortedResult objectAtIndex:3 inSection:sectionY], @"Objects should be sorted.");
}

- (void)testObjectEnumerator
{
    [self addUnsortedSectionsAndObjects];
    
    NSArray *allObjects = [self.groupedArray allObjects];
    NSEnumerator *e;
    
    // Test that calling allObjects on the enumerator matches all objects
    e = [self.groupedArray objectEnumerator];
    XCTAssert([allObjects isEqualToArray:[e allObjects]]);
    
    // Test that calling nextObject on the above enumerator now returns nil
    XCTAssert([e nextObject] == nil);
    // Test that calling allObjects on the above enumerator now returns an empty array of count 0
    NSArray *eAllObjects = [e allObjects];
    XCTAssert(eAllObjects && [eAllObjects count] == 0);
    // Test that using fast enumeration on the above enumerator does not execute at all
    for (id __unused obj in e) {
        XCTAssert(nil, @"This loop should not execute.");
    }
    
    // Test that calling nextObject on the enumerator in a loop matches all objects
    e = [self.groupedArray objectEnumerator];
    id object = nil;
    NSMutableArray *enumeratorObjects = [NSMutableArray new];
    while (object = [e nextObject]) {
        [enumeratorObjects addObject:object];
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that using fast enumeration on the above enumerator does not execute at all
    for (id __unused obj in e) {
        XCTAssert(nil, @"This loop should not execute.");
    }
    // Test that calling allObjects on the above enumerator now returns an empty array of count 0
    eAllObjects = [e allObjects];
    XCTAssert(eAllObjects && [eAllObjects count] == 0);
    
    // Test that using fast enumeration on the enumerator matches standard fast enumeration output
    e = [self.groupedArray objectEnumerator];
    enumeratorObjects = [NSMutableArray new];
    for (id obj in e) {
        [enumeratorObjects addObject:obj];
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that calling nextObject one or more times before using fast enumeration retains the state for the enumerator (fast enum. should only pull remaining objects)
    e = [self.groupedArray objectEnumerator];
    [e nextObject];
    [e nextObject];
    NSUInteger skipped = 2;
    enumeratorObjects = [NSMutableArray new];
    for (id obj in e) {
        [enumeratorObjects addObject:obj];
    }
    XCTAssert(enumeratorObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:enumeratorObjects[i - skipped]]);
    }
    
    // Test that calling nextObject one or more times before using allObjects retains the state for the enumerator (nextObject should only pull remaining objects)
    e = [self.groupedArray objectEnumerator];
    [e nextObject];
    skipped = 1;
    NSArray *eObjects = [e allObjects];
    XCTAssert(eObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:eObjects[i - skipped]]);
    }
    
    // Test that breaking out of fast enumeration after 1 loop still causes nextObject to work correctly (not skipping any objects)
    e = [self.groupedArray objectEnumerator];
    for (id __unused obj in e) {
        break;
    }
    enumeratorObjects = [NSMutableArray new];
    object = nil;
    while (object = [e nextObject]) {
        [enumeratorObjects addObject:object];
    }
    skipped = 1;
    XCTAssert(enumeratorObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:enumeratorObjects[i - skipped]]);
    }
    
    // Test that breaking out of fast enumeration after 1 loop still causes the next fast enumeration call to work correctly (not skipping any objects)
    e = [self.groupedArray objectEnumerator];
    enumeratorObjects = [NSMutableArray new];
    for (NSUInteger i = 0; i < allObjects.count; i++) {
        for (id obj in e) {
            [enumeratorObjects addObject:obj];
            break;
        }
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that breaking out of fast enumeration after 1 loop still causes allObjects to work correctly (not skipping any objects)
    e = [self.groupedArray objectEnumerator];
    for (id __unused obj in e) {
        break;
    }
    skipped = 1;
    eObjects = [e allObjects];
    XCTAssert(eObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:eObjects[i - skipped]]);
    }
    
    // Test that 2 different enumerators used at the same time maintain independent state
    NSEnumerator *e1 = [self.groupedArray objectEnumerator];
    NSEnumerator *e2 = [self.groupedArray objectEnumerator];
    id firstObject = [e1 nextObject];
    id secondObject = [e1 nextObject];
    XCTAssert([[e2 nextObject] isEqual:firstObject]);
    id thirdObject = [e1 nextObject];
    XCTAssert([[e2 nextObject] isEqual:secondObject]);
    XCTAssert([[e2 nextObject] isEqual:thirdObject]);
    id fourthObject = [e2 nextObject];
    XCTAssert([[e1 nextObject] isEqual:fourthObject]);
}

- (void)testReverseObjectEnumerator
{
    [self addUnsortedSectionsAndObjects];
    
    NSArray *allObjects = [[[self.groupedArray allObjects] reverseObjectEnumerator] allObjects];
    NSEnumerator *e;
    
    // Test that calling allObjects on the enumerator matches all objects
    e = [self.groupedArray reverseObjectEnumerator];
    XCTAssert([allObjects isEqualToArray:[e allObjects]]);
    
    // Test that calling nextObject on the above enumerator now returns nil
    XCTAssert([e nextObject] == nil);
    // Test that calling allObjects on the above enumerator now returns an empty array of count 0
    NSArray *eAllObjects = [e allObjects];
    XCTAssert(eAllObjects && [eAllObjects count] == 0);
    // Test that using fast enumeration on the above enumerator does not execute at all
    for (id __unused obj in e) {
        XCTAssert(nil, @"This loop should not execute.");
    }
    
    // Test that calling nextObject on the enumerator in a loop matches all objects
    e = [self.groupedArray reverseObjectEnumerator];
    id object = nil;
    NSMutableArray *enumeratorObjects = [NSMutableArray new];
    while (object = [e nextObject]) {
        [enumeratorObjects addObject:object];
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that using fast enumeration on the above enumerator does not execute at all
    for (id __unused obj in e) {
        XCTAssert(nil, @"This loop should not execute.");
    }
    // Test that calling allObjects on the above enumerator now returns an empty array of count 0
    eAllObjects = [e allObjects];
    XCTAssert(eAllObjects && [eAllObjects count] == 0);
    
    // Test that using fast enumeration on the enumerator matches standard fast enumeration output
    e = [self.groupedArray reverseObjectEnumerator];
    enumeratorObjects = [NSMutableArray new];
    for (id obj in e) {
        [enumeratorObjects addObject:obj];
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that calling nextObject one or more times before using fast enumeration retains the state for the enumerator (fast enum. should only pull remaining objects)
    e = [self.groupedArray reverseObjectEnumerator];
    [e nextObject];
    [e nextObject];
    NSUInteger skipped = 2;
    enumeratorObjects = [NSMutableArray new];
    for (id obj in e) {
        [enumeratorObjects addObject:obj];
    }
    XCTAssert(enumeratorObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:enumeratorObjects[i - skipped]]);
    }
    
    // Test that calling nextObject one or more times before using allObjects retains the state for the enumerator (nextObject should only pull remaining objects)
    e = [self.groupedArray reverseObjectEnumerator];
    [e nextObject];
    skipped = 1;
    NSArray *eObjects = [e allObjects];
    XCTAssert(eObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:eObjects[i - skipped]]);
    }
    
    // Test that breaking out of fast enumeration after 1 loop still causes nextObject to work correctly (not skipping any objects)
    e = [self.groupedArray reverseObjectEnumerator];
    for (id __unused obj in e) {
        break;
    }
    enumeratorObjects = [NSMutableArray new];
    object = nil;
    while (object = [e nextObject]) {
        [enumeratorObjects addObject:object];
    }
    skipped = 1;
    XCTAssert(enumeratorObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:enumeratorObjects[i - skipped]]);
    }
    
    // Test that breaking out of fast enumeration after 1 loop still causes the next fast enumeration call to work correctly (not skipping any objects)
    e = [self.groupedArray reverseObjectEnumerator];
    enumeratorObjects = [NSMutableArray new];
    for (NSUInteger i = 0; i < allObjects.count; i++) {
        for (id obj in e) {
            [enumeratorObjects addObject:obj];
            break;
        }
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that breaking out of fast enumeration after 1 loop still causes allObjects to work correctly (not skipping any objects)
    e = [self.groupedArray reverseObjectEnumerator];
    for (id __unused obj in e) {
        break;
    }
    skipped = 1;
    eObjects = [e allObjects];
    XCTAssert(eObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:eObjects[i - skipped]]);
    }
    
    // Test that 2 different enumerators used at the same time maintain independent state
    NSEnumerator *e1 = [self.groupedArray reverseObjectEnumerator];
    NSEnumerator *e2 = [self.groupedArray reverseObjectEnumerator];
    id firstObject = [e1 nextObject];
    id secondObject = [e1 nextObject];
    XCTAssert([[e2 nextObject] isEqual:firstObject]);
    id thirdObject = [e1 nextObject];
    XCTAssert([[e2 nextObject] isEqual:secondObject]);
    XCTAssert([[e2 nextObject] isEqual:thirdObject]);
    id fourthObject = [e2 nextObject];
    XCTAssert([[e1 nextObject] isEqual:fourthObject]);
}

- (void)testSectionEnumerator
{
    [self addUnsortedSectionsAndObjects];
    
    NSArray *allObjects = [self.groupedArray allSections];
    NSEnumerator *e;
    
    // Test that calling allObjects on the enumerator matches all objects
    e = [self.groupedArray sectionEnumerator];
    XCTAssert([allObjects isEqualToArray:[e allObjects]]);
    
    // Test that calling nextObject on the above enumerator now returns nil
    XCTAssert([e nextObject] == nil);
    // Test that calling allObjects on the above enumerator now returns an empty array of count 0
    NSArray *eAllObjects = [e allObjects];
    XCTAssert(eAllObjects && [eAllObjects count] == 0);
    // Test that using fast enumeration on the above enumerator does not execute at all
    for (id __unused obj in e) {
        XCTAssert(nil, @"This loop should not execute.");
    }
    
    // Test that calling nextObject on the enumerator in a loop matches all objects
    e = [self.groupedArray sectionEnumerator];
    id object = nil;
    NSMutableArray *enumeratorObjects = [NSMutableArray new];
    while (object = [e nextObject]) {
        [enumeratorObjects addObject:object];
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that using fast enumeration on the above enumerator does not execute at all
    for (id __unused obj in e) {
        XCTAssert(nil, @"This loop should not execute.");
    }
    // Test that calling allObjects on the above enumerator now returns an empty array of count 0
    eAllObjects = [e allObjects];
    XCTAssert(eAllObjects && [eAllObjects count] == 0);
    
    // Test that using fast enumeration on the enumerator matches standard fast enumeration output
    e = [self.groupedArray sectionEnumerator];
    enumeratorObjects = [NSMutableArray new];
    for (id obj in e) {
        [enumeratorObjects addObject:obj];
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that calling nextObject one or more times before using fast enumeration retains the state for the enumerator (fast enum. should only pull remaining objects)
    e = [self.groupedArray sectionEnumerator];
    [e nextObject];
    [e nextObject];
    NSUInteger skipped = 2;
    enumeratorObjects = [NSMutableArray new];
    for (id obj in e) {
        [enumeratorObjects addObject:obj];
    }
    XCTAssert(enumeratorObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:enumeratorObjects[i - skipped]]);
    }
    
    // Test that calling nextObject one or more times before using allObjects retains the state for the enumerator (nextObject should only pull remaining objects)
    e = [self.groupedArray sectionEnumerator];
    [e nextObject];
    skipped = 1;
    NSArray *eObjects = [e allObjects];
    XCTAssert(eObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:eObjects[i - skipped]]);
    }
    
    // Test that breaking out of fast enumeration after 1 loop still causes nextObject to work correctly (not skipping any objects)
    e = [self.groupedArray sectionEnumerator];
    for (id __unused obj in e) {
        break;
    }
    enumeratorObjects = [NSMutableArray new];
    object = nil;
    while (object = [e nextObject]) {
        [enumeratorObjects addObject:object];
    }
    skipped = 1;
    XCTAssert(enumeratorObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:enumeratorObjects[i - skipped]]);
    }
    
    // Test that breaking out of fast enumeration after 1 loop still causes the next fast enumeration call to work correctly (not skipping any objects)
    e = [self.groupedArray sectionEnumerator];
    enumeratorObjects = [NSMutableArray new];
    for (NSUInteger i = 0; i < allObjects.count; i++) {
        for (id obj in e) {
            [enumeratorObjects addObject:obj];
            break;
        }
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that breaking out of fast enumeration after 1 loop still causes allObjects to work correctly (not skipping any objects)
    e = [self.groupedArray sectionEnumerator];
    for (id __unused obj in e) {
        break;
    }
    skipped = 1;
    eObjects = [e allObjects];
    XCTAssert(eObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:eObjects[i - skipped]]);
    }
    
    // Test that 2 different enumerators used at the same time maintain independent state
    NSEnumerator *e1 = [self.groupedArray sectionEnumerator];
    NSEnumerator *e2 = [self.groupedArray sectionEnumerator];
    id firstObject = [e1 nextObject];
    id secondObject = [e1 nextObject];
    XCTAssert([[e2 nextObject] isEqual:firstObject]);
    id thirdObject = [e1 nextObject];
    XCTAssert([[e2 nextObject] isEqual:secondObject]);
    XCTAssert([[e2 nextObject] isEqual:thirdObject]);
    id fourthObject = [e2 nextObject];
    XCTAssert([[e1 nextObject] isEqual:fourthObject]);
}

- (void)testReverseSectionEnumerator
{
    [self addUnsortedSectionsAndObjects];
    
    NSArray *allObjects = [[[self.groupedArray allSections] reverseObjectEnumerator] allObjects];
    NSEnumerator *e;
    
    // Test that calling allObjects on the enumerator matches all objects
    e = [self.groupedArray reverseSectionEnumerator];
    XCTAssert([allObjects isEqualToArray:[e allObjects]]);
    
    // Test that calling nextObject on the above enumerator now returns nil
    XCTAssert([e nextObject] == nil);
    // Test that calling allObjects on the above enumerator now returns an empty array of count 0
    NSArray *eAllObjects = [e allObjects];
    XCTAssert(eAllObjects && [eAllObjects count] == 0);
    // Test that using fast enumeration on the above enumerator does not execute at all
    for (id __unused obj in e) {
        XCTAssert(nil, @"This loop should not execute.");
    }
    
    // Test that calling nextObject on the enumerator in a loop matches all objects
    e = [self.groupedArray reverseSectionEnumerator];
    id object = nil;
    NSMutableArray *enumeratorObjects = [NSMutableArray new];
    while (object = [e nextObject]) {
        [enumeratorObjects addObject:object];
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that using fast enumeration on the above enumerator does not execute at all
    for (id __unused obj in e) {
        XCTAssert(nil, @"This loop should not execute.");
    }
    // Test that calling allObjects on the above enumerator now returns an empty array of count 0
    eAllObjects = [e allObjects];
    XCTAssert(eAllObjects && [eAllObjects count] == 0);
    
    // Test that using fast enumeration on the enumerator matches standard fast enumeration output
    e = [self.groupedArray reverseSectionEnumerator];
    enumeratorObjects = [NSMutableArray new];
    for (id obj in e) {
        [enumeratorObjects addObject:obj];
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that calling nextObject one or more times before using fast enumeration retains the state for the enumerator (fast enum. should only pull remaining objects)
    e = [self.groupedArray reverseSectionEnumerator];
    [e nextObject];
    [e nextObject];
    NSUInteger skipped = 2;
    enumeratorObjects = [NSMutableArray new];
    for (id obj in e) {
        [enumeratorObjects addObject:obj];
    }
    XCTAssert(enumeratorObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:enumeratorObjects[i - skipped]]);
    }
    
    // Test that calling nextObject one or more times before using allObjects retains the state for the enumerator (nextObject should only pull remaining objects)
    e = [self.groupedArray reverseSectionEnumerator];
    [e nextObject];
    skipped = 1;
    NSArray *eObjects = [e allObjects];
    XCTAssert(eObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:eObjects[i - skipped]]);
    }
    
    // Test that breaking out of fast enumeration after 1 loop still causes nextObject to work correctly (not skipping any objects)
    e = [self.groupedArray reverseSectionEnumerator];
    for (id __unused obj in e) {
        break;
    }
    enumeratorObjects = [NSMutableArray new];
    object = nil;
    while (object = [e nextObject]) {
        [enumeratorObjects addObject:object];
    }
    skipped = 1;
    XCTAssert(enumeratorObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:enumeratorObjects[i - skipped]]);
    }
    
    // Test that breaking out of fast enumeration after 1 loop still causes the next fast enumeration call to work correctly (not skipping any objects)
    e = [self.groupedArray reverseSectionEnumerator];
    enumeratorObjects = [NSMutableArray new];
    for (NSUInteger i = 0; i < allObjects.count; i++) {
        for (id obj in e) {
            [enumeratorObjects addObject:obj];
            break;
        }
    }
    XCTAssert([allObjects isEqualToArray:enumeratorObjects]);
    
    // Test that breaking out of fast enumeration after 1 loop still causes allObjects to work correctly (not skipping any objects)
    e = [self.groupedArray reverseSectionEnumerator];
    for (id __unused obj in e) {
        break;
    }
    skipped = 1;
    eObjects = [e allObjects];
    XCTAssert(eObjects.count == allObjects.count - skipped);
    for (NSUInteger i = skipped; i < allObjects.count; i++) {
        XCTAssert([allObjects[i] isEqual:eObjects[i - skipped]]);
    }
    
    // Test that 2 different enumerators used at the same time maintain independent state
    NSEnumerator *e1 = [self.groupedArray reverseSectionEnumerator];
    NSEnumerator *e2 = [self.groupedArray reverseSectionEnumerator];
    id firstObject = [e1 nextObject];
    id secondObject = [e1 nextObject];
    XCTAssert([[e2 nextObject] isEqual:firstObject]);
    id thirdObject = [e1 nextObject];
    XCTAssert([[e2 nextObject] isEqual:secondObject]);
    XCTAssert([[e2 nextObject] isEqual:thirdObject]);
    id fourthObject = [e2 nextObject];
    XCTAssert([[e1 nextObject] isEqual:fourthObject]);
}

@end

#pragma clang diagnostic pop
