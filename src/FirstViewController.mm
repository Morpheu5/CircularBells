#import <Social/Social.h>

#import "FirstViewController.h"
#import "ScaleSelectionTableViewController.h"
#import "InstrumentSelectViewController.h"
#import "SupportUsViewController.h"
#import "PresetsTableViewController.h"

#include "cinder/app/App.h"
#include "CircularBellsApp.h"
#include "lzw.h"

@implementation FirstViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// Prepare the store observer for in-app purchases
	_storeObserver = [[[StoreObserver alloc] init] retain];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:_storeObserver];
	
	// [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeBanner) name:@"RemoveAdsPurchased" object:_storeObserver];
	
	// Setup the UI around the main Cinder application window
	UIViewController *cinderViewParent = ci::app::getWindow()->getNativeViewController();
	self.viewControllers = @[cinderViewParent];
	
	cinderViewParent.navigationController.delegate = self;
	
	[self setNavigationBarHidden:YES];
	[self.navigationBar setTintColor:[UIColor purpleColor]];
	UIBarButtonItem *leftSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
	leftSpacer.width = -10;
	
	UIBarButtonItem *pushUpButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/push-up.png"]
																	 style:UIBarButtonItemStylePlain
																	target:self
																	action:@selector(pushUpPushed:)];
	pushUpButton.accessibilityLabel = NSLocalizedString(@"Push up", @"a11y");

	UIBarButtonItem *scalesButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/scale.png"]
																  style:UIBarButtonItemStylePlain
																 target:self
																 action:@selector(scalePushed:)];
	scalesButton.accessibilityLabel = NSLocalizedString(@"Change scale", @"a11y");

	UIBarButtonItem *bellButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/bell.png"]
																   style:UIBarButtonItemStylePlain
																  target:self
																  action:@selector(bellPushed:)];
	bellButton.accessibilityLabel = NSLocalizedString(@"Change instrument", @"a11y");

//	UIBarButtonItem *presetsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/presets.png"]
//																	  style:UIBarButtonItemStylePlain
//																	 target:self
//																	 action:@selector(presetsPushed:)];
//	presetsButton.accessibilityLabel = NSLocalizedString(@"Change preset", @"a11y");

	UIBarButtonItem *resetPositionsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/resetpositions.png"]
																			  style:UIBarButtonItemStylePlain
																			target:self
																			action:@selector(resetPositionsPushed:)];
	resetPositionsButton.accessibilityLabel = NSLocalizedString(@"Go back to initial position", @"a11y");

	UIBarButtonItem *perlinButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/perlin.png"]
																	 style:UIBarButtonItemStylePlain
																	target:self
																	action:@selector(togglePerlin:)];
	perlinButton.accessibilityLabel = NSLocalizedString(@"Toggle bells floating", @"a11y");

	UIBarButtonItem *lockButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/unlocked.png"]
																   style:UIBarButtonItemStylePlain
																  target:self
																  action:@selector(toggleLock:)];
	lockButton.accessibilityLabel = NSLocalizedString(@"Lock bells", @"a11y");

//	UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
//																				 target:self
//																				 action:@selector(sharePushed:)];
//	shareButton.accessibilityLabel = NSLocalizedString(@"Share you work", @"a11y");

	UIBarButtonItem *supportUsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"assets/icons/info.png"]
																		style:UIBarButtonItemStylePlain
																	   target:self
																	   action:@selector(supportUs:)];
	supportUsButton.accessibilityLabel = NSLocalizedString(@"About us", @"a11y");

	[cinderViewParent.navigationItem setLeftBarButtonItems:@[leftSpacer, pushUpButton, scalesButton, bellButton/*, presetsButton*/]];
	[cinderViewParent.navigationItem setRightBarButtonItems:@[supportUsButton, /*shareButton,*/ lockButton, perlinButton, resetPositionsButton]];
	
	UIImage *pullDownImage = [UIImage imageNamed:@"assets/icons/pull-down.png"];
	_pullDownButton = [[UIButton alloc] init];
	_pullDownButton.backgroundColor = [UIColor colorWithPatternImage:pullDownImage];
	_pullDownButton.alpha = 0.5f;
	[_pullDownButton setTintColor:[UIColor purpleColor]];
	[_pullDownButton addTarget:self action:@selector(pullDownPushed:) forControlEvents:UIControlEventTouchUpInside];
	
	[cinderViewParent.view addSubview:_pullDownButton];
	_pullDownButton.translatesAutoresizingMaskIntoConstraints = NO;
	[cinderViewParent.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==16)-[_pullDownButton(44.0)]-(>=0)-|"
																				  options:0
																				  metrics:nil
																					views:NSDictionaryOfVariableBindings(_pullDownButton)]];
	[cinderViewParent.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(==16)-[_pullDownButton(44.0)]-(>=0)-|"
																				  options:0
																				  metrics:nil
																					views:NSDictionaryOfVariableBindings(_pullDownButton)]];

	// Check if the in-app purchases registry exists
	NSData *value = [[NSUserDefaults standardUserDefaults] dataForKey:@"RemoveAds"];
	if(value == nil) {
		// The user hasn't given us their BIG MONEY!!1
		// Setup iAd stuff
	}
}

