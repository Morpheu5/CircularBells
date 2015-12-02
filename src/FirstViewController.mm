#import "FirstViewController.h"
#import "ScaleSelectionTableViewController.h"
#import "InstrumentSelectViewController.h"
#import "SupportUsViewController.h"
#import "PresetsTableViewController.h"

#include "cinder/app/App.h"
#include "CircularBellsApp.h"

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// Prepare the store observer for in-app purchases
	_storeObserver = [[[StoreObserver alloc] init] retain];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:_storeObserver];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeBanner) name:@"RemoveAdsPurchased" object:_storeObserver];
	
	// Setup the UI around the main Cinder application window
	UIViewController *cinderViewParent = ci::app::getWindow()->getNativeViewController();
	self.viewControllers = @[cinderViewParent];
	
	cinderViewParent.navigationController.delegate = self;
	
	cinderViewParent.title = @"Circular Bells";
	[self setNavigationBarHidden:YES];
	[self.navigationBar setTintColor:[UIColor purpleColor]];
	UIBarButtonItem *leftSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	leftSpacer.width = -10;
	
	UIBarButtonItem *pushUpButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/push-up.png"]
																	 style:UIBarButtonItemStylePlain
																	target:self
																	action:@selector(pushUpPushed:)];
	UIBarButtonItem *keyButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/scale.png"]
																  style:UIBarButtonItemStylePlain
																 target:self
																 action:@selector(scalePushed:)];
	UIBarButtonItem *bellButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/bell.png"]
																   style:UIBarButtonItemStylePlain
																  target:self
																  action:@selector(bellPushed:)];
	UIBarButtonItem *presetsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/presets.png"]
																	  style:UIBarButtonItemStylePlain
																	 target:self
																	 action:@selector(presetsPushed:)];
	UIBarButtonItem *perlinButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/pause.png"]
																	 style:UIBarButtonItemStylePlain
																	target:self
																	action:@selector(togglePerlin:)];
	UIBarButtonItem *supportUsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/info.png"]
																		style:UIBarButtonItemStylePlain
																	   target:self
																	   action:@selector(supportUs:)];
	
	[cinderViewParent.navigationItem setLeftBarButtonItems:@[leftSpacer, pushUpButton, keyButton, bellButton, /*presetsButton,*/ perlinButton]];
	[cinderViewParent.navigationItem setRightBarButtonItems:@[supportUsButton]];
	
	UIImage *pullDownImage = [UIImage imageNamed:@"assets/icons/pull-down.png"];
	_pullDownButton = [[UIButton alloc] init];
	_pullDownButton.backgroundColor = [UIColor colorWithPatternImage:pullDownImage];
	_pullDownButton.alpha = 0.5f;
	[_pullDownButton setTintColor:[UIColor purpleColor]];
	[_pullDownButton addTarget:self action:@selector(pullDownPushed:) forControlEvents:UIControlEventTouchUpInside];
	
	[cinderViewParent.view addSubview:_pullDownButton];
	_pullDownButton.translatesAutoresizingMaskIntoConstraints = NO;
	[cinderViewParent.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==0)-[_pullDownButton(44.0)]-(>=0)-|"
																				  options:0
																				  metrics:nil
																					views:NSDictionaryOfVariableBindings(_pullDownButton)]];
	[cinderViewParent.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==0)-[_pullDownButton(44.0)]-(>=0)-|"
																				  options:0
																				  metrics:nil
																					views:NSDictionaryOfVariableBindings(_pullDownButton)]];

	// Check if the in-app purchases registry exists
	NSData *value = [[NSUserDefaults standardUserDefaults] dataForKey:@"RemoveAds"];
	if(value == nil) { // The user hasn't given us their BIG MONEY!!1
		// Setup iAd stuff
		_isBannerVisible = NO;
		_bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
		CGRect frame = _bannerView.frame;
		frame.origin.y = self.view.bounds.size.height;
		_bannerView.frame = frame;
		_bannerView.delegate = self;
		[cinderViewParent.view addSubview:_bannerView];
	}
}

#pragma mark - UI settings stuff

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
//	if(viewController == ci::app::getWindow()->getNativeViewController()) {
//		ci::app::setFrameRate(60.0f);
//	}
}

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

- (IBAction)scalePushed:(id)sender {
	ScaleSelectionTableViewController *vc = [[ScaleSelectionTableViewController alloc] initWithStyle:UITableViewStylePlain];
	vc.modalPresentationStyle = UIModalPresentationFormSheet;
	
	[self presentViewController:vc
					   animated:YES
					 completion:nil];
}

- (IBAction)bellPushed:(UIBarButtonItem *)sender {
	InstrumentSelectViewController *vc = [[UIStoryboard storyboardWithName:@"Storyboard" bundle:nil] instantiateViewControllerWithIdentifier:@"InstrumentSelectVC"];
	NSString *filepath = [[NSBundle mainBundle] pathForResource:@"assets/Instruments" ofType:@"plist"];
	if([[NSFileManager defaultManager] fileExistsAtPath:filepath]) {
		vc.instrumentsList = [NSArray arrayWithContentsOfFile:filepath];
		vc.modalPresentationStyle = UIModalPresentationFormSheet;
		
		[self presentViewController:vc
						   animated:YES
						 completion:nil];
	} else {
		[[[UIAlertView alloc] initWithTitle:@"Unexpected error"
								  message:@"Instrument list not found. Please contact us and report this bug."
								 delegate:nil
						cancelButtonTitle:@"OK"
						otherButtonTitles:nil]
		show];
	}

}

- (IBAction)supportUs:(id)sender {
	SupportUsViewController *vc = [[UIStoryboard storyboardWithName:@"Storyboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SupportUs"];
	vc.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
	
	UIViewController *cVc = ci::app::getWindow()->getNativeViewController();
	[cVc.navigationController pushViewController:vc animated:YES];
}

- (void)togglePerlin:(UIBarButtonItem *)sender {
	CircularBellsApp *theApp = static_cast<CircularBellsApp *>(cinder::app::App::get());
	theApp->togglePerlin();
	if(theApp->isPerlinEnabled()) {
		[sender setImage:[UIImage imageNamed:@"assets/icons/pause.png"]];
	} else {
		[sender setImage:[UIImage imageNamed:@"assets/icons/perlin.png"]];
	}
}

- (void)presetsPushed:(UIBarButtonItem *)sender {
	PresetsTableViewController *vc = [[PresetsTableViewController alloc] initWithStyle:UITableViewStylePlain];
	vc.modalPresentationStyle = UIModalPresentationFormSheet;
	
	[self presentViewController:vc
					   animated:YES
					 completion:nil];
}

#pragma mark - iAd stuff

- (void)removeBanner {
	_isBannerVisible = NO;
	[_bannerView removeFromSuperview];
}

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

// TODO Throttle down and back up on banners.

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
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:_storeObserver];
	_storeObserver = nil;
}

@end
