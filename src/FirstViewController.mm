#import "FirstViewController.h"

#include "cinder/app/App.h"
#include "CircularBellsApp.h"

@interface FirstViewController()
	@property (nonatomic) BOOL isBannerVisible;
	@property (strong, nonatomic) ADBannerView* bannerView;
@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	UIViewController *cinderViewParent = ci::app::getWindow()->getNativeViewController();
	
	self.viewControllers = @[cinderViewParent];
	
	cinderViewParent.title = @"Circular Bells";
	[self setNavigationBarHidden:YES];
	//cinderViewParent.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.infoButton];
	//cinderViewParent.toolbarItems = [self tabBarItems];

	_isBannerVisible = NO;
	_bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
	CGRect frame = _bannerView.frame;
	frame.origin.y = self.view.bounds.size.height;
	_bannerView.frame = frame;
	_bannerView.delegate = self;
	[self.view addSubview:_bannerView];
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

//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
- (void)viewDidLayoutSubviews {
	CGSize bigSize = self.view.bounds.size;
	CGSize newSize = [_bannerView sizeThatFits:bigSize];
	if(_isBannerVisible) {
		_bannerView.frame = CGRectMake(0, bigSize.height - newSize.height, newSize.width, newSize.height);
	} else {
		_bannerView.frame = CGRectMake(0, bigSize.height, newSize.width, newSize.height);
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