- (void)viewWillDisappear:(BOOL)animated {

}

#pragma mark - UI settings stuff

- (BOOL)prefersStatusBarHidden {
	return YES;
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
		[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unexpected error", nil)
									message:NSLocalizedString(@"Instrument list not found. Please contact us and report this bug.", nil)
								   delegate:nil
						  cancelButtonTitle:NSLocalizedString(@"OK", nil)
						  otherButtonTitles:nil]
		 show];
	}
}

- (IBAction)supportUs:(id)sender {
	UIViewController *cinderViewParent = ci::app::getWindow()->getNativeViewController();
	cinderViewParent.title = NSLocalizedString(@"Back", nil);
	SupportUsViewController *vc = [[UIStoryboard storyboardWithName:@"Storyboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SupportUs"];
	vc.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStylePlain target:nil action:nil];
	
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

- (void)toggleLock:(UIBarButtonItem *)sender {
	CircularBellsApp *theApp = static_cast<CircularBellsApp *>(cinder::app::App::get());
	theApp->toggleLocked();
	if(theApp->isLocked()) {
		[sender setImage:[UIImage imageNamed:@"assets/icons/locked.png"]];
	} else {
		[sender setImage:[UIImage imageNamed:@"assets/icons/unlocked.png"]];
	}
}

- (void)presetsPushed:(UIBarButtonItem *)sender {
	PresetsTableViewController *vc = (PresetsTableViewController *)[[UIStoryboard storyboardWithName:@"Storyboard" bundle:nil] instantiateViewControllerWithIdentifier:@"PresetsVC"]; //[[PresetsTableViewController alloc] init];
	vc.modalPresentationStyle = UIModalPresentationFormSheet;
	
	[self presentViewController:vc
					   animated:YES
					 completion:nil];
}

- (void)resetPositionsPushed:(UIBarButtonItem *)sender {
	CircularBellsApp *theApp = static_cast<CircularBellsApp *>(cinder::app::App::get());
	theApp->resetPositions();
}

- (void)sharePushed:(UIBarButtonItem *)sender {
	CircularBellsApp *theApp = static_cast<CircularBellsApp *>(cinder::app::App::get());
	NSString *path = [NSString stringWithUTF8String:theApp->saveScreenshot().c_str()];
	UIImage *image = [UIImage imageWithContentsOfFile:path];
	map<int, vec2> positions = theApp->getPositions();
	
	ostringstream stream;
	for(pair<int, vec2> p : positions) {
		stream << to_string((int)round(p.second.x)) << "," << to_string((int)round(p.second.y)) << ",";
	}
	string src = stream.str();
	src.pop_back();
	
	std::vector<int> compressed;
	compress(src, std::back_inserter(compressed));
	u16string compressedString;
	for(int i : compressed) {
		auto c = (char16_t)i;
		compressedString.push_back(c);
	}

	NSData *s_data = [NSData dataWithBytes:compressedString.data() length:compressedString.size()*sizeof(char16_t)];
	NSString *s_base64 = [s_data base64EncodedStringWithOptions:0];
	NSString *s_urlencoded = [s_base64 stringByAddingPercentEscapesUsingEncoding:NSUnicodeStringEncoding];
	
	UIActivityViewController *vc = [[UIActivityViewController alloc]
									initWithActivityItems:@[[NSString stringWithFormat:NSLocalizedString(@"Look what I made with #CircularBells! http://cb.morpheu5.net/v1/%@", @"Share message"), s_urlencoded], image]
									applicationActivities:nil];
	
	if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		if([vc respondsToSelector:@selector(popoverPresentationController)]) {
			vc.popoverPresentationController.barButtonItem = sender;
		}
	}
	
	[self presentViewController:vc
					   animated:YES
					 completion:nil];
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
