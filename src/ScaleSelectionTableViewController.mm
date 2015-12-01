#include "CircularBellsApp.h"

#import "ScaleSelectionTableViewController.h"

@interface ScaleSelectionTableViewController () {
	vector<string> _scaleNames;
	string _currentScaleName;
}

@end

@implementation ScaleSelectionTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"scaleCell"];
	
	CircularBellsApp *theApp = static_cast<CircularBellsApp *>(cinder::app::App::get());
	_scaleNames = theApp->getAvailableScales();
	_currentScaleName = theApp->getCurrentScaleName();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if(section == 0) {
		return _scaleNames.size();
	} else {
		return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(section == 0) {
		return @"Choose a scale…";
	} else {
		return @"";
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"scaleCell" forIndexPath:indexPath];
	cell.textLabel.text = [NSString stringWithUTF8String:_scaleNames[indexPath.row].c_str()];
	if(_scaleNames[indexPath.row] == _currentScaleName) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	CircularBellsApp *theApp = static_cast<CircularBellsApp *>(cinder::app::App::get());
	theApp->setCurrentScale(_scaleNames[indexPath.row]);
	_currentScaleName = theApp->getCurrentScaleName();
	[self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end
