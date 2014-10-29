//
//  INTUMutableGroupedArrayTests.m
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

#import <XCTest/XCTest.h>
#import "INTUGroupedArrayImports.h"
#import <libkern/OSAtomic.h>

@interface INTUMutableGroupedArrayTests : XCTestCase

@property (nonatomic, strong) INTUMutableGroupedArray *groupedArray;

@end

/**
 Unit tests for the INTUMutableGroupedArray class.
 */
@implementation INTUMutableGroupedArrayTests

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
    for (NSUInteger section = 0; section < numberOfSections; section++) {
        for (NSUInteger object = 0; object < numberOfObjects; object++) {
            [self.groupedArray addObject:@(object) toSection:[NSString stringWithFormat:@"Section %lu", (unsigned long) section]];
        }
    }
}

/**
 Test the grouped array's literal syntax.
 */
- (void)testLiteralSyntax
{
    INTUMutableGroupedArray *groupedArray;
    
    // Test an empty grouped array
    groupedArray = [INTUMutableGroupedArray literal:@[]];
    XCTAssertNotNil(groupedArray);
    XCTAssert([groupedArray isMemberOfClass:[INTUMutableGroupedArray class]]);
    XCTAssert([groupedArray countAllSections] == 0);
    XCTAssert([groupedArray countAllObjects] == 0);
    
    // Test a valid simple grouped array
    groupedArray = [INTUMutableGroupedArray literal:@[sectionW, @[objectA]]];
    XCTAssert([groupedArray isMemberOfClass:[INTUMutableGroupedArray class]]);
    XCTAssert([groupedArray countAllSections] == 1);
    XCTAssert([groupedArray countAllObjects] == 1);
    XCTAssert([groupedArray sectionAtIndex:0] == sectionW);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    
    // Test a valid grouped array that has some repeating objects
    groupedArray = [INTUMutableGroupedArray literal:@[sectionW, @[objectA],
                                                      sectionX, @[objectB, objectA, objectA]
                                                      ]];
    XCTAssert([groupedArray isMemberOfClass:[INTUMutableGroupedArray class]]);
    XCTAssert([groupedArray countAllSections] == 2);
    XCTAssert([groupedArray countAllObjects] == 4);
    XCTAssert([groupedArray sectionAtIndex:0] == sectionW);
    XCTAssert([groupedArray sectionAtIndex:1] == sectionX);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]] == objectB);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:1]] == objectA);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:1]] == objectA);
    
    // Test a "dumb" but still valid grouped array
    groupedArray = [INTUMutableGroupedArray literal:@[@[], @[objectA]]];
    XCTAssert([groupedArray isMemberOfClass:[INTUMutableGroupedArray class]]);
    XCTAssert([groupedArray countAllSections] == 1);
    XCTAssert([groupedArray countAllObjects] == 1);
    XCTAssert([[groupedArray sectionAtIndex:0] isEqual:@[]]);
    XCTAssert([groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    
    NSArray *literal; // for some reason the compiler doesn't like certain literals inside the XCTAssertThrows macro
    
    // Test an invalid nil literal
    XCTAssertThrows([INTUGroupedArray literal:nil]);
    
    // Test an invalid grouped array with an empty array of objects
    literal = @[sectionW, @[]];
    XCTAssertThrows([INTUMutableGroupedArray literal:literal]);
    
    // Test an invalid grouped array with a single section and no objects
    literal = @[sectionW];
    XCTAssertThrows([INTUMutableGroupedArray literal:literal]);
    
    // Test an invalid grouped array with two sections and no objects array
    literal = @[sectionY, sectionW];
    XCTAssertThrows([INTUMutableGroupedArray literal:literal]);
    
    // There used to be enforcement of unique sections by the literal API, however that has been removed.
    // Make sure that we no longer throw an exception on having two identical sections (even though this is not a good idea).
    literal = @[sectionY, @[objectA],
                sectionY, @[objectB]];
    XCTAssertNoThrow([INTUMutableGroupedArray literal:literal]);
}

/**
 Test the grouped array's NSCoding methods.
 */
- (void)testEncodeAndDecode
{
    [self addUnsortedSectionsAndObjects];
    
    NSData *serializedGroupedArray = [NSKeyedArchiver archivedDataWithRootObject:self.groupedArray];
    INTUMutableGroupedArray *decodedGroupedArray = [NSKeyedUnarchiver unarchiveObjectWithData:serializedGroupedArray];
    XCTAssertTrue([decodedGroupedArray countAllSections] == [self.groupedArray countAllSections], @"The decoded grouped array should have the same number of sections as the original.");
    XCTAssertTrue([decodedGroupedArray countAllObjects] == [self.groupedArray countAllObjects], @"The decoded grouped array should have the same number of objects as the original.");
    XCTAssertTrue([[decodedGroupedArray indexPathOfObject:objectA] isEqual:[self.groupedArray indexPathOfObject:objectA]], @"The decoded grouped array should have Object A at the same index path as the original.");
}

/**
 Test adding objects into the grouped array and the output of various other methods.
 */
- (void)testAddObjects
{
    NSString *object1 = @"Object 1";
    NSString *section1 = @"Section 1";
    
    XCTAssertFalse([self.groupedArray containsSection:section1], @"Section 1 should not exist.");
    XCTAssertFalse([self.groupedArray containsObject:object1], @"Object 1 should not exist.");
    XCTAssertFalse([self.groupedArray containsObject:object1 inSection:section1], @"Object 1 should not exist in Section 1.");
    
    [self.groupedArray addObject:object1 toSection:section1];
    
    XCTAssertTrue([self.groupedArray containsSection:section1], @"Section 1 should exist.");
    XCTAssertEqual(section1, [self.groupedArray sectionAtIndex:0], @"Section 1 should be the first section.");
    XCTAssertTrue([self.groupedArray indexOfSection:section1] == 0, @"Section 1 should be at index 0.");
    XCTAssertTrue([self.groupedArray containsObject:object1], @"Object 1 should exist.");
    XCTAssertTrue([self.groupedArray containsObject:object1 inSection:section1], @"Object 1 should exist in Section 1.");
    XCTAssertEqual(object1, [self.groupedArray objectAtIndex:0 inSection:section1], @"Object 1 should be the first object in Section 1.");
    XCTAssertEqual([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:[self.groupedArray indexOfSection:section1]]], [self.groupedArray objectAtIndex:0 inSection:section1], @"Both methods should return the same object.");
    
    NSString *object2 = @"Object 2";
    
    [self.groupedArray addObject:object2 toSection:section1];
    
    XCTAssertTrue([self.groupedArray containsObject:object2], @"Object 2 should exist.");
    XCTAssertTrue([self.groupedArray containsObject:object2 inSection:section1], @"Object 2 should exist in Section 1.");
    XCTAssertEqual(object1, [self.groupedArray objectAtIndex:0 inSection:section1], @"Object 1 should be the first object in Section 1.");
    XCTAssertEqual(object2, [self.groupedArray objectAtIndex:1 inSection:section1], @"Object 2 should be the second object in Section 1.");
    XCTAssertTrue([[self.groupedArray objectsInSectionAtIndex:0] count] == 2, @"There should be 2 objects in the first section.");
    
    NSString *section2 = @"Section 2";
    
    XCTAssertFalse([self.groupedArray containsSection:section2], @"Section 2 should not exist.");
    XCTAssertTrue([self.groupedArray indexOfObject:object2 inSection:section2] == NSNotFound, @"Section 2 does not exist yet.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:section2] == 0, @"Section 2 does not exist yet.");
    XCTAssertNil([self.groupedArray objectsInSection:section2], @"Section 2 does not exist yet.");
    
    [self.groupedArray addObject:object1 toSection:section2];
    
    XCTAssertEqual(section1, [self.groupedArray sectionAtIndex:0], @"Section 1 should be the first section.");
    XCTAssertEqual(section2, [self.groupedArray sectionAtIndex:1], @"Section 2 should be the second section.");
    XCTAssertTrue([self.groupedArray indexOfSection:section1] == 0, @"Section 1 should be at index 0.");
    XCTAssertTrue([self.groupedArray indexOfSection:section2] == 1, @"Section 2 should be at index 1.");
    XCTAssertEqual(object1, [self.groupedArray objectAtIndex:0 inSection:section1], @"Object 1 should be the first object in Section 1.");
    XCTAssertEqual(object2, [self.groupedArray objectAtIndex:1 inSection:section1], @"Object 2 should be the second object in Section 1.");
    XCTAssertEqual(object1, [self.groupedArray objectAtIndex:0 inSection:section2], @"Object 1 should be the first object in Section 2.");
        XCTAssertEqual([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:[self.groupedArray indexOfSection:section1]]], [self.groupedArray objectAtIndex:1 inSection:section1], @"Both methods should return the same object.");
    
    NSString *section3 = @"Section 3";
    
    [self.groupedArray addObject:object1 toSection:section3];
    [self.groupedArray addObject:object1 toSection:section3];
    [self.groupedArray addObject:object2 toSection:section3];
    [self.groupedArray addObject:object1 toSection:section3];
    [self.groupedArray addObject:object2 toSection:section3];
    
    XCTAssertEqual(object1, [self.groupedArray objectAtIndex:0 inSection:section3], @"Object 1 should be the first object in Section 3.");
    XCTAssertEqual(object1, [self.groupedArray objectAtIndex:1 inSection:section3], @"Object 2 should be the second object in Section 3.");
    XCTAssertEqual(object2, [self.groupedArray objectAtIndex:2 inSection:section3], @"Object 1 should be the first object in Section 3.");
    XCTAssertEqual(object1, [self.groupedArray objectAtIndex:3 inSection:section3], @"Object 2 should be the second object in Section 3.");
    XCTAssertEqual(object2, [self.groupedArray objectAtIndex:4 inSection:section3], @"Object 1 should be the first object in Section 3.");
        XCTAssertEqual([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:[self.groupedArray indexOfSection:section3]]], [self.groupedArray objectAtIndex:3 inSection:section3], @"Both methods should return the same object.");
    
    XCTAssertTrue([self.groupedArray countAllSections] == 3, @"There should be 3 sections total in the grouped array.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 8, @"There should be 8 objects total in the grouped array.");
    XCTAssertTrue([[self.groupedArray allObjects] count] == 8, @"There should be 8 objects total.");
    XCTAssertTrue([[self.groupedArray objectsInSection:section1] count] == 2, @"There should be 2 objects in section 1.");
    XCTAssertTrue([[self.groupedArray objectsInSection:section2] count] == 1, @"There should be 1 object in section 2.");
    XCTAssertTrue([[self.groupedArray objectsInSection:section3] count] == 5, @"There should be 5 objects in section 3.");
    
    NSArray *allSections = [self.groupedArray allSections];
    XCTAssertTrue([allSections count] == 3, @"The array of all sections should be of size 3.");
    XCTAssertTrue([allSections[0] isEqual:section1], @"The first section should be section 1.");
    XCTAssertTrue([allSections[1] isEqual:section2], @"The second section should be section 2.");
    XCTAssertTrue([allSections[2] isEqual:section3], @"The third section should be section 3.");
}

