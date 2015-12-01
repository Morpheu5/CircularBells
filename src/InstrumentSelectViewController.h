#import <UIKit/UIKit.h>

@interface InstrumentSelectViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *instrumentsList;

@end
