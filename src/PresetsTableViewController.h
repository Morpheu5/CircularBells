//
//  PresetsTableViewController.h
//  CircularBells
//
//  Created by Andrea Franceschini on 01/12/15.
//
//

#import <UIKit/UIKit.h>

@interface PresetsTableViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIToolbar *toolBar;

- (IBAction)addPreset:(UIBarButtonItem *)sender;
- (IBAction)done:(UIBarButtonItem *)sender;

- (NSString *)sanitizeString:(NSString *)inString;

@end