/**
 Test adding objects into the grouped array using a section index hint.
 */
- (void)testAddObjectsUsingSectionIndexHint
{
    // Test a wrong hint that requires the section to be created
    [self.groupedArray addObject:objectA toSection:sectionW withSectionIndexHint:50];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 1, @"There should be 1 section in the grouped array.");
    XCTAssertTrue([self.groupedArray sectionAtIndex:0] == sectionW, @"Section W should be the first section in the grouped array.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 1, @"There should be 1 object in the grouped array.");
    XCTAssertTrue([self.groupedArray objectAtIndex:0 inSection:sectionW] == objectA, @"Object A should be the first object in Section W.");
    
    // Test a wrong hint that doesn't require the section to be created
    [self.groupedArray addObject:objectB toSection:sectionW withSectionIndexHint:50];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 1, @"There should be 1 section in the grouped array.");
    XCTAssertTrue([self.groupedArray sectionAtIndex:0] == sectionW, @"Section W should be the first section in the grouped array.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects in the grouped array.");
    XCTAssertTrue([self.groupedArray objectAtIndex:1 inSection:sectionW] == objectB, @"Object B should be the second object in Section W.");
    
    // Test a wrong hint that requires the section to be created
    [self.groupedArray addObject:objectC toSection:sectionX withSectionIndexHint:0];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections in the grouped array.");
    XCTAssertTrue([self.groupedArray sectionAtIndex:1] == sectionX, @"Section X should be the second section in the grouped array.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 3, @"There should be 3 objects in the grouped array.");
    XCTAssertTrue([self.groupedArray objectAtIndex:0 inSection:sectionX] == objectC, @"Object C should be the first object in Section X.");
    
    // Test a wrong hint that doesn't require the section to be created
    [self.groupedArray addObject:objectD toSection:sectionX withSectionIndexHint:0];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections in the grouped array.");
    XCTAssertTrue([self.groupedArray sectionAtIndex:1] == sectionX, @"Section X should be the second section in the grouped array.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 4, @"There should be 4 objects in the grouped array.");
    XCTAssertTrue([self.groupedArray objectAtIndex:1 inSection:sectionX] == objectD, @"Object D should be the second object in Section X.");
    
    // Test a correct hint that requires the section to be created
    [self.groupedArray addObject:objectE toSection:sectionY withSectionIndexHint:2];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 3, @"There should be 3 sections in the grouped array.");
    XCTAssertTrue([self.groupedArray sectionAtIndex:2] == sectionY, @"Section Y should be the third section in the grouped array.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 5, @"There should be 5 objects in the grouped array.");
    XCTAssertTrue([self.groupedArray objectAtIndex:0 inSection:sectionY] == objectE, @"Object E should be the first object in Section Y.");
    
    // Test a correct hint that doesn't require the section to be created
    [self.groupedArray addObject:objectF toSection:sectionY withSectionIndexHint:2];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 3, @"There should be 3 sections in the grouped array.");
    XCTAssertTrue([self.groupedArray sectionAtIndex:2] == sectionY, @"Section Y should be the third section in the grouped array.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 6, @"There should be 6 objects in the grouped array.");
    XCTAssertTrue([self.groupedArray objectAtIndex:1 inSection:sectionY] == objectF, @"Object F should be the second object in Section Y.");
}

/**
 Test adding objects into the grouped array using a section index.
 */
- (void)testAddObjectToSectionAtIndex
{
    XCTAssertThrows([self.groupedArray addObject:objectA toSectionAtIndex:0], @"Attempting to add an object to a section with an out of bounds index should throw an exception.");
    
    [self.groupedArray addObject:objectA toSection:sectionW];
    XCTAssertThrows([self.groupedArray addObject:objectA toSectionAtIndex:1], @"Attempting to add an object to a section with an out of bounds index should throw an exception.");
    [self.groupedArray addObject:objectB toSectionAtIndex:0];
    XCTAssert([self.groupedArray countAllObjects] == 2, @"The grouped array should have 2 objects total.");
    XCTAssert([self.groupedArray countObjectsInSectionAtIndex:0] == 2, @"The grouped array should have 2 objects in the first section.");
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionW] == objectA, @"Object A should be the first object in Section W.");
    XCTAssert([self.groupedArray objectAtIndex:1 inSection:sectionW] == objectB, @"Object B should be the second object in Section W.");
}

/**
 Test adding objects from an array into the grouped array.
 */
