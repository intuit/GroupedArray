# [![INTUGroupedArray](https://github.com/intuit/GroupedArray/blob/master/Images/INTUGroupedArray.png?raw=true)](#)
[![Build Status](http://img.shields.io/travis/intuit/GroupedArray.svg?style=flat)](https://travis-ci.org/intuit/GroupedArray) [![Test Coverage](http://img.shields.io/coveralls/intuit/GroupedArray.svg?style=flat)](https://coveralls.io/r/intuit/GroupedArray) [![Version](http://img.shields.io/cocoapods/v/INTUGroupedArray.svg?style=flat)](http://cocoapods.org/pods/INTUGroupedArray) [![Platform](http://img.shields.io/cocoapods/p/INTUGroupedArray.svg?style=flat)](http://cocoapods.org/pods/INTUGroupedArray) [![License](http://img.shields.io/cocoapods/l/INTUGroupedArray.svg?style=flat)](LICENSE)

An Objective-C and Swift collection for iOS and OS X that stores objects grouped into sections.

INTUGroupedArray is an Objective-C data structure that takes the common one-dimensional array to the next dimension. The grouped array is designed with a familiar API to fit right in alongside Foundation collections like NSArray, with fully-featured immutable and mutable variants. A thin bridge brings the grouped array to Swift as native classes, where it harnesses the power, safety, and flexibility of generics, optionals, subscripts, literals, tuples, and much more.

INTUGroupedArray is extremely versatile, and can replace complicated nested arrays or combinations of other data structures as a general purpose data storage mechanism. The grouped array is ideal to use as a UITableView data source, as it is highly compatible with the data source and delegate callbacks -- requiring only a single line of code in many cases. However, it is suitable for use across the entire stack of iOS and OS X applications.

## Setup

### Objective-C

#### Using [CocoaPods](http://cocoapods.org)

1.	Add the pod `INTUGroupedArray` to your [Podfile](http://guides.cocoapods.org/using/the-podfile.html).

    	pod 'INTUGroupedArray'

2.	Run `pod install` from Terminal, then open your app's `.xcworkspace` file to launch Xcode.
3.	Import the umbrella header `INTUGroupedArrayImports.h` so that all the grouped array classes are available to use. Typically, this should be written as `#import <INTUGroupedArray/INTUGroupedArrayImports.h>`

#### Manually from GitHub

1.	Download the Objective-C source files in the [Source/INTUGroupedArray directory](Source/INTUGroupedArray).
2.	Add all the files to your Xcode project (drag and drop is easiest).
3.	Import the umbrella header `INTUGroupedArrayImports.h` so that all the grouped array classes are available to use.

### Swift

1.  To use the grouped array in Swift, you first need to obtain the Objective-C source code and integrate it into your project (see above).
2.	Download the `GroupedArray.swift` Swift source file in the [Source/Swift directory](Source/Swift) and add it to your project.
3.  If you haven't already, you will need to set up an [Objective-C Bridging Header](https://developer.apple.com/library/ios/documentation/swift/conceptual/buildingcocoaapps/MixandMatch.html) for your project.
4.	Add the umbrella header `INTUGroupedArrayImports.h` to your Bridging Header file. (The Swift grouped array classes depend on this so they can access the Objective-C source.)

At this point, the native Swift classes `GroupedArray` and `MutableGroupedArray` will be available to use in your project's Swift code.

## Concept
At a high level, the grouped array is a collection of sections, each of which contains an array of objects. Both the sections and objects can be instances of any class.

[![INTUGroupedArray Illustration](https://github.com/intuit/GroupedArray/blob/master/Images/INTUGroupedArray-Illustration.png?raw=true)](#)

The grouped array closely mirrors the structure of a UITableView, which also has rows organized into one or more sections. As a result, the table view data source and delegate methods map directly to grouped array API methods.

Some of the grouped array APIs are similar to those of a dictionary (e.g. retrieving the objects in a section by passing in the section itself, instead of its index). *Note that, unlike a dictionary, the grouped array does not require elements (sections or objects) to implement a `-hash` method or require that elements have a stable hash value once inside a grouped array. However, this comes at the cost of performance for certain operations like section lookups.*

Like the Foundation collections, there are two variants of the grouped array:

*  `INTUGroupedArray`: An immutable grouped array. Thread safe. (Swift type: `GroupedArray`)
*  `INTUMutableGroupedArray`: A mutable subclass. Not thread safe. (Swift type: `MutableGroupedArray`)

As a best practice, you should favor the static immutable grouped array over the dynamic mutable variant.

The performance of most operations is annotated in the detailed documentation above the implementation of each method in the .m file. (The documentation in the header files is abbreviated to provide a convenient API reference.)

### Key Design Points

#### No empty sections
Every section in a grouped array must contain at least one object, similar to how every key in a dictionary must be associated with a value. This design simplifies some of the complexity when dealing with multi-dimensional data structures. For example, this allows a section to be removed as soon as its last object is removed. If there is a use case where you do want an 'empty' section, you can use a single placeholder object to achieve this.

#### Sections should be unique
The grouped array is designed under the assumption that no two sections in the grouped array are considered equal (using `-isEqual:`). For example, this allows sections to be automatically created and removed as needed in the mutable grouped array. Although it is discouraged, it is technically possible to have duplicate sections, however this impairs the functionality of section-based APIs (e.g. `-indexOfSection:`, `-indexOfObject:inSection:`, `-addObject:toSection:`, and others) which will only operate on one instance of the section.

#### Errors are handled gracefully
Most errors are not fatal errors, and there is a better way to recover than terminating the entire app. In Debug builds, the grouped array will throw exceptions on errors, however with assertions disabled in Release builds, it will not crash. For example, attempting to access a section at an out-of-bounds index will throw an exception in Debug, but will simply return nil in Release. In the Swift grouped array, this is communicated via implicitly unwrapped optionals -- these values will only be nil if there was an error, so you should test for nil if you wish to avoid runtime errors.

## Usage

Here are some snippets of common operations with a grouped array. Note that this is only a small portion of the overall API -- refer to the source files for the full API and documentation.

### Objective-C

Create an immutable grouped array using the literal syntax:

    INTUGroupedArray *groupedArray = [INTUGroupedArray literal:@[@"Section 1", @[@"Object A", @"Object B"],
                                                                 @"Section 2", @[@"Object C"],
                                                                 @"Section 3", @[@"Object D", @"Object E", @"Object F"]]];

Count the number of sections and objects in the grouped array:

    NSUInteger sectionCount = [groupedArray countAllSections];
    NSUInteger objectCount = [groupedArray countAllObjects];

Access the first section:

    id section = [groupedArray sectionAtIndex:0];

Get an array of objects in the first section:

    NSArray *objectsInSection = [groupedArray objectsInSectionAtIndex:0];

Access the first object in the first section (using NSIndexPath):

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    id object = [groupedArray objectAtIndexPath:indexPath];	

Get an array of all objects:

    NSArray *allObjects = [groupedArray allObjects];

Iterate over the objects in the grouped array:

    for (id object in groupedArray) { /* do something with object */ }

Get a mutable copy of the immutable grouped array:

    INTUMutableGroupedArray *mutableGroupedArray = [groupedArray mutableCopy];

Add an object to the end of the first section:

    [mutableGroupedArray addObject:@"New Object" toSectionAtIndex:0];

Insert an object at the beginning of Section 3:

    [mutableGroupedArray insertObject:@"Another Object" atIndex:0 inSection:@"Section 3"];

Remove the second section:

    [mutableGroupedArray removeSectionAtIndex:1];

Test if two grouped arrays are equal (contain the same sections & objects):

    if ([groupedArray isEqual:mutableGroupedArray]) { /* the two grouped arrays are equal */ }

### Swift

Create an immutable grouped array (with both sections and objects of type NSString) using an array literal:

	let groupedArray: GroupedArray<NSString, NSString> = ["Section 1", ["Object A", "Object B"],
	                                                      "Section 2", ["Object C"],
	                                                      "Section 3", ["Object D", "Object E", "Object F"]]

Count the number of sections and objects:

    let sectionCount = groupedArray.countAllSections()
    let objectCount = groupedArray.countAllObjects()

Access the first section using a subscript:

    let section = groupedArray[0]

Access the first object in the second section using a subscript:

    let object = groupedArray[1, 0]

Access an object by index path using a subscript:

    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
    let object = groupedArray[indexPath]

Get the last object in the grouped array, if there is one:

    if let lastObject = groupedArray.lastObject() { /* do something with lastObject */ }

Iterate over the grouped array:

    for (section, object) in groupedArray { /* do something with the section/object */ }

Get a mutable copy of the immutable grouped array:

    var mutableGroupedArray = groupedArray.mutableCopy() // the type of mutableGroupedArray is inferred to be: MutableGroupedArray<NSString, NSString>

Replace the first object in the third section using a subscript:

    mutableGroupedArray[2, 0] = "Another Object"

Test if two grouped arrays are equal (contain the same sections & objects):

    if (groupedArray == mutableGroupedArray) { /* the two grouped arrays are equal */ }

## Sample Projects
There are two sample projects provided.

The [Objective-C sample project](GroupedArraySample) demonstrates how the grouped array can be used to back a table view on iOS. This project requires Xcode 6.0 or higher.

The [Swift sample project](SwiftGroupedArray) highlights some additional capabilities available when using the Swift interface. This project requires Xcode 6.1 or higher.

### Unit Tests
The unit test suite is incorporated into the Objective-C sample project. It is cross platform, and can run on iOS and OS X.

## Issues & Contributions
Please [open an issue here on GitHub](https://github.com/intuit/GroupedArray/issues/new) if you have a problem, suggestion, or other comment.

Pull requests are welcome and encouraged! There are no official guidelines, but please try to be consistent with the existing code style. Any contributions should include new or updated unit tests as necessary to maintain thorough test coverage.

## License
INTUGroupedArray is provided under the MIT license.

# INTU on GitHub
Check out more [iOS and OS X open source projects from Intuit](https://github.com/search?utf8=✓&q=user%3Aintuit+language%3Aobjective-c&type=Repositories&ref=searchresults)!
