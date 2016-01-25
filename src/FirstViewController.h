#import <UIKit/UIKit.h>
#import <iAd/iAd.h>
#import <StoreKit/StoreKit.h>

#import "StoreObserver.h"

#include "cinder/Function.h"

@interface FirstViewController : UINavigationController <ADBannerViewDelegate, UINavigationControllerDelegate>

@property (nonatomic) BOOL isBannerVisible;
@property (strong, nonatomic) ADBannerView *bannerView;

@property (strong, nonatomic) UIButton *pullDownButton;

@property (strong, nonatomic) UIBarButtonItem *removeAdsButton;

@property (strong, nonatomic) StoreObserver *storeObserver;

- (IBAction)pullDownPushed:(UIButton *)sender;
- (IBAction)pushUpPushed:(UIButton *)sender;

- (IBAction)scalePushed:(id)sender;
- (IBAction)bellPushed:(UIBarButtonItem *)sender;
- (IBAction)presetsPushed:(UIBarButtonItem *)sender;
- (IBAction)togglePerlin:(UIBarButtonItem *)sender;
- (IBAction)toggleLock:(UIBarButtonItem *)sender;
- (void)resetPositionsPushed:(UIBarButtonItem *)sender;

- (IBAction)supportUs:(id)sender;

- (void)removeBanner;

@end