- (void)testAddObjectsFromArray
{
    NSArray *objectArrayEmpty = [NSArray new];
    NSArray *objectArray1 = @[objectD, objectB, objectC, objectF];
    NSArray *objectArray2 = @[objectE, objectD, objectB];
    
    [self.groupedArray addObjectsFromArray:nil toSection:sectionX];
    XCTAssertFalse([self.groupedArray containsSection:sectionX], @"sectionX should not exist.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 0, @"There should be no objects.");
    
    [self.groupedArray addObjectsFromArray:objectArrayEmpty toSection:sectionX];
    XCTAssertFalse([self.groupedArray containsSection:sectionX], @"sectionX should not exist.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 0, @"There should be no objects.");
    
    [self.groupedArray addObjectsFromArray:objectArray1 toSection:sectionX];
    XCTAssertTrue([self.groupedArray containsSection:sectionX], @"sectionX should exist.");
    XCTAssertTrue([self.groupedArray countAllObjects] == [objectArray1 count], @"The total number of objects should be the same as the number of objects as objectArray1.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionX] == [objectArray1 count], @"sectionX should contain the same number of objects as objectArray1");
    NSUInteger i = 0;
    for (id object in [self.groupedArray allObjects]) {
        XCTAssertEqualObjects(object, objectArray1[i], @"The objects should be equal.");
        i++;
    }
    
    [self.groupedArray addObjectsFromArray:objectArray2 toSection:sectionW];
    XCTAssertTrue([self.groupedArray containsSection:sectionW], @"sectionW should exist.");
    XCTAssertTrue([self.groupedArray countAllObjects] == [objectArray1 count] + [objectArray2 count], @"The total number of objects should be the sum of the counts of objectArray1 and objectArray2.");
    NSArray *combinedArray = [objectArray1 arrayByAddingObjectsFromArray:objectArray2];
    i = 0;
    for (id object in [self.groupedArray allObjects]) {
        XCTAssertEqualObjects(object, combinedArray[i], @"The objects should be equal.");
        i++;
    }
    
    [self.groupedArray addObjectsFromArray:objectArray2 toSection:sectionX];
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionX] == [objectArray1 count] + [objectArray2 count], @"The number of objects in sectionX should be the sum of the counts of objectArray1 and objectArray2.");
    
    self.groupedArray = [INTUMutableGroupedArray groupedArrayWithArray:nil];
    XCTAssertNotNil(self.groupedArray, @"The grouped array should not be nil.");
    XCTAssertTrue([self.groupedArray countAllSections] == 0, @"There should be zero sections.");
    
    self.groupedArray = [INTUMutableGroupedArray groupedArrayWithArray:objectArrayEmpty];
    XCTAssertNotNil(self.groupedArray, @"The grouped array should not be nil.");
    XCTAssertTrue([self.groupedArray countAllSections] == 0, @"There should be zero sections.");
    
    self.groupedArray = [INTUMutableGroupedArray groupedArrayWithArray:objectArray2];
    XCTAssertTrue([self.groupedArray countAllSections] == 1, @"There should be exactly one section.");
    XCTAssertTrue([self.groupedArray countObjectsInSectionAtIndex:0] == [objectArray2 count], @"sectionX should contain the same number of objects as objectArray2");
    XCTAssertTrue([[self.groupedArray allObjects] count] == [objectArray2 count], @"sectionX should contain the same number of objects as objectArray2");
    i = 0;
    for (id object in [self.groupedArray allObjects]) {
        XCTAssertEqualObjects(object, objectArray2[i], @"The objects should be equal.");
        i++;
    }
}

/**
 Test the insertObject:atIndex:inSection: method.
 */
- (void)testInsertObjectAtIndexInSection
{
    // Insert first object & create a section
    [self.groupedArray insertObject:objectD atIndex:0 inSection:sectionW];
    XCTAssert([self.groupedArray countAllSections] == 1);
    XCTAssert([self.groupedArray countAllObjects] == 1);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionW] == objectD);

    // Insert to the end of an existing section
    [self.groupedArray insertObject:objectA atIndex:1 inSection:sectionW];
    XCTAssert([self.groupedArray countAllSections] == 1);
    XCTAssert([self.groupedArray countAllObjects] == 2);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionW] == objectD);
    XCTAssert([self.groupedArray objectAtIndex:1 inSection:sectionW] == objectA);

    // Insert to the beginning of an existing section
    [self.groupedArray insertObject:objectC atIndex:0 inSection:sectionW];
    XCTAssert([self.groupedArray countAllSections] == 1);
    XCTAssert([self.groupedArray countAllObjects] == 3);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionW] == objectC);
    XCTAssert([self.groupedArray objectAtIndex:1 inSection:sectionW] == objectD);
    XCTAssert([self.groupedArray objectAtIndex:2 inSection:sectionW] == objectA);

    // Insert to the middle of an existing section
    [self.groupedArray insertObject:objectB atIndex:1 inSection:sectionW];
    XCTAssert([self.groupedArray countAllSections] == 1);
    XCTAssert([self.groupedArray countAllObjects] == 4);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionW] == objectC);
    XCTAssert([self.groupedArray objectAtIndex:1 inSection:sectionW] == objectB);
    XCTAssert([self.groupedArray objectAtIndex:2 inSection:sectionW] == objectD);
    XCTAssert([self.groupedArray objectAtIndex:3 inSection:sectionW] == objectA);
    
    // Insert another object & create a second section
    [self.groupedArray insertObject:objectA atIndex:0 inSection:sectionZ];
    XCTAssert([self.groupedArray countAllSections] == 2);
    XCTAssert([self.groupedArray countAllObjects] == 5);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionZ] == objectA);
    
    // Index out of bounds tests
    XCTAssertThrows([self.groupedArray insertObject:nil atIndex:0 inSection:sectionW], @"Nil object should throw an exception.");
    XCTAssertThrows([self.groupedArray insertObject:objectA atIndex:0 inSection:nil], @"Nil section should throw an exception.");
    XCTAssertThrows([self.groupedArray insertObject:objectA atIndex:2 inSection:sectionZ], @"Out of bounds index should throw an exception.");
}

/**
 Test the insertObject:atIndexPath: method.
 */
- (void)testInsertObjectAtIndexPath
{
    [self.groupedArray addObject:objectD toSection:sectionW];
    
    // Insert to the end of an existing section
    [self.groupedArray insertObject:objectA atIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]];
    XCTAssert([self.groupedArray countAllSections] == 1);
    XCTAssert([self.groupedArray countAllObjects] == 2);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionW] == objectD);
    XCTAssert([self.groupedArray objectAtIndex:1 inSection:sectionW] == objectA);
    
    // Insert to the beginning of an existing section
    [self.groupedArray insertObject:objectC atIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]];
    XCTAssert([self.groupedArray countAllSections] == 1);
    XCTAssert([self.groupedArray countAllObjects] == 3);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionW] == objectC);
    XCTAssert([self.groupedArray objectAtIndex:1 inSection:sectionW] == objectD);
    XCTAssert([self.groupedArray objectAtIndex:2 inSection:sectionW] == objectA);
    
    // Insert to the middle of an existing section
    [self.groupedArray insertObject:objectB atIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]];
    XCTAssert([self.groupedArray countAllSections] == 1);
    XCTAssert([self.groupedArray countAllObjects] == 4);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionW] == objectC);
    XCTAssert([self.groupedArray objectAtIndex:1 inSection:sectionW] == objectB);
    XCTAssert([self.groupedArray objectAtIndex:2 inSection:sectionW] == objectD);
    XCTAssert([self.groupedArray objectAtIndex:3 inSection:sectionW] == objectA);
    
    // Index out of bounds tests
    XCTAssertThrows([self.groupedArray insertObject:nil atIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]], @"Nil object should throw an exception.");
    XCTAssertThrows([self.groupedArray insertObject:objectA atIndexPath:nil], @"Nil index path should throw an exception.");
    XCTAssertThrows([self.groupedArray insertObject:objectA atIndexPath:[INTUGroupedArray indexPathForRow:5 inSection:0]], @"Out of bounds object index should throw an exception.");
    XCTAssertThrows([self.groupedArray insertObject:objectA atIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]], @"Out of bounds section index should throw an exception.");
}

/**
 Test the replaceSectionAtIndex:withSection: method.
 */
- (void)testReplaceSectionAtIndexWithSection
{
    [self addUnsortedSectionsAndObjects];
    
    // Replace the last section
    NSString *replacementSectionZ = @"Replaced Section Z";
    [self.groupedArray replaceSectionAtIndex:3 withSection:replacementSectionZ];
    XCTAssert([self.groupedArray countAllSections] == 4);
    XCTAssert([self.groupedArray countAllObjects] == 8);
    XCTAssert([self.groupedArray sectionAtIndex:3] == replacementSectionZ);
    XCTAssert([self.groupedArray containsSection:sectionZ] == NO);
    
    // Replace the first section
    NSString *replacementSectionY = @"Replaced Section Y";
    [self.groupedArray replaceSectionAtIndex:0 withSection:replacementSectionY];
    XCTAssert([self.groupedArray countAllSections] == 4);
    XCTAssert([self.groupedArray countAllObjects] == 8);
    XCTAssert([self.groupedArray sectionAtIndex:0] == replacementSectionY);
    XCTAssert([self.groupedArray containsSection:sectionY] == NO);
    
    // Replace the only section
    self.groupedArray = [INTUMutableGroupedArray literal:@[sectionX, @[objectA, objectB]]];
    NSString *replacementSectionX = @"Replaced Section X";
    [self.groupedArray replaceSectionAtIndex:0 withSection:replacementSectionX];
    XCTAssert([self.groupedArray countAllSections] == 1);
    XCTAssert([self.groupedArray countAllObjects] == 2);
    XCTAssert([self.groupedArray sectionAtIndex:0] == replacementSectionX);
    XCTAssert([self.groupedArray containsSection:sectionX] == NO);
    
    self.groupedArray = [INTUMutableGroupedArray groupedArray];
    [self addUnsortedSectionsAndObjects];
    
    // Attempt to replace with a section that already exists elsewhere
    // There used to be enforcement of unique sections by this API, however that has been removed.
    // Make sure that we no longer throw an exception on having two identical sections (even though this is not a good idea).
    XCTAssertNoThrow([self.groupedArray replaceSectionAtIndex:0 withSection:sectionZ], @"Replacing a section with a section that already exists should not throw an exception.");
    XCTAssert([self.groupedArray countAllSections] == 4);
    XCTAssert([self.groupedArray sectionAtIndex:0] == sectionZ);
    
    // Index out of bounds tests
    XCTAssertThrows([self.groupedArray replaceSectionAtIndex:0 withSection:nil], @"Nil section should throw an exception.");
    XCTAssertThrows([self.groupedArray replaceSectionAtIndex:4 withSection:sectionW], @"Out of bounds section index should throw an exception.");
}

/**
 Test the replaceObjectAtIndexPath:withObject: method.
 */
