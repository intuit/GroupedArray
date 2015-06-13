//
//  ViewController.m
//  GroupedArraySample
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

#import "ViewController.h"
#import "INTUGroupedArrayImports.h"
#import "INTUFruitCategory.h"
#import "INTUFruit.h"

@interface ViewController ()

@property (nonatomic, strong) INTUMutableGroupedArray *groupedArray;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"INTUGroupedArray Demo";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editTapped:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadTapped:)];
    
    [self resetGroupedArray];
}

- (void)editTapped:(id)sender
{
    [self setEditing:!self.editing animated:YES];
    
    UIBarButtonSystemItem leftBarButtonItem = self.editing ? UIBarButtonSystemItemDone : UIBarButtonSystemItemEdit;
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:leftBarButtonItem target:self action:@selector(editTapped:)] animated:YES];
    UIBarButtonSystemItem rightBarButtonItem = self.editing ? UIBarButtonSystemItemTrash : UIBarButtonSystemItemRefresh;
    SEL rightBarButtonSelector = self.editing ? @selector(trashTapped:) : @selector(reloadTapped:);
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:rightBarButtonItem target:self action:rightBarButtonSelector] animated:YES];
}

- (void)reloadTapped:(id)sender
{
    [self.tableView reloadData];
}

- (void)trashTapped:(id)sender
{
    [self resetGroupedArray];
    [self.tableView reloadData];
}

- (void)resetGroupedArray
{
    INTUMutableGroupedArray *groupedArray = [INTUMutableGroupedArray new];
    
    INTUFruitCategory *smallRoundCategory = [INTUFruitCategory fruitCategoryWithDisplayName:@"Small Round"];
    [groupedArray addObject:[INTUFruit fruitWithName:@"Apple" color:@"Red"] toSection:smallRoundCategory];
    [groupedArray addObject:[INTUFruit fruitWithName:@"Orange" color:@"Orange"] toSection:smallRoundCategory];
    [groupedArray addObject:[INTUFruit fruitWithName:@"Lemon" color:@"Yellow"] toSection:smallRoundCategory];
    [groupedArray addObject:[INTUFruit fruitWithName:@"Kiwi" color:@"Green"] toSection:smallRoundCategory];
    
    INTUFruitCategory *largeRoundCategory = [INTUFruitCategory fruitCategoryWithDisplayName:@"Large Round"];
    [groupedArray addObject:[INTUFruit fruitWithName:@"Grapefruit" color:@"Pink"] toSection:largeRoundCategory];
    [groupedArray addObject:[INTUFruit fruitWithName:@"Melon" color:@"Brown"] toSection:largeRoundCategory];
    
    INTUFruitCategory *vegetableCategory = [INTUFruitCategory fruitCategoryWithDisplayName:@"Vegetable"];
    [groupedArray addObject:[INTUFruit fruitWithName:@"Tomato" color:@"Red"] toSection:vegetableCategory];
    
    INTUFruitCategory *otherCategory = [INTUFruitCategory fruitCategoryWithDisplayName:@"Other"];
    [groupedArray addObject:[INTUFruit fruitWithName:@"Banana" color:@"Yellow"] toSection:otherCategory];
    [groupedArray addObject:[INTUFruit fruitWithName:@"Strawberry" color:@"Red"] toSection:otherCategory];
    
    self.groupedArray = groupedArray;
}


#pragma mark UITableViewDataSource & UITableViewDelegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.groupedArray countAllSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.groupedArray countObjectsInSectionAtIndex:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    INTUFruit *fruit = [self.groupedArray objectAtIndexPath:indexPath];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.textLabel.text = fruit.name;
    cell.detailTextLabel.text = fruit.color;
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    INTUFruitCategory *fruitCategory = [self.groupedArray sectionAtIndex:section];
    return fruitCategory.displayName;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSUInteger originalSectionCount = [self.groupedArray countAllSections];
    [self.groupedArray moveObjectAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    if ([self.groupedArray countAllSections] < originalSectionCount) {
        // Use dispatch_async to push the section delete animation to the next run loop to avoid visual issues with UITableView
        dispatch_async(dispatch_get_main_queue(), ^{
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sourceIndexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSUInteger originalSectionCount = [self.groupedArray countAllSections];
        [self.groupedArray removeObjectAtIndexPath:indexPath];
        if ([self.groupedArray countAllSections] < originalSectionCount) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

@end
