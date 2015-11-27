#import "FirstViewController.h"
#import "ScaleSelectionTableViewController.h"

#include "cinder/app/App.h"
#include "CircularBellsApp.h"

@interface FirstViewController()

@property (nonatomic) BOOL isBannerVisible;
@property (strong, nonatomic) ADBannerView *bannerView;

@property (strong, nonatomic) UIButton *pullDownButton;

- (IBAction)pullDownPushed:(UIButton *)sender;
- (IBAction)pushUpPushed:(UIButton *)sender;

- (IBAction)scaleSelect:(id)sender;

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	UIViewController *cinderViewParent = ci::app::getWindow()->getNativeViewController();
	
	self.viewControllers = @[cinderViewParent];
	
	cinderViewParent.title = @"";
	[self setNavigationBarHidden:YES];
	cinderViewParent.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/push-up.png"]
																						  style:UIBarButtonItemStylePlain
																						 target:self	 action:@selector(pushUpPushed:)];
	//cinderViewParent.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.infoButton];
	//cinderViewParent.toolbarItems = [self tabBarItems];
	
	UIBarButtonItem *keyButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/scale.png"]
																  style:UIBarButtonItemStylePlain
																 target:self action:@selector(scaleSelect:)];
	
	[cinderViewParent.navigationItem setLeftBarButtonItems:@[keyButton]];

	_isBannerVisible = NO;
	_bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
	CGRect frame = _bannerView.frame;
	frame.origin.y = self.view.bounds.size.height;
	_bannerView.frame = frame;
	_bannerView.delegate = self;
//	[self.view addSubview:_bannerView];
	// TODO: Enable this ^
	
	UIImage *pullDownImage = [UIImage imageNamed:@"assets/icons/pull-down.png"];
	_pullDownButton = [[UIButton alloc] init];
	_pullDownButton.backgroundColor = [UIColor colorWithPatternImage:pullDownImage];
	_pullDownButton.alpha = 0.5f;
	[_pullDownButton addTarget:self action:@selector(pullDownPushed:) forControlEvents:UIControlEventTouchUpInside];
	
	[cinderViewParent.view addSubview:_pullDownButton];
	_pullDownButton.translatesAutoresizingMaskIntoConstraints = NO;
	[cinderViewParent.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(>=0)-[_pullDownButton(44.0)]-(==10)-|"
																				  options:0
																				  metrics:nil
																					views:NSDictionaryOfVariableBindings(_pullDownButton)]];
	[cinderViewParent.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==10)-[_pullDownButton(44.0)]-(>=0)-|"
																				  options:0
																				  metrics:nil
																					views:NSDictionaryOfVariableBindings(_pullDownButton)]];
}

#pragma mark - UI settings stuff

- (IBAction)pullDownPushed:(UIButton *)sender {
	[UIView animateWithDuration:0.25 animations:^{
		_pullDownButton.alpha = 0.0f;
	}];
	[self setNavigationBarHidden:NO animated:YES];
}

- (IBAction)pushUpPushed:(UIButton *)sender {
	[self setNavigationBarHidden:YES animated:YES];
	[UIView animateWithDuration:0.25 animations:^{
		_pullDownButton.alpha = 0.5f;
	}];
}

- (IBAction)scaleSelect:(id)sender {
	ScaleSelectionTableViewController *vc = [[ScaleSelectionTableViewController alloc] initWithStyle:UITableViewStylePlain];
	vc.modalPresentationStyle = UIModalPresentationPopover;
	vc.popoverPresentationController.barButtonItem = sender;
	[self presentViewController:vc
					   animated:YES
					 completion:nil];
}

#pragma mark - iAd stuff

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
	if(!_isBannerVisible) {
		[UIView animateWithDuration:0.5 animations:^{
			CGRect frame = _bannerView.frame;
			frame.origin.y -= frame.size.height;
			_bannerView.frame = frame;
		} completion:^(BOOL finished) {
			_isBannerVisible = YES;
		}];
	}
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
	if(_isBannerVisible) {
		[UIView animateWithDuration:0.5 animations:^{
			CGRect frame = _bannerView.frame;
			frame.origin.y = self.view.bounds.size.height;
			_bannerView.frame = frame;
		} completion:^(BOOL finished) {
			_isBannerVisible = NO;
		}];
	}
}

- (void)viewDidLayoutSubviews {
	CGSize bigSize = self.view.bounds.size;
	CGSize newSize = [_bannerView sizeThatFits:bigSize];
	if(_isBannerVisible) {
		_bannerView.frame = CGRectMake(0, bigSize.height - newSize.height, newSize.width, newSize.height);
	} else {
		_bannerView.frame = CGRectMake(0, bigSize.height, newSize.width, newSize.height);
	}
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