- (void)testReplaceObjectAtIndexPathWithObject
{
    [self addUnsortedSectionsAndObjects];
    
    // Replace at the end of an existing section
    [self.groupedArray replaceObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0] withObject:objectA];
    XCTAssert([self.groupedArray countAllSections] == 4);
    XCTAssert([self.groupedArray countAllObjects] == 8);
    XCTAssert([self.groupedArray objectAtIndex:3 inSection:sectionY] == objectA);
    
    // Replace at the beginning of an existing section
    [self.groupedArray replaceObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] withObject:objectC];
    XCTAssert([self.groupedArray countAllSections] == 4);
    XCTAssert([self.groupedArray countAllObjects] == 8);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionY] == objectC);
    
    // Replace the only item in an existing section
    [self.groupedArray replaceObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:3] withObject:objectE];
    XCTAssert([self.groupedArray countAllSections] == 4);
    XCTAssert([self.groupedArray countAllObjects] == 8);
    XCTAssert([self.groupedArray objectAtIndex:0 inSection:sectionZ] == objectE);
    
    // Index out of bounds tests
    XCTAssertThrows([self.groupedArray replaceObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] withObject:nil], @"Nil object should throw an exception.");
    XCTAssertThrows([self.groupedArray replaceObjectAtIndexPath:nil withObject:objectA], @"Nil index path should throw an exception.");
    XCTAssertThrows([self.groupedArray replaceObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:4] withObject:objectA], @"Out of bounds object index should throw an exception.");
    XCTAssertThrows([self.groupedArray replaceObjectAtIndexPath:[INTUGroupedArray indexPathForRow:4 inSection:0] withObject:objectA], @"Out of bounds section index should throw an exception.");
}

/**
 Test the moveSectionAtIndex:toIndex: method.
 */
- (void)testMoveSectionAtIndexToIndex
{
    [self addUnsortedSectionsAndObjects];
    
    INTUGroupedArray *original = [self.groupedArray mutableCopy];
    
    // Move section to the same place
    [self.groupedArray moveSectionAtIndex:0 toIndex:0];
    XCTAssert([self.groupedArray isEqualToGroupedArray:original]);
    [self.groupedArray moveSectionAtIndex:1 toIndex:1];
    XCTAssert([self.groupedArray isEqualToGroupedArray:original]);
    [self.groupedArray moveSectionAtIndex:2 toIndex:2];
    XCTAssert([self.groupedArray isEqualToGroupedArray:original]);
    [self.groupedArray moveSectionAtIndex:3 toIndex:3];
    XCTAssert([self.groupedArray isEqualToGroupedArray:original]);
    
    // Move first section to the end
    [self.groupedArray moveSectionAtIndex:0 toIndex:3];
    XCTAssert([self.groupedArray sectionAtIndex:0] == sectionW);
    XCTAssert([self.groupedArray sectionAtIndex:1] == sectionX);
    XCTAssert([self.groupedArray sectionAtIndex:2] == sectionZ);
    XCTAssert([self.groupedArray sectionAtIndex:3] == sectionY);
    
    // Move last section to middle
    [self.groupedArray moveSectionAtIndex:3 toIndex:2];
    XCTAssert([self.groupedArray sectionAtIndex:0] == sectionW);
    XCTAssert([self.groupedArray sectionAtIndex:1] == sectionX);
    XCTAssert([self.groupedArray sectionAtIndex:2] == sectionY);
    XCTAssert([self.groupedArray sectionAtIndex:3] == sectionZ);
    
    // Move last section to beginning
    [self.groupedArray moveSectionAtIndex:3 toIndex:0];
    XCTAssert([self.groupedArray sectionAtIndex:0] == sectionZ);
    XCTAssert([self.groupedArray sectionAtIndex:1] == sectionW);
    XCTAssert([self.groupedArray sectionAtIndex:2] == sectionX);
    XCTAssert([self.groupedArray sectionAtIndex:3] == sectionY);
    
    // Move first section to middle
    [self.groupedArray moveSectionAtIndex:0 toIndex:1];
    XCTAssert([self.groupedArray sectionAtIndex:0] == sectionW);
    XCTAssert([self.groupedArray sectionAtIndex:1] == sectionZ);
    XCTAssert([self.groupedArray sectionAtIndex:2] == sectionX);
    XCTAssert([self.groupedArray sectionAtIndex:3] == sectionY);
    
    // Index out of bounds tests
    XCTAssertThrows([self.groupedArray moveSectionAtIndex:4 toIndex:0], @"Out of bounds from index should throw an exception.");
    XCTAssertThrows([self.groupedArray moveSectionAtIndex:0 toIndex:4], @"Out of bounds to index should throw an exception.");
}

/**
 Test the moveObjectAtIndexPath:toIndexPath: method.
 */
- (void)testMoveObjectAtIndexPathToIndexPath
{
    [self addUnsortedSectionsAndObjects];
    
    INTUGroupedArray *original = [self.groupedArray mutableCopy];
    
    // Move section to the same place
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:original]);
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1] toIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:original]);
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:2] toIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:2]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:original]);
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:3] toIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:3]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:original]);
    
    // Move the first object in a section to the end of the section
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]];
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectE);
    
    // Move the first object in a section to the middle of the section
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]];
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectE);
    
    // Move the last object in a section to the beginning of the section
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]];
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectC);
    
    // Move the last object in a section to the middle of the section
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]];
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectB);
    
    [self.groupedArray removeAllObjects];
    [self addUnsortedSectionsAndObjects];
    // Move the first object in a section to the beginning of another section
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]];
    XCTAssert([self.groupedArray countObjectsInSectionAtIndex:0] == 3);
    XCTAssert([self.groupedArray countObjectsInSectionAtIndex:1] == 3);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:1]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:1]] == objectD);
    
    [self.groupedArray removeAllObjects];
    [self addUnsortedSectionsAndObjects];
    // Move the last object in a section to the middle of another section
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:1]];
    XCTAssert([self.groupedArray countObjectsInSectionAtIndex:0] == 3);
    XCTAssert([self.groupedArray countObjectsInSectionAtIndex:1] == 3);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:1]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:1]] == objectD);
    
    [self.groupedArray removeAllObjects];
    [self addUnsortedSectionsAndObjects];
    // Move a middle object in a section to the end of another section
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:1]];
    XCTAssert([self.groupedArray countObjectsInSectionAtIndex:0] == 3);
    XCTAssert([self.groupedArray countObjectsInSectionAtIndex:1] == 3);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:1]] == objectD);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:1]] == objectB);
    
    [self.groupedArray removeAllObjects];
    [self addUnsortedSectionsAndObjects];
    // Move the only object in a section to another section (from section should be removed)
    [self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:3] toIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:2]];
    XCTAssert([self.groupedArray countAllSections] == 3);
    XCTAssert([self.groupedArray countAllObjects] == 8);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:2]] == objectF);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:2]] == objectD);
    XCTAssert([self.groupedArray containsSection:sectionZ] == NO);
    
    [self.groupedArray removeAllObjects];
    [self addUnsortedSectionsAndObjects];
    // Index out of bounds tests
    XCTAssertThrows([self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:4] toIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]], @"Out of bounds from section index should throw an exception.");
    XCTAssertThrows([self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:4]], @"Out of bounds to section index should throw an exception.");
    XCTAssertThrows([self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:2] toIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]], @"Out of bounds from row index should throw an exception.");
    XCTAssertThrows([self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1] toIndexPath:[INTUGroupedArray indexPathForRow:6 inSection:0]], @"Out of bounds to row index in a different section should throw an exception.");
    XCTAssertThrows([self.groupedArray moveObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] toIndexPath:[INTUGroupedArray indexPathForRow:5 inSection:0]], @"Out of bounds to row index in the same section should throw an exception.");
}

/**
 Test the exchangeSectionAtIndex:withSectionAtIndex: method.
 */
- (void)testExchangeSectionAtIndexWithSectionAtIndex
{
    [self addUnsortedSectionsAndObjects];
    
    INTUMutableGroupedArray *copy = [self.groupedArray mutableCopy];
    
    // Test exchanging the first section with the last
    [self.groupedArray exchangeSectionAtIndex:0 withSectionAtIndex:3];
    [copy exchangeSectionAtIndex:3 withSectionAtIndex:0];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray sectionAtIndex:0] == sectionZ);
    XCTAssert([self.groupedArray sectionAtIndex:1] == sectionW);
    XCTAssert([self.groupedArray sectionAtIndex:2] == sectionX);
    XCTAssert([self.groupedArray sectionAtIndex:3] == sectionY);
    
    // Test exchanging the first section with a middle section
    [self.groupedArray exchangeSectionAtIndex:0 withSectionAtIndex:1];
    [copy exchangeSectionAtIndex:1 withSectionAtIndex:0];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray sectionAtIndex:0] == sectionW);
    XCTAssert([self.groupedArray sectionAtIndex:1] == sectionZ);
    XCTAssert([self.groupedArray sectionAtIndex:2] == sectionX);
    XCTAssert([self.groupedArray sectionAtIndex:3] == sectionY);
    
    // Test exchanging the last section with itself
    [self.groupedArray exchangeSectionAtIndex:3 withSectionAtIndex:3];
    [copy exchangeSectionAtIndex:3 withSectionAtIndex:3];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray sectionAtIndex:0] == sectionW);
    XCTAssert([self.groupedArray sectionAtIndex:1] == sectionZ);
    XCTAssert([self.groupedArray sectionAtIndex:2] == sectionX);
    XCTAssert([self.groupedArray sectionAtIndex:3] == sectionY);
    
    // Index out of bounds tests
    XCTAssertThrows([self.groupedArray exchangeSectionAtIndex:4 withSectionAtIndex:0], @"An out of bounds to index should throw an exception.");
    XCTAssertThrows([self.groupedArray exchangeSectionAtIndex:0 withSectionAtIndex:4], @"An out of bounds to index should throw an exception.");
}

