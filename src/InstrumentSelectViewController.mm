#include "CircularBellsApp.h"

#import "InstrumentSelectViewController.h"
#import "InstrumentCellView.h"

@interface InstrumentSelectViewController() {
	string _currentInstrument;
}
@end

@implementation InstrumentSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	CircularBellsApp *theApp = static_cast<CircularBellsApp *>(cinder::app::App::get());
	_currentInstrument = theApp->getInstrument();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_tableView sizeToFit];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0) {
		return @"Choose an instrument…";
	} else {
		return @"";
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0) {
		return _instrumentsList.count;
	} else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    InstrumentCellView *cell = [tableView dequeueReusableCellWithIdentifier:@"instrumentCell" forIndexPath:indexPath];
    
	cell.textLabel.text = _instrumentsList[indexPath.row][@"name"];
	if([[NSString stringWithUTF8String:_currentInstrument.c_str()] isEqualToString:_instrumentsList[indexPath.row][@"preset"]]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	CircularBellsApp *theApp = static_cast<CircularBellsApp *>(cinder::app::App::get());
	theApp->setInstrument([_instrumentsList[indexPath.row][@"preset"] cStringUsingEncoding:NSUTF8StringEncoding]);
	_currentInstrument = theApp->getInstrument();
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
