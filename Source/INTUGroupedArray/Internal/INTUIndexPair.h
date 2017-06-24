//
//  INTUIndexPair.h
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

#ifndef INTUIndexPair_h
#define INTUIndexPair_h

#import <Foundation/Foundation.h>
#import "INTUGroupedArrayDefines.h"

GA__INTU_ASSUME_NONNULL_BEGIN


struct INTUIndexPair {
    NSUInteger sectionIndex;
    NSUInteger objectIndex;
};
/**
 A struct that contains a section index and object index.
 Offers better performance than NSIndexPath, which has the overhead of being an Objective-C object.
 */
typedef struct INTUIndexPair INTUIndexPair;

/**
 Returns an INTUIndexPair with the section index and object index.
 */
static inline INTUIndexPair INTUIndexPairMake(NSUInteger sectionIndex, NSUInteger objectIndex)
{
    INTUIndexPair indexPair; indexPair.sectionIndex = sectionIndex; indexPair.objectIndex = objectIndex; return indexPair;
}

/**
 Returns an INTUIndexPair based on the first two indices in the NSIndexPath object.
 */
static inline INTUIndexPair INTUIndexPairConvert(NSIndexPath *indexPath)
{
    INTUIndexPair indexPair; indexPair.sectionIndex = [indexPath indexAtPosition:0]; indexPair.objectIndex = [indexPath indexAtPosition:1]; return indexPair;
}

GA__INTU_ASSUME_NONNULL_END

#endif /* INTUIndexPair_h */
