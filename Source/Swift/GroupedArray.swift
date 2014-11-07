//
//  GroupedArray.swift
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

import Foundation


public func ==<S1, O1, S2, O2>(lhs: GroupedArray<S1, O1>, rhs: GroupedArray<S2, O2>) -> Bool
{
    return lhs.intuGroupedArray.isEqualToGroupedArray(rhs.intuGroupedArray)
}


// MARK: GroupedArray

public class GroupedArray<S: AnyObject, O: AnyObject>: SequenceType, Equatable, Printable, DebugPrintable, ArrayLiteralConvertible
{
    private var intuGroupedArray: INTUGroupedArray
    
    public init()
    {
        intuGroupedArray = INTUGroupedArray()
    }
    
    public init(groupedArray: GroupedArray<S, O>)
    {
        intuGroupedArray = INTUGroupedArray(groupedArray: groupedArray.intuGroupedArray)
    }
    
    public init(groupedArray: GroupedArray<S, O>, copyItems: Bool)
    {
        intuGroupedArray = INTUGroupedArray(groupedArray: groupedArray.intuGroupedArray, copyItems: copyItems)
    }
    
    public init(array: [O])
    {
        intuGroupedArray = INTUGroupedArray(array: array)
    }
    
    public required init(arrayLiteral elements: AnyObject...)
    {
        intuGroupedArray = INTUGroupedArray.literal(elements)
    }
    
    
    public func copy() -> GroupedArray<S, O>
    {
        let newGroupedArray = GroupedArray<S, O>()
        newGroupedArray.intuGroupedArray = intuGroupedArray.copy() as INTUGroupedArray
        return newGroupedArray
    }
    
    public func mutableCopy() -> MutableGroupedArray<S, O>
    {
        let newGroupedArray = MutableGroupedArray<S, O>()
        newGroupedArray.intuGroupedArray = intuGroupedArray.mutableCopy() as INTUMutableGroupedArray
        return newGroupedArray
    }
    
    
    public var description: String {
        return intuGroupedArray.description
    }
    
    public var debugDescription: String {
        return intuGroupedArray.description
    }
    
    
    subscript (sectionIndex: Int) -> S! {
        return sectionAtIndex(sectionIndex)
    }
    
    subscript (sectionIndex: Int, objectIndex: Int) -> O! {
        return objectAtIndexPath(INTUGroupedArray.indexPathForRow(UInt(objectIndex), inSection: UInt(sectionIndex)))
    }
    
    subscript (indexPath: NSIndexPath) -> O! {
        return objectAtIndexPath(indexPath)
    }
    
    
    public func sectionAtIndex(index: Int) -> S!
    {
        return intuGroupedArray.sectionAtIndex(UInt(index)) as? S
    }
    
    public func countAllSections() -> Int
    {
        return Int(intuGroupedArray.countAllSections())
    }
    
    public func allSections() -> [S]
    {
        return intuGroupedArray.allSections() as [S]
    }
    
    public func containsSection(section: S) -> Bool
    {
        return intuGroupedArray.containsSection(section)
    }
    
    public func indexOfSection(section: S) -> Int?
    {
        let index = Int(intuGroupedArray.indexOfSection(section))
        return (index == NSNotFound) ? nil : index
    }
    
    
    public func objectAtIndex(index: Int, inSection section: S) -> O!
    {
        return intuGroupedArray.objectAtIndex(UInt(index), inSection: section) as? O
    }
    
    public func objectAtIndexPath(indexPath: NSIndexPath) -> O!
    {
        return intuGroupedArray.objectAtIndexPath(indexPath) as? O
    }
    
    public func firstObject() -> O?
    {
        return intuGroupedArray.firstObject() as? O
    }
    
    public func lastObject() -> O?
    {
        return intuGroupedArray.lastObject() as? O
    }
    
    public func containsObject(object: O) -> Bool
    {
        return intuGroupedArray.containsObject(object)
    }
    
    public func indexPathOfObject(object: O) -> NSIndexPath?
    {
        return intuGroupedArray.indexPathOfObject(object)
    }
    
    public func containsObject(object: O, inSection section: S) -> Bool
    {
        return intuGroupedArray.containsObject(object, inSection: section)
    }
    
    public func indexOfObject(object: O, inSection section: S) -> Int?
    {
        let index = Int(intuGroupedArray.indexOfObject(object, inSection: section))
        return (index == NSNotFound) ? nil : index
    }
    
    public func countObjectsInSection(section: S) -> Int
    {
        return Int(intuGroupedArray.countObjectsInSection(section))
    }
    
    public func countObjectsInSectionAtIndex(sectionIndex: Int) -> Int
    {
        return Int(intuGroupedArray.countObjectsInSectionAtIndex(UInt(sectionIndex)))
    }
    
