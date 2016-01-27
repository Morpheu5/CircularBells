#import "PresetsTableViewController.h"

#include "CircularBellsApp.h"

@interface PresetsTableViewController ()

@end

@implementation PresetsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	ci::app::setFrameRate(1.0f);
}

- (void)viewWillDisappear:(BOOL)animated {
	ci::app::setFrameRate(60.0f);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)sanitizeString:(NSString *)inString {
	CFMutableStringRef crazy = (__bridge CFMutableStringRef)[inString mutableCopy];
	CFStringTransform(crazy, NULL, kCFStringTransformToLatin, NO);
	CFStringTransform(crazy, NULL, kCFStringTransformStripCombiningMarks, NO);
	CFStringTransform(crazy, NULL, kCFStringTransformToUnicodeName, NO);
	NSString *decrazy = (__bridge NSString *)crazy;
	
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^A-Za-z0-9]" options:0 error:&error];
	decrazy = [regex stringByReplacingMatchesInString:decrazy options:0 range:NSMakeRange(0, decrazy.length) withTemplate:@"-"];
	
	return decrazy;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0) {
		return 40;
	} else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"presetCell" forIndexPath:indexPath];
    
	cell.textLabel.text = NSLocalizedString(@"Preset name", nil);
	
	
    return cell;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewRowAction *renameAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
																			title:NSLocalizedString(@"Rename", nil)
																		  handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
																			  // Do the rename here
																		  }];
	UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
																			title:NSLocalizedString(@"Delete", nil)
																		  handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
																			  // Do the delete here
																		  }];
	return @[deleteAction, renameAction];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

#pragma mark - Toolbar actions

- (IBAction)addPreset:(UIBarButtonItem *)sender {
}

- (IBAction)done:(UIBarButtonItem *)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Dunno...

- (void)dealloc {
	[_tableView release];
	[_toolBar release];
	[super dealloc];
}
@end