/**
 Test the exchangeObjectAtIndexPath:withObjectAtIndexPath: method.
 */
- (void)testExchangeObjectAtIndexPathWithObjectAtIndexPath
{
    [self addUnsortedSectionsAndObjects];
    
    INTUMutableGroupedArray *copy = [self.groupedArray mutableCopy];
    
    // Exchange the first object in a section with the last object in the same section
    [self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]];
    [copy exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectE);
    
    // Exchange the first object in a section with a middle object in the same section
    [self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]];
    [copy exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectE);

    // Exchange the last object in a section with a middle object in the same section
    [self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]];
    [copy exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectC);
    
    // Exchange an object with itself
    [self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]];
    [copy exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectC);
    
    [self.groupedArray removeAllObjects];
    [self addUnsortedSectionsAndObjects];
    copy = [self.groupedArray mutableCopy];
    
    // Exchange the first object in a section with the first object of another section
    [self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]];
    [copy exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray countAllSections] == 4);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:1]] == objectD);
    
    // Exchange the last object in a section with the middle object of another section
    [self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]];
    [copy exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray countAllSections] == 4);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:1]] == objectC);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:1]] == objectD);

    // Exchange a middle object in a section with the first object of another section
    [self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:3]];
    [copy exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:3] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]];
    XCTAssert([self.groupedArray isEqualToGroupedArray:copy]);
    XCTAssert([self.groupedArray countAllSections] == 4);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] == objectA);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:1 inSection:0]] == objectB);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:2 inSection:0]] == objectD);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:3 inSection:0]] == objectE);
    XCTAssert([self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:3]] == objectA);
    
    // Index out of bounds tests
    XCTAssertThrows([self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:4 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]], @"An out of bounds from object index should throw an exception.");
    XCTAssertThrows([self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:4 inSection:0]], @"An out of bounds to object index should throw an exception.");
    XCTAssertThrows([self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:4] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]], @"An out of bounds from section index should throw an exception.");
    XCTAssertThrows([self.groupedArray exchangeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0] withObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:4]], @"An out of bounds to section index should throw an exception.");
}

/**
 Test removing all objects from the grouped array.
 */
- (void)testRemoveAllObjects
{
    [self generateSections:8 withObjects:450];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 8, @"There should be 8 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 3600, @"There should be 3600 objects total.");
    
    [self.groupedArray removeAllObjects];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 0, @"There should be 0 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 0, @"There should be 0 objects total.");
}

/**
 Test removing objects from the grouped array.
 */
