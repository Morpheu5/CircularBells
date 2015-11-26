#import "FirstViewController.h"

#include "cinder/app/App.h"
#include "CircularBellsApp.h"

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	UIViewController *cinderViewParent = ci::app::getWindow()->getNativeViewController();
	
	self.viewControllers = @[cinderViewParent];
	
	cinderViewParent.title = @"Circular Bells";
	[self setNavigationBarHidden:YES];
//	cinderViewParent.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.infoButton];
//	cinderViewParent.toolbarItems = [self tabBarItems];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	[coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		ci::app::App::get()->resize();
	}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