    public func objectsInSection(section: S) -> [O]
    {
        return intuGroupedArray.objectsInSection(section) as [O]
    }
    
    public func objectsInSectionAtIndex(sectionIndex: Int) -> [O]
    {
        return intuGroupedArray.objectsInSectionAtIndex(UInt(sectionIndex)) as [O]
    }
    
    public func countAllObjects() -> Int
    {
        return Int(intuGroupedArray.countAllObjects())
    }
    
    public func allObjects() -> [O]
    {
        return intuGroupedArray.allObjects() as [O]
    }
    
    
    public func enumerateSections(block: (section: S, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void)
    {
        intuGroupedArray.enumerateSectionsUsingBlock { (section: AnyObject!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            block(section: section as S, index: Int(index), stop: stop)
        }
    }
    
    public func enumerateSections(options: NSEnumerationOptions, block: (section: S, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Void)
    {
        intuGroupedArray.enumerateSectionsWithOptions(options) { (section: AnyObject!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            block(section: section as S, index: Int(index), stop: stop)
        }
    }
    
    public func enumerateObjects(block: (object: O, indexPath: NSIndexPath, stop: UnsafeMutablePointer<ObjCBool>) -> Void)
    {
        intuGroupedArray.enumerateObjectsUsingBlock { (object: AnyObject!, indexPath: NSIndexPath!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            block(object: object as O, indexPath: indexPath, stop: stop)
        }
    }
    
    public func enumerateObjects(options: NSEnumerationOptions, block: (object: O, indexPath: NSIndexPath, stop: UnsafeMutablePointer<ObjCBool>) -> Void)
    {
        intuGroupedArray.enumerateObjectsWithOptions(options) { (object: AnyObject!, indexPath: NSIndexPath!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            block(object: object as O, indexPath: indexPath, stop: stop)
        }
    }
    
    public func enumerateObjectsInSectionAtIndex(sectionIndex: Int, block: (object: O, indexPath: NSIndexPath, stop: UnsafeMutablePointer<ObjCBool>) -> Void)
    {
        intuGroupedArray.enumerateObjectsInSectionAtIndex(UInt(sectionIndex)) { (object: AnyObject!, indexPath: NSIndexPath!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            block(object: object as O, indexPath: indexPath, stop: stop)
        }
    }
    
    public func enumerateObjectsInSectionAtIndex(sectionIndex: Int, withOptions options: NSEnumerationOptions, block: (object: O, indexPath: NSIndexPath, stop: UnsafeMutablePointer<ObjCBool>) -> Void)
    {
        intuGroupedArray.enumerateObjectsInSectionAtIndex(UInt(sectionIndex), withOptions: options) { (object: AnyObject!, indexPath: NSIndexPath!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            block(object: object as O, indexPath: indexPath, stop: stop)
        }
    }
    
    
    public func generate() -> GeneratorOf<(section: S, object: O)>
    {
        let groupedArray = self
        var sectionIndex = 0
        var objectIndex = 0
        return Swift.GeneratorOf {
            let sectionCount = groupedArray.countAllSections()
            if sectionIndex < sectionCount {
                let section = groupedArray.sectionAtIndex(sectionIndex)
                let objectCount = groupedArray.countObjectsInSectionAtIndex(sectionIndex)
                if objectIndex < objectCount {
                    let object = groupedArray.objectAtIndexPath(INTUGroupedArray.indexPathForRow(UInt(objectIndex), inSection: UInt(sectionIndex)))
                    objectIndex++
                    return (section, object)
                }
                objectIndex = 0
                sectionIndex++
            }
            return nil
        }
    }
    
    public func sectionEnumerator() -> GroupedArraySectionEnumerator<S>
    {
        return GroupedArraySectionEnumerator(intuGroupedArray.sectionEnumerator())
    }
    
    public func reverseSectionEnumerator() -> GroupedArraySectionEnumerator<S>
    {
        return GroupedArraySectionEnumerator(intuGroupedArray.reverseSectionEnumerator())
    }
    
    public func objectEnumerator() -> GroupedArrayObjectEnumerator<O>
    {
        return GroupedArrayObjectEnumerator(intuGroupedArray.objectEnumerator())
    }
    
    public func reverseObjectEnumerator() -> GroupedArrayObjectEnumerator<O>
    {
        return GroupedArrayObjectEnumerator(intuGroupedArray.reverseObjectEnumerator())
    }
    
    
    public func indexOfSectionPassingTest(predicate: (section: S, index: Int, stop: UnsafeMutablePointer<ObjCBool>) -> Bool) -> Int?
    {
        let index = Int(intuGroupedArray.indexOfSectionPassingTest { (section: AnyObject!, index: UInt, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return predicate(section: section as S, index: Int(index), stop: stop)
        })
        return (index == NSNotFound) ? nil : index
    }
    
    public func indexPathOfObjectPassingTest(predicate: (object: O, indexPath: NSIndexPath, stop: UnsafeMutablePointer<ObjCBool>) -> Bool) -> NSIndexPath?
    {
        return intuGroupedArray.indexPathOfObjectPassingTest { (object: AnyObject!, indexPath: NSIndexPath!, stop: UnsafeMutablePointer<ObjCBool>) -> Bool in
            return predicate(object: object as O, indexPath: indexPath, stop: stop)
        }
    }
    
    
    public func filtered(#sectionPredicate: NSPredicate, objectPredicate: NSPredicate) -> GroupedArray<S, O>
    {
        let newGroupedArray: GroupedArray<S, O> = GroupedArray()
        newGroupedArray.intuGroupedArray = intuGroupedArray.filteredGroupedArrayUsingSectionPredicate(sectionPredicate, objectPredicate: objectPredicate)
        return newGroupedArray
    }
    
    public func sorted(#sectionComparator: NSComparator, objectComparator: NSComparator) -> GroupedArray<S, O>
    {
        let newGroupedArray: GroupedArray<S, O> = GroupedArray()
        newGroupedArray.intuGroupedArray = intuGroupedArray.sortedGroupedArrayUsingSectionComparator(sectionComparator, objectComparator: objectComparator)
        return newGroupedArray
    }
}


// MARK: MutableGroupedArray

public class MutableGroupedArray<S: AnyObject, O: AnyObject>: GroupedArray<S, O>
{
    private var intuMutableGroupedArray: INTUMutableGroupedArray
    {
        return intuGroupedArray as INTUMutableGroupedArray
    }
    
    override public init()
    {
        super.init()
        intuGroupedArray = INTUMutableGroupedArray()
    }
    
    override public init(groupedArray: GroupedArray<S, O>)
    {
        super.init()
        intuGroupedArray = INTUMutableGroupedArray(groupedArray: groupedArray.intuGroupedArray)
    }
    
    override public init(groupedArray: GroupedArray<S, O>, copyItems: Bool)
    {
        super.init()
        intuGroupedArray = INTUMutableGroupedArray(groupedArray: groupedArray.intuGroupedArray, copyItems: copyItems)
    }
    
    override public init(array: [O])
    {
        super.init()
        intuGroupedArray = INTUMutableGroupedArray(array: array)
    }
    
    public required init(arrayLiteral elements: AnyObject...)
    {
        super.init()
        intuGroupedArray = INTUMutableGroupedArray.literal(elements)
    }
    
    
    override subscript (sectionIndex: Int) -> S! {
        get {
            return sectionAtIndex(sectionIndex)
        }
        set(newValue) {
            replaceSectionAtIndex(sectionIndex, withSection: newValue)
        }
    }
    
    override subscript (sectionIndex: Int, objectIndex: Int) -> O! {
        get {
            return objectAtIndexPath(INTUGroupedArray.indexPathForRow(UInt(objectIndex), inSection: UInt(sectionIndex)))
        }
        set(newValue) {
            replaceObjectAtIndexPath(INTUGroupedArray.indexPathForRow(UInt(objectIndex), inSection: UInt(sectionIndex)), withObject: newValue)
        }
    }
    
    override subscript (indexPath: NSIndexPath) -> O! {
        get {
            return objectAtIndexPath(indexPath)
        }
        set(newValue) {
            replaceObjectAtIndexPath(indexPath, withObject: newValue)
        }
    }


    public func addObject(object: O, toSection section: S)
    {
        intuMutableGroupedArray.addObject(object, toSection: section)
    }
    
    public func addObject(object: O, toSection section: S, withSectionIndexHint sectionIndexHint: Int)
    {
        intuMutableGroupedArray.addObject(object, toSection: section, withSectionIndexHint: UInt(sectionIndexHint))
    }
    
    public func addObject(object: O, toSectionAtIndex sectionIndex: Int)
    {
        intuMutableGroupedArray.addObject(object, toSectionAtIndex: UInt(sectionIndex))
    }
    
    public func addObjectsFromArray(objects: [O], toSection section: S)
    {
        intuMutableGroupedArray.addObjectsFromArray(objects, toSection: section)
    }
    
    
    public func insertObject(object: O, atIndex index: Int, inSection section: S)
    {
        intuMutableGroupedArray.insertObject(object, atIndex: UInt(index), inSection: section)
    }
    
    public func insertObject(object: O, atIndexPath indexPath: NSIndexPath)
    {
        intuMutableGroupedArray.insertObject(object, atIndexPath: indexPath)
    }
    
    
    public func replaceSectionAtIndex(index: Int, withSection section: S)
    {
        intuMutableGroupedArray.replaceSectionAtIndex(UInt(index), withSection: section)
    }
    
    public func replaceObjectAtIndexPath(indexPath: NSIndexPath, withObject object: O)
    {
        intuMutableGroupedArray.replaceObjectAtIndexPath(indexPath, withObject: object)
    }
    
    
    public func moveSectionAtIndex(fromIndex: Int, toIndex: Int)
    {
        intuMutableGroupedArray.moveSectionAtIndex(UInt(fromIndex), toIndex: UInt(toIndex))
    }
    
    public func moveObjectAtIndexPath(fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath)
    {
        intuMutableGroupedArray.moveObjectAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
    }
    
    
    public func exchangeSectionAtIndex(index1: Int, withSectionAtIndex index2: Int)
    {
        intuMutableGroupedArray.exchangeSectionAtIndex(UInt(index1), withSectionAtIndex: UInt(index2))
    }
    
    public func exchangeObjectAtIndexPath(indexPath1: NSIndexPath, withObjectAtIndexPath indexPath2: NSIndexPath)
    {
        intuMutableGroupedArray.exchangeObjectAtIndexPath(indexPath1, withObjectAtIndexPath: indexPath2)
    }
    
    
    public func removeAllObjects()
    {
        intuMutableGroupedArray.removeAllObjects()
    }
    
    public func removeSection(section: S)
    {
        intuMutableGroupedArray.removeSection(section)
    }
    
    public func removeSectionAtIndex(sectionIndex: Int)
    {
        intuMutableGroupedArray.removeSectionAtIndex(UInt(sectionIndex))
    }
    
    public func removeObject(object: O)
    {
        intuMutableGroupedArray.removeObject(object)
    }
    
    public func removeObject(object: O, fromSection section: S)
    {
        intuMutableGroupedArray.removeObject(object, fromSection: section)
    }
    
    public func removeObjectAtIndex(index: Int, fromSection section: S)
    {
        intuMutableGroupedArray.removeObjectAtIndex(UInt(index), fromSection: section)
    }
    
    public func removeObjectAtIndexPath(indexPath: NSIndexPath)
    {
        intuMutableGroupedArray.removeObjectAtIndexPath(indexPath)
    }
    
    
    public func filter(#sectionPredicate: NSPredicate, objectPredicate: NSPredicate)
    {
        intuMutableGroupedArray.filterUsingSectionPredicate(sectionPredicate, objectPredicate: objectPredicate)
    }
    
    public func sort(#sectionComparator: NSComparator, objectComparator: NSComparator)
    {
        intuMutableGroupedArray.sortUsingSectionComparator(sectionComparator, objectComparator: objectComparator)
    }
}


// MARK: Enumerators

public class GroupedArraySectionEnumerator<S: AnyObject>: SequenceType, GeneratorType, NSFastEnumeration
{
    private var enumerator: AnyObject // Must be a subclass of NSEnumerator; must also conform to INTUGroupedArraySectionEnumerator protocol
    
    public init(_ enumerator: AnyObject)
    {
        self.enumerator = enumerator
    }
    
    public func generate() -> GroupedArraySectionEnumerator<S>
    {
        return self
    }
    
    public func next() -> S?
    {
        return nextSection()
    }
    
    public func nextSection() -> S?
    {
        return enumerator.nextSection() as? S
    }
    
    public func allSections() -> [S]
    {
        return enumerator.allSections() as [S]
    }
    
    public func countByEnumeratingWithState(state: UnsafeMutablePointer<NSFastEnumerationState>, objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>, count len: Int) -> Int
    {
        return enumerator.countByEnumeratingWithState(state, objects: buffer, count: len)
    }
}

public class GroupedArrayObjectEnumerator<O: AnyObject>: SequenceType, GeneratorType, NSFastEnumeration
{
    private var enumerator: AnyObject // Must be a subclass of NSEnumerator
    
    public init(_ enumerator: AnyObject)
    {
        self.enumerator = enumerator
    }
    
    public func generate() -> GroupedArrayObjectEnumerator<O>
    {
        return self
    }
    
    public func next() -> O?
    {
        return nextObject()
    }
    
    public func nextObject() -> O?
    {
        return enumerator.nextObject() as? O
    }
    
    public func allObjects() -> [O]
    {
        return enumerator.allObjects as [O]
    }
    
    public func countByEnumeratingWithState(state: UnsafeMutablePointer<NSFastEnumerationState>, objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>, count len: Int) -> Int
    {
        return enumerator.countByEnumeratingWithState(state, objects: buffer, count: len)
    }
}
