//
//  ViewController.swift
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

import UIKit

class ViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        groupedArrayDemos()

        moreGroupedArrayDemos()
    }
    
    func groupedArrayDemos()
    {
        // Create a grouped array using the array literal syntax
        let groupedArray: GroupedArray<NSString, NSString> = ["Section 1", ["Object A", "Object B", "Object C"],
                                                              "Section 2", ["Object D"],
                                                              "Section 3", ["Object E", "Object F"],
                                                              "Section 4", ["Object G"]]
        
        // Access a section and object
        let section0 = groupedArray.sectionAtIndex(0)
        println("The first section is: \(section0)")
        let object00 = groupedArray.objectAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))
        println("The first object is: \(object00)")
        
        // Use some APIs that return optionals
        if let sectionIndex = groupedArray.indexOfSection("Section 4") {
            println("Found the section at index: \(sectionIndex)")
        }
        if let lastObject = groupedArray.lastObject() {
            println("The last object is: \(lastObject)")
        }
        
        
        // Iterate over the grouped array
        for (section, object) in groupedArray {
            println("Enumerating with tuple (section: \(section), object: \(object))")
        }
        
        // Iterate over just the sections
        for section in groupedArray.sectionEnumerator() {
            println("Enumerating section: \(section)")
        }
        
        // Iterate over the objects in reverse
        for object in groupedArray.reverseObjectEnumerator() {
            println("Enumerating reversed object: \(object)")
        }
        
        
        // Add objects to a mutable grouped array
        var mutableGroupedArray = MutableGroupedArray<NSString, NSString>()
        mutableGroupedArray.addObject("Object A", toSection: "Section 1")
        mutableGroupedArray.addObject("Object B", toSection: "Section 1")
        mutableGroupedArray.addObject("Object C", toSection: "Section 1")
        mutableGroupedArray.addObject("Object D", toSection: "Section 2")
        mutableGroupedArray.addObject("Object E", toSection: "Section 3")
        mutableGroupedArray.addObject("Object F", toSection: "Section 3")
        mutableGroupedArray.addObject("Object G", toSection: "Section 4")
        
        
        // Test equality using the == operator
        println("Are the two grouped arrays equal: \(groupedArray == mutableGroupedArray)")
        
        
        // Use subscripts to access a section by index
        let section = mutableGroupedArray[0]
        println("The first section is: \(section)")
        // Use subscripts to access an object passing in a section index and object index
        let object = mutableGroupedArray[0, 1]
        println("The second object in the first section is: \(object)")
        // Use subscripts to access an object by index path
        let indexPath = NSIndexPath(forRow: 2, inSection: 0)
        let anotherObject = mutableGroupedArray[indexPath]
        println("The third object in the first section is: \(anotherObject)")
        
        // Replace a section with a new section using subscripts
        mutableGroupedArray[1] = "New Section 2"
        println("The second section is now: \(mutableGroupedArray[1])")
        // Replace some objects with new objects using subscripts
        mutableGroupedArray[1, 0] = "New Object D"
        println("The object in the second section is now: \(mutableGroupedArray[1, 0])")
        mutableGroupedArray[indexPath] = "New Object C"
        println("The last object in the first section is now: \(mutableGroupedArray[indexPath])")
    }
    
    func moreGroupedArrayDemos()
    {
        // When using the array literal syntax, if the type is not explicitly annotated, it will default to a Swift Array
        let a = [5, ["Some text"], 10, ["Some more text"]]
        println(a)
        // Same literal, but with the GroupedArray type (and generics) made explicit
        var b: GroupedArray<NSNumber, NSString> = [5, ["Some text"], 10, ["Some more text"]]
        println(b)
    }
}