- (void)testRemove
{
    [self generateSections:20 withObjects:10];
    
    id section1 = [self.groupedArray sectionAtIndex:0];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 20, @"There should be 20 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 200, @"There should be 200 objects total.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:section1] == 10, @"There should be 10 objects in the first section.");
    
    [self.groupedArray removeObjectAtIndex:0 fromSection:section1];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 20, @"There should be 20 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 199, @"There should be 199 objects total.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:section1] == 9, @"There should be 9 objects in the first section.");
    
    NSUInteger numberOfSection1Objects = [self.groupedArray countObjectsInSectionAtIndex:0];
    for (NSUInteger i = 0; i < numberOfSection1Objects; i++) {
        [self.groupedArray removeObjectAtIndex:0 fromSection:section1];
    }
    
    XCTAssertTrue([self.groupedArray countAllSections] == 19, @"There should be 19 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 190, @"There should be 190 objects total.");
    XCTAssertFalse([self.groupedArray containsSection:section1], @"Section 1 should no longer exist.");
    
    // Remove every object one by one
    NSArray *allSections = [self.groupedArray allSections];
    for (id section in allSections) {
        NSUInteger numberOfObjectsInSection = [self.groupedArray countObjectsInSection:section];
        for (NSUInteger i = 0; i < numberOfObjectsInSection; i++) {
            id object = [self.groupedArray objectAtIndex:0 inSection:section];
            [self.groupedArray removeObject:object fromSection:section];
        }
    }
    
    XCTAssertNotNil(self.groupedArray, @"Grouped array should not be nil.");
    XCTAssertTrue([self.groupedArray countAllSections] == 0, @"There should be no more sections.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 0, @"There should be no more objects.");
}

/**
 Test removing entire sections from the grouped array.
 */
- (void)testRemoveSection
{
    [self generateSections:3 withObjects:500];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 3, @"There should be 3 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 1500, @"There should be 1500 objects total.");
    XCTAssertTrue([self.groupedArray countObjectsInSectionAtIndex:0] == 500, @"There should be 500 objects in the first section.");
    
    id sectionToRemove = [self.groupedArray sectionAtIndex:0];
    XCTAssertTrue([self.groupedArray containsSection:sectionToRemove], @"Section should exist.");
    [self.groupedArray removeSection:sectionToRemove];
    
    XCTAssertFalse([self.groupedArray containsSection:sectionToRemove], @"Section should not exist.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 3 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 1000, @"There should be 1000 objects total.");
    
    // This will be a no-op since the section does not exist (it was already removed)
    [self.groupedArray removeSection:sectionToRemove];
    
    XCTAssertFalse([self.groupedArray containsSection:sectionToRemove], @"Section should not exist.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 3 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 1000, @"There should be 1000 objects total.");
    
    // This will be a no-op since the section does not exist (it was already removed)
    [self.groupedArray removeObject:[self.groupedArray objectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]] fromSection:sectionToRemove];
    
    XCTAssertFalse([self.groupedArray containsSection:sectionToRemove], @"Section should not exist.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 3 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 1000, @"There should be 1000 objects total.");
}

/**
 Test the removeSectionAtIndex: method.
 */
- (void)testRemoveSectionAtIndex
{
    [self generateSections:3 withObjects:500];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 3, @"There should be 3 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 1500, @"There should be 1500 objects total.");
    XCTAssertTrue([self.groupedArray countObjectsInSectionAtIndex:0] == 500, @"There should be 500 objects in the first section.");
    
    id sectionToRemove = [self.groupedArray sectionAtIndex:0];
    XCTAssertTrue([self.groupedArray containsSection:sectionToRemove], @"Section should exist.");
    [self.groupedArray removeSectionAtIndex:0];
    XCTAssertFalse([self.groupedArray containsSection:sectionToRemove], @"Section should not exist.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 3 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 1000, @"There should be 1000 objects total.");
    
    // This will be a no-op since the section does not exist (it was already removed)
    [self.groupedArray removeSectionAtIndex:1];
    XCTAssertTrue([self.groupedArray countAllSections] == 1, @"There should be 1 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 500, @"There should be 500 objects total.");
    
    [self.groupedArray removeSectionAtIndex:0];
    XCTAssertTrue([self.groupedArray countAllSections] == 0, @"There should be 0 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 0, @"There should be 0 objects total.");
    
    // Index out of bounds tests
    XCTAssertThrows([self.groupedArray removeSectionAtIndex:0], @"Attempting to remove a section index that is out of bounds should throw an exception.");
}

/**
 Test removing an object which has been added multiple times to the grouped array.
 */
- (void)testRemoveDuplicates
{
    NSString *object1 = @"Object 1";
    NSString *object2 = @"Object 2";
    NSString *section1 = @"Section 1";
    NSString *section2 = @"Section 2";
    
    [self.groupedArray addObject:object1 toSection:section1];
    [self.groupedArray addObject:object2 toSection:section1];
    [self.groupedArray addObject:object1 toSection:section1];
    [self.groupedArray addObject:object1 toSection:section2];
    
    XCTAssertTrue([self.groupedArray countAllObjects] == 4, @"There should be 4 objects total.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:section1] == 3, @"There should be 3 objects in the first section.");
    
    // Remove all instances of object1
    [self.groupedArray removeObject:object1];
    
    XCTAssertTrue([self.groupedArray countAllObjects] == 1, @"There should be 1 object total.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:section1] == 1, @"There should be 1 object in the first section.");
    XCTAssertEqualObjects([self.groupedArray objectAtIndex:0 inSection:section1], object2, @"Object 2 should be the remaining object.");
    XCTAssertFalse([self.groupedArray containsSection:section2], @"Section 2 should no longer exist.");
    
    [self.groupedArray addObject:object1 toSection:section1];
    [self.groupedArray addObject:object2 toSection:section1];
    [self.groupedArray addObject:object1 toSection:section1];
    
    XCTAssertTrue([self.groupedArray countAllObjects] == 4, @"There should be 4 objects total.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:section1] == 4, @"There should be 4 objects in the first section.");
    
    // Remove all instances of object2 in the first section
    [self.groupedArray removeObject:object2 fromSection:section1];
    
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:section1] == 2, @"There should be 2 objects in the first section.");
}

/**
 Test the removeObjectAtIndexPath: method.
 */
- (void)testRemoveObjectAtIndexPath
{
    [self generateSections:20 withObjects:10];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 20, @"There should be 20 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 200, @"There should be 200 objects total.");
    XCTAssertTrue([self.groupedArray countObjectsInSectionAtIndex:0] == 10, @"There should be 10 objects in the first section.");
    
    [self.groupedArray removeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 20, @"There should be 20 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 199, @"There should be 199 objects total.");
    XCTAssertTrue([self.groupedArray countObjectsInSectionAtIndex:0] == 9, @"There should be 9 objects in the first section.");
    
    id section1 = [self.groupedArray sectionAtIndex:0];
    NSUInteger numberOfSection1Objects = [self.groupedArray countObjectsInSectionAtIndex:0];
    for (NSUInteger i = 0; i < numberOfSection1Objects; i++) {
        [self.groupedArray removeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]];
    }
    
    XCTAssertTrue([self.groupedArray countAllSections] == 19, @"There should be 19 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 190, @"There should be 190 objects total.");
    XCTAssertFalse([self.groupedArray containsSection:section1], @"Section 1 should no longer exist.");
    
    // Remove every object one by one
    NSArray *allSections = [self.groupedArray allSections];
    for (NSUInteger sectionIndex = 0; sectionIndex < [allSections count]; sectionIndex++) {
        NSUInteger numberOfObjectsInSection = [self.groupedArray countObjectsInSectionAtIndex:0];
        for (NSUInteger objectIndex = 0; objectIndex < numberOfObjectsInSection; objectIndex++) {
            [self.groupedArray removeObjectAtIndexPath:[INTUGroupedArray indexPathForRow:0 inSection:0]];
        }
    }
    
    XCTAssertNotNil(self.groupedArray, @"Grouped array should not be nil.");
    XCTAssertTrue([self.groupedArray countAllSections] == 0, @"There should be no more sections.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 0, @"There should be no more objects.");
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
    
    [self.groupedArray addObject:object1 toSection:section1];
    [self.groupedArray addObject:object2 toSection:section2];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUMutableGroupedArray *copy = [[INTUMutableGroupedArray alloc] initWithGroupedArray:self.groupedArray];
    
    XCTAssert([copy isMemberOfClass:[INTUMutableGroupedArray class]], @"The copy should be an INTUMutableGroupedArray.");
    XCTAssertTrue(self.groupedArray != copy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([copy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([copy countAllObjects] == 2, @"There should be 2 objects total.");
    
    [self.groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        id otherSection = [copy sectionAtIndex:index];
        XCTAssertEqual(section, otherSection, @"The sections should be identical instances.");
    }];
    
    [self.groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
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
    NSMutableString *object3 = [NSMutableString stringWithString:@"Object 3"];
    NSMutableString *section1 = [NSMutableString stringWithString:@"Section 1"];
    NSMutableString *section2 = [NSMutableString stringWithString:@"Section 2"];
    
    [self.groupedArray addObject:object1 toSection:section1];
    [self.groupedArray addObject:object2 toSection:section2];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUMutableGroupedArray *deepCopy = [[INTUMutableGroupedArray alloc] initWithGroupedArray:self.groupedArray copyItems:YES];
    
    XCTAssert([deepCopy isMemberOfClass:[INTUMutableGroupedArray class]], @"The copy should be an INTUMutableGroupedArray.");
    XCTAssertTrue(self.groupedArray != deepCopy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([deepCopy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([deepCopy countAllObjects] == 2, @"There should be 2 objects total.");
    
    [self.groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        id otherSection = [deepCopy sectionAtIndex:index];
        XCTAssertNotEqual(section, otherSection, @"The sections should not be identical instances.");
        XCTAssertEqualObjects(section, otherSection, @"The sections should be equal.");
    }];
    
    [self.groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        id otherObject = [deepCopy objectAtIndexPath:indexPath];
        XCTAssertNotEqual(object, otherObject, @"The objects should not be identical instances.");
        XCTAssertEqualObjects(object, otherObject, @"The objects should be equal.");
    }];
    
    // Add an object to the original, and make sure it does not appear in the copy.
    [self.groupedArray addObject:object3 toSection:section1];
    
    XCTAssertEqualObjects(section1, [self.groupedArray sectionAtIndex:0], @"Section 1 should be the first section.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:section1] == 2, @"There should be 2 objects in section 1.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 3, @"There should be 3 objects total.");
    XCTAssertEqualObjects(section1, [deepCopy sectionAtIndex:0], @"Section 1 should be the first section.");
    XCTAssertTrue([deepCopy countObjectsInSection:section1] == 1, @"There should be 1 object in section 1.");
    XCTAssertTrue([deepCopy countAllObjects] == 2, @"There should be 2 objects total.");
    
    // Remove the only item in section 2 to delete the section in the original, and make sure it still exists in the copy.
    [self.groupedArray removeObject:[self.groupedArray objectAtIndex:0 inSection:section2] fromSection:section2];
    
    XCTAssertFalse([self.groupedArray containsSection:section2], @"Section 2 should not exist in the original.");
    XCTAssertTrue([deepCopy containsSection:section2], @"Section 2 should still exist in the copy.");
    XCTAssertTrue([deepCopy countObjectsInSection:section2] == 1, @"Section 2 should have 1 object in the section.");
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
    
    [self.groupedArray addObject:object1 toSection:section1];
    [self.groupedArray addObject:object2 toSection:section2];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUGroupedArray *copy = [self.groupedArray copy];
    
    XCTAssert([copy isMemberOfClass:[INTUGroupedArray class]], @"The copy should be an INTUGroupedArray.");
    XCTAssertTrue(self.groupedArray != copy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([copy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([copy countAllObjects] == 2, @"There should be 2 objects total.");
    
    [self.groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        id otherSection = [copy sectionAtIndex:index];
        XCTAssertEqual(section, otherSection, @"The sections should be identical instances.");
    }];
    
    [self.groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        id otherObject = [copy objectAtIndexPath:indexPath];
        XCTAssertEqual(object, otherObject, @"The objects should be identical instances.");
    }];
}

/**
 Test copying the grouped array, then making changes to the original or copy and checking they are correctly independent.
 */
- (void)testMutableCopy
{
    NSMutableString *object1 = [NSMutableString stringWithString:@"Object 1"];
    NSMutableString *object2 = [NSMutableString stringWithString:@"Object 2"];
    NSMutableString *object3 = [NSMutableString stringWithString:@"Object 3"];
    NSMutableString *section1 = [NSMutableString stringWithString:@"Section 1"];
    NSMutableString *section2 = [NSMutableString stringWithString:@"Section 2"];
    
    [self.groupedArray addObject:object1 toSection:section1];
    [self.groupedArray addObject:object2 toSection:section2];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUMutableGroupedArray *mutableCopy = [self.groupedArray mutableCopy];
    
    XCTAssert([mutableCopy isMemberOfClass:[INTUMutableGroupedArray class]], @"The copy should be an INTUMutableGroupedArray.");
    XCTAssertTrue(self.groupedArray != mutableCopy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([mutableCopy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([mutableCopy countAllObjects] == 2, @"There should be 2 objects total.");
    
    [self.groupedArray enumerateSectionsUsingBlock:^(id section, NSUInteger index, BOOL *stop) {
        id otherSection = [mutableCopy sectionAtIndex:index];
        XCTAssertEqual(section, otherSection, @"The sections should be identical instances.");
    }];
    
    [self.groupedArray enumerateObjectsUsingBlock:^(id object, NSIndexPath *indexPath, BOOL *stop) {
        id otherObject = [mutableCopy objectAtIndexPath:indexPath];
        XCTAssertEqual(object, otherObject, @"The objects should be identical instances.");
    }];
    
    // Add an object to the original, and make sure it does not appear in the copy.
    [self.groupedArray addObject:object3 toSection:section1];

    XCTAssertEqualObjects(section1, [self.groupedArray sectionAtIndex:0], @"Section 1 should be the first section.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:section1] == 2, @"There should be 2 objects in section 1.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 3, @"There should be 3 objects total.");
    XCTAssertEqualObjects(section1, [mutableCopy sectionAtIndex:0], @"Section 1 should be the first section.");
    XCTAssertTrue([mutableCopy countObjectsInSection:section1] == 1, @"There should be 1 object in section 1.");
    XCTAssertTrue([mutableCopy countAllObjects] == 2, @"There should be 2 objects total.");
    
    // Remove the only item in section 2 to delete the section in the original, and make sure it still exists in the copy.
    [self.groupedArray removeObject:[self.groupedArray objectAtIndex:0 inSection:section2] fromSection:section2];
    
    XCTAssertFalse([self.groupedArray containsSection:section2], @"Section 2 should not exist in the original.");
    XCTAssertTrue([mutableCopy containsSection:section2], @"Section 2 should still exist in the copy.");
    XCTAssertTrue([mutableCopy countObjectsInSection:section2] == 1, @"Section 2 should have 1 object in the section.");
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
    
    [self.groupedArray addObject:object1 toSection:section1];
    [self.groupedArray addObject:object2 toSection:section2];
    
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    
    INTUGroupedArray *copy = [self.groupedArray copy];
    
    XCTAssertTrue(self.groupedArray != copy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([copy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([copy countAllObjects] == 2, @"There should be 2 objects total.");
    
    // Mutate the object1 object and make sure this change is visible from both the original and the copy.
    [object1 appendString:@" Mutated"];
    
    XCTAssertEqualObjects(object1, @"Object 1 Mutated", @"The object1 object should now be 'Object 1 Mutated'.");
    XCTAssertTrue([[self.groupedArray objectAtIndex:0 inSection:section1] isEqual:object1], @"The first object of the original should now be named 'Object 1 Mutated'.");
    XCTAssertTrue([[copy objectAtIndex:0 inSection:section1] isEqual:object1], @"The first section of the copy should now be named 'Object 1 Mutated'.");
    XCTAssertEqual([self.groupedArray objectAtIndex:0 inSection:section1], [copy objectAtIndex:0 inSection:section1], @"The original and copy should reference the same object.");
    
    // Mutate the section1 object and make sure this affects the first section in both the original and the copy.
    [section1 appendString:@" Mutated"];
    
    XCTAssertEqualObjects(section1, @"Section 1 Mutated", @"The section1 object should now be 'Section 1 Mutated'.");
    XCTAssertEqual([self.groupedArray sectionAtIndex:0], section1, @"The first section of the original should be 'Section 1 Mutated'.");
    XCTAssertEqual([copy sectionAtIndex:0], section1, @"The first section of the original should be 'Section 1 Mutated'.");
    XCTAssertEqual([self.groupedArray sectionAtIndex:0], [copy sectionAtIndex:0], @"The first section of the original and the copy should be the same object.");
    XCTAssertTrue([self.groupedArray containsSection:section1], @"The original should have a section 'Section 1 Mutated'.");
    XCTAssertTrue([copy containsSection:section1], @"The copy should have a section 'Section 1 Mutated'.");
    
    INTUGroupedArray *mutableCopy = [self.groupedArray mutableCopy];
    
    XCTAssertTrue(self.groupedArray != mutableCopy, @"The copy should not be a reference to the same object.");
    XCTAssertTrue([self.groupedArray countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([self.groupedArray countAllObjects] == 2, @"There should be 2 objects total.");
    XCTAssertTrue([mutableCopy countAllSections] == 2, @"There should be 2 sections total.");
    XCTAssertTrue([mutableCopy countAllObjects] == 2, @"There should be 2 objects total.");
    
    // Mutate the object1 object and make sure this change is visible from both the original and the copy.
    [object1 appendString:@" Again"];
    
    XCTAssertEqualObjects(object1, @"Object 1 Mutated Again", @"The section1 object should now be 'Object 1 Mutated Again'.");
    XCTAssertTrue([[self.groupedArray objectAtIndex:0 inSection:section1] isEqual:object1], @"The first object of the original should now be named 'Object 1 Mutated'.");
    XCTAssertTrue([[mutableCopy objectAtIndex:0 inSection:section1] isEqual:object1], @"The first section of the copy should now be named 'Object 1 Mutated'.");
    XCTAssertEqual([self.groupedArray objectAtIndex:0 inSection:section1], [mutableCopy objectAtIndex:0 inSection:section1], @"The original and copy should reference the same object.");
    
    // Mutate the section1 object and make sure this affects the first section in both the original and the copy.
    [section1 appendString:@" Again"];
    
    XCTAssertEqualObjects(section1, @"Section 1 Mutated Again", @"The section1 object should now be 'Section 1 Mutated Again'.");
    XCTAssertEqual([self.groupedArray sectionAtIndex:0], section1, @"The first section of the original should be 'Section 1 Mutated'.");
    XCTAssertEqual([mutableCopy sectionAtIndex:0], section1, @"The first section of the original should be 'Section 1 Mutated'.");
    XCTAssertEqual([self.groupedArray sectionAtIndex:0], [mutableCopy sectionAtIndex:0], @"The first section of the original and the copy should be the same object.");
    XCTAssertTrue([self.groupedArray containsSection:section1], @"The original should have a section 'Section 1 Mutated'.");
    XCTAssertTrue([mutableCopy containsSection:section1], @"The copy should have a section 'Section 1 Mutated'.");
}

/**
 Adds some sections and objects to the index array in an unsorted fashion.
 */
- (void)addUnsortedSectionsAndObjects
{
    [self.groupedArray addObject:objectE toSection:sectionY];
    [self.groupedArray addObject:objectB toSection:sectionY];
    [self.groupedArray addObject:objectA toSection:sectionY];
    [self.groupedArray addObject:objectC toSection:sectionY];
    
    XCTAssertEqual(objectE, [self.groupedArray objectAtIndex:0 inSection:sectionY], @"Objects should not be sorted.");
    XCTAssertEqual(objectB, [self.groupedArray objectAtIndex:1 inSection:sectionY], @"Objects should not be sorted.");
    XCTAssertEqual(objectA, [self.groupedArray objectAtIndex:2 inSection:sectionY], @"Objects should not be sorted.");
    XCTAssertEqual(objectC, [self.groupedArray objectAtIndex:3 inSection:sectionY], @"Objects should not be sorted.");
    
    [self.groupedArray addObject:objectA toSection:sectionW];
    [self.groupedArray addObject:objectF toSection:sectionX];
    [self.groupedArray addObject:objectD toSection:sectionZ];
    [self.groupedArray addObject:objectD toSection:sectionW];
    
    XCTAssertEqual(sectionY, [self.groupedArray sectionAtIndex:0], @"Sections should not be sorted.");
    XCTAssertEqual(sectionW, [self.groupedArray sectionAtIndex:1], @"Sections should not be sorted.");
    XCTAssertEqual(sectionX, [self.groupedArray sectionAtIndex:2], @"Sections should not be sorted.");
    XCTAssertEqual(sectionZ, [self.groupedArray sectionAtIndex:3], @"Sections should not be sorted.");
}

/**
 Test the filterSectionsUsingPredicate: method.
 */
- (void)testFilterSectionsUsingPredicate
{
    [self.groupedArray addObject:objectE toSection:sectionY];
    [self.groupedArray addObject:objectB toSection:sectionY];
    [self.groupedArray addObject:objectA toSection:sectionY];
    [self.groupedArray addObject:objectC toSection:sectionY];
    [self.groupedArray addObject:objectA toSection:sectionW];
    [self.groupedArray addObject:objectF toSection:sectionX];
    [self.groupedArray addObject:objectD toSection:sectionZ];
    [self.groupedArray addObject:objectD toSection:sectionW];
    
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return evaluatedObject == sectionZ;
    }];
    
    XCTAssert([self.groupedArray countAllSections] == 4, @"There should be 4 sections.");
    XCTAssert([self.groupedArray countAllObjects] == 8, @"There should be 8 objects.");
    XCTAssert([self.groupedArray containsSection:sectionW], @"Section W should exist.");
    XCTAssert([self.groupedArray containsSection:sectionX], @"Section X should exist.");
    XCTAssert([self.groupedArray containsSection:sectionY], @"Section Y should exist.");
    XCTAssert([self.groupedArray containsSection:sectionZ], @"Section Z should exist.");
    
    [self.groupedArray filterUsingSectionPredicate:predicate objectPredicate:nil];
    
    XCTAssert([self.groupedArray countAllSections] == 1, @"There should be 1 section.");
    XCTAssert([self.groupedArray countAllObjects] == 1, @"There should be 1 object.");
    XCTAssertFalse([self.groupedArray containsSection:sectionW], @"Section Y should not exist.");
    XCTAssertFalse([self.groupedArray containsSection:sectionX], @"Section Y should not exist.");
    XCTAssertFalse([self.groupedArray containsSection:sectionY], @"Section Y should not exist.");
    XCTAssert([self.groupedArray containsSection:sectionZ], @"Section Z should exist.");
}

/**
 Test the filterObjectsUsingPredicate: method.
 */
- (void)testFilterObjectsUsingPredicate
{
    [self.groupedArray addObject:objectE toSection:sectionY];
    [self.groupedArray addObject:objectB toSection:sectionY];
    [self.groupedArray addObject:objectA toSection:sectionY];
    [self.groupedArray addObject:objectC toSection:sectionY];
    [self.groupedArray addObject:objectA toSection:sectionW];
    [self.groupedArray addObject:objectF toSection:sectionX];
    [self.groupedArray addObject:objectD toSection:sectionZ];
    [self.groupedArray addObject:objectD toSection:sectionW];
    
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
    
    [self.groupedArray filterUsingSectionPredicate:nil objectPredicate:predicate];
    
    XCTAssert([self.groupedArray countAllSections] == 2, @"There should be 2 sections.");
    XCTAssert([self.groupedArray countAllObjects] == 2, @"There should be 2 objects.");
    XCTAssert([self.groupedArray containsSection:sectionW], @"Section Y should exist.");
    XCTAssertFalse([self.groupedArray containsSection:sectionX], @"Section Y should not exist.");
    XCTAssert([self.groupedArray containsSection:sectionY], @"Section Y should exist.");
    XCTAssertFalse([self.groupedArray containsSection:sectionZ], @"Section Z should not exist.");
    XCTAssert([self.groupedArray containsObject:objectA], @"Object A should exist.");
    XCTAssertFalse([self.groupedArray containsObject:objectB], @"Object B should not exist.");
    XCTAssertFalse([self.groupedArray containsObject:objectC], @"Object C should not exist.");
    XCTAssertFalse([self.groupedArray containsObject:objectD], @"Object D should not exist.");
    XCTAssertFalse([self.groupedArray containsObject:objectE], @"Object E should not exist.");
    XCTAssertFalse([self.groupedArray containsObject:objectF], @"Object F should not exist.");
}

/**
 Test the filterSectionsUsingPredicate: method.
 */
- (void)testFilterSectionsAndObjectsUsingPredicate
{
    [self.groupedArray addObject:objectE toSection:sectionY];
    [self.groupedArray addObject:objectB toSection:sectionY];
    [self.groupedArray addObject:objectA toSection:sectionY];
    [self.groupedArray addObject:objectC toSection:sectionY];
    [self.groupedArray addObject:objectA toSection:sectionW];
    [self.groupedArray addObject:objectF toSection:sectionX];
    [self.groupedArray addObject:objectD toSection:sectionZ];
    [self.groupedArray addObject:objectD toSection:sectionW];
    
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
    
    [self.groupedArray filterUsingSectionPredicate:sectionPredicate objectPredicate:objectPredicate];
    
    XCTAssert([self.groupedArray countAllSections] == 0);
    XCTAssert([self.groupedArray countAllObjects] == 0);
}

- (void)testSortUsingSectionComparatorObjectComparator
{
    [self addUnsortedSectionsAndObjects];
    
    INTUGroupedArray *unsorted = [self.groupedArray copy];
    
    [self.groupedArray sortUsingSectionComparator:nil objectComparator:nil];
    XCTAssert([self.groupedArray isEqualToGroupedArray:unsorted]);
    
    self.groupedArray = [unsorted mutableCopy];
    [self.groupedArray sortUsingSectionComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) { return [obj1 compare:obj2]; }
                                 objectComparator:nil];
    
    XCTAssertEqual(sectionW, [self.groupedArray sectionAtIndex:0], @"Sections should be sorted.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionW] == 2, @"There should be 2 objects in sectionW.");
    XCTAssertEqual(sectionX, [self.groupedArray sectionAtIndex:1], @"Sections should be sorted.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionX] == 1, @"There should be 1 objects in sectionX.");
    XCTAssertEqual(sectionY, [self.groupedArray sectionAtIndex:2], @"Sections should be sorted.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionY] == 4, @"There should be 4 objects in sectionY.");
    XCTAssertEqual(sectionZ, [self.groupedArray sectionAtIndex:3], @"Sections should be sorted.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionZ] == 1, @"There should be 1 objects in sectionZ.");
    
    self.groupedArray = [unsorted mutableCopy];
    [self.groupedArray sortUsingSectionComparator:nil
                                 objectComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) { return [obj1 compare:obj2]; }];
    
    XCTAssertEqual(objectA, [self.groupedArray objectAtIndex:0 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectB, [self.groupedArray objectAtIndex:1 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectC, [self.groupedArray objectAtIndex:2 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectE, [self.groupedArray objectAtIndex:3 inSection:sectionY], @"Objects should be sorted.");
    
    self.groupedArray = [unsorted mutableCopy];
    [self.groupedArray sortUsingSectionComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) { return [obj1 compare:obj2]; }
                                 objectComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) { return [obj1 compare:obj2]; }];
    
    XCTAssertEqual(sectionW, [self.groupedArray sectionAtIndex:0], @"Sections should be sorted.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionW] == 2, @"There should be 2 objects in sectionW.");
    XCTAssertEqual(sectionX, [self.groupedArray sectionAtIndex:1], @"Sections should be sorted.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionX] == 1, @"There should be 1 objects in sectionX.");
    XCTAssertEqual(sectionY, [self.groupedArray sectionAtIndex:2], @"Sections should be sorted.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionY] == 4, @"There should be 4 objects in sectionY.");
    XCTAssertEqual(sectionZ, [self.groupedArray sectionAtIndex:3], @"Sections should be sorted.");
    XCTAssertTrue([self.groupedArray countObjectsInSection:sectionZ] == 1, @"There should be 1 objects in sectionZ.");
    XCTAssertEqual(objectA, [self.groupedArray objectAtIndex:0 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectB, [self.groupedArray objectAtIndex:1 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectC, [self.groupedArray objectAtIndex:2 inSection:sectionY], @"Objects should be sorted.");
    XCTAssertEqual(objectE, [self.groupedArray objectAtIndex:3 inSection:sectionY], @"Objects should be sorted.");
}

- (void)fastEnumerateEnumerator:(NSEnumerator *)e
{
    NSMutableArray *dummy = [NSMutableArray new];
    for (id obj in e) {
        [dummy addObject:obj];
    }
    XCTAssert(dummy);
}

- (void)testObjectEnumeratorMutation
{
    [self addUnsortedSectionsAndObjects];
    NSEnumerator *e;
    
    // Test mutating the grouped array between calls of nextObject, fast enumeration (and vice versa) throws an exception
    
    e = [self.groupedArray objectEnumerator];
    
    XCTAssertNoThrow([e nextObject]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([e allObjects]);
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    
    e = [self.groupedArray objectEnumerator];
    
    XCTAssertNoThrow([e allObjects]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([e allObjects]);
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    
    e = [self.groupedArray objectEnumerator];
    
    XCTAssertNoThrow([self fastEnumerateEnumerator:e]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([e allObjects]);
}

- (void)testReverseObjectEnumeratorMutation
{
    [self addUnsortedSectionsAndObjects];
    NSEnumerator *e;
    
    // Test mutating the grouped array between calls of nextObject, fast enumeration (and vice versa) throws an exception
    
    e = [self.groupedArray reverseObjectEnumerator];
    
    XCTAssertNoThrow([e nextObject]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([e allObjects]);
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    
    e = [self.groupedArray reverseObjectEnumerator];
    
    XCTAssertNoThrow([e allObjects]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([e allObjects]);
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    
    e = [self.groupedArray reverseObjectEnumerator];
    
    XCTAssertNoThrow([self fastEnumerateEnumerator:e]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([e allObjects]);
}

- (void)testSectionEnumeratorMutation
{
    [self addUnsortedSectionsAndObjects];
    NSEnumerator *e;
    
    // Test mutating the grouped array between calls of nextObject, fast enumeration (and vice versa) throws an exception
    
    e = [self.groupedArray sectionEnumerator];
    
    XCTAssertNoThrow([e nextObject]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([e allObjects]);
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    
    e = [self.groupedArray sectionEnumerator];
    
    XCTAssertNoThrow([e allObjects]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([e allObjects]);
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    
    e = [self.groupedArray sectionEnumerator];
    
    XCTAssertNoThrow([self fastEnumerateEnumerator:e]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([e allObjects]);
}

- (void)testReverseSectionEnumeratorMutation
{
    [self addUnsortedSectionsAndObjects];
    NSEnumerator *e;
    
    // Test mutating the grouped array between calls of nextObject, fast enumeration (and vice versa) throws an exception
    
    e = [self.groupedArray reverseSectionEnumerator];
    
    XCTAssertNoThrow([e nextObject]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([e allObjects]);
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    
    e = [self.groupedArray reverseSectionEnumerator];
    
    XCTAssertNoThrow([e allObjects]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([e allObjects]);
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    
    e = [self.groupedArray reverseSectionEnumerator];
    
    XCTAssertNoThrow([self fastEnumerateEnumerator:e]);
    [self.groupedArray addObject:@"New Object" toSection:@"New Section"];
    XCTAssertThrows([self fastEnumerateEnumerator:e]);
    XCTAssertThrows([e nextObject]);
    XCTAssertThrows([e allObjects]);
}

@end
