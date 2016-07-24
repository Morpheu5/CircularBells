#import "SupportUsViewController.h"
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"

#include "CircularBellsApp.h"

#import "FirstViewController.h"

@implementation SupportUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	_requestedProduct = nil;
	_hud = nil;
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"RemoveAds"] != nil) {
		[self removeAdsPurchased];
	}

	_commentButton.layer.cornerRadius = 6.0;
	_commentButton.clipsToBounds = YES;

	_getInTouchButton.layer.cornerRadius = 6.0;
	_getInTouchButton.clipsToBounds = YES;

	_restorePurchasesButton.layer.cornerRadius = 6.0;
	_restorePurchasesButton.clipsToBounds = YES;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAdsPurchased) name:@"RemoveAdsPurchased" object:nil];

	_scrollView.contentSize = CGSizeMake(_contentView.bounds.size.width, _contentView.bounds.size.height - 44.0);
}

- (void)viewWillAppear:(BOOL)animated {
	ci::app::setFrameRate(1.0f);
}

- (void)viewWillDisappear:(BOOL)animated {
	ci::app::setFrameRate(60.0f);
	UIViewController *cinderViewParent = ci::app::getWindow()->getNativeViewController();
	cinderViewParent.title = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (IBAction)getInTouchPushed:(UIButton *)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.andreafranceschini.org/contact"]];
}

- (IBAction)restorePurchasesPushed:(UIButton *)sender {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - Remove ads business logic

//- (void)removeAdsPurchased {
//	[_removeAdsButton setImage:[UIImage imageNamed:@"assets/icons/purchased.png"] forState:UIControlStateNormal];
//	[_removeAdsButton setEnabled:NO];
//}
//
//- (IBAction)removeAdsPushed:(UIButton *)sender {
//	_hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//	_hud.mode = MBProgressHUDModeIndeterminate;
//	_hud.labelText = NSLocalizedString(@"Contacting Store…", nil);
//	if([SKPaymentQueue canMakePayments]) {
//		_productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:@[@"net.morpheu5.circularbells.removeads"]]];
//		_productsRequest.delegate = self;
//		[_productsRequest start];
//	} else {
//		[_hud hide:YES];
//		[self showStoreError];
//	}
//}

- (void)showStoreError {
	[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Store unavailable", nil)
								message:NSLocalizedString(@"Sorry, the store is unavailable, and you can't remove ads right now. Please try again later, we are very sorry for the inconvenience.", nil)
							   delegate:self
					  cancelButtonTitle:NSLocalizedString(@"OK", nil)
					  otherButtonTitles:nil]
	 show];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	[_hud hide:YES];
	[self showStoreError];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	[_hud hide:YES];
	for(NSString *productId in response.invalidProductIdentifiers) {
		if([productId isEqualToString:@"net.morpheu5.circularbells.removeads"]) {
			[self showPurchaseUnavailableError];
			return;
		}
	}
	
	for(SKProduct *product in response.products) {
		if([product.productIdentifier isEqualToString:@"net.morpheu5.circularbells.removeads"]) {
			_requestedProduct = product;
			
			SKMutablePayment *paymentRequest = [SKMutablePayment paymentWithProduct:_requestedProduct];
			[[SKPaymentQueue defaultQueue] addPayment:paymentRequest];
			
			return;
		}
	}
	[self showPurchaseUnavailableError];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if(buttonIndex != [alertView cancelButtonIndex]) {
		SKMutablePayment *paymentRequest = [SKMutablePayment paymentWithProduct:_requestedProduct];
		[paymentRequest setSimulatesAskToBuyInSandbox:YES];
		[[SKPaymentQueue defaultQueue] addPayment:paymentRequest];
		[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Thank you!", nil)
									message:NSLocalizedString(@"Your payment is being processed by the store, and your purchase will be delivered as soon as possible!", nil)
								   delegate:nil
						  cancelButtonTitle:NSLocalizedString(@"OK", nil)
						  otherButtonTitles:nil]
		 show];
	} else {
		_requestedProduct = nil;
	}
}

- (void)showPurchaseUnavailableError {
	[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Purchase unavailable", nil)
								message:NSLocalizedString(@"An unexpected error happened while initiating the transaction. Please try again later, we are very sorry for the inconvenience.", nil)
							   delegate:nil
					  cancelButtonTitle:NSLocalizedString(@"OK", nil)
					  otherButtonTitles:nil]
	 show];
}

#pragma mark - Leave comment business logic

- (IBAction)commentPushed:(UIButton *)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/it/app/circular-bells/id1062362784?mt=8&ls=1"]];
}

@end
