#import "SupportUsViewController.h"
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"

@implementation SupportUsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	_requestedProduct = nil;
	_hud = nil;
	
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"RemoveAds"] != nil) {
		[self removeAdsPurchased];
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeAdsPurchased) name:@"RemoveAdsPurchased" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (IBAction)restorePurchasesPushed:(UIButton *)sender {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - Remove ads business logic

- (void)removeAdsPurchased {
	[_removeAdsButton setImage:[UIImage imageNamed:@"assets/icons/purchased.png"] forState:UIControlStateNormal];
	[_removeAdsButton setEnabled:NO];
}

- (IBAction)removeAdsPushed:(UIButton *)sender {
	_hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	_hud.mode = MBProgressHUDModeIndeterminate;
	_hud.labelText = @"Contacting Store…";
	if([SKPaymentQueue canMakePayments]) {
		_productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithArray:@[@"net.morpheu5.circularbells.removeads"]]];
		_productsRequest.delegate = self;
		[_productsRequest start];
	} else {
		[_hud hide:YES];
		[self showStoreError];
	}
}

- (void)showStoreError {
	[[[UIAlertView alloc] initWithTitle:@"Store unavailable"
								message:@"Sorry, the store is unavailable, and you can't remove ads right now. Please try again later, we are very sorry for the inconvenience."
							   delegate:self
					  cancelButtonTitle:@"OK"
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
		[[[UIAlertView alloc] initWithTitle:@"Thank you!"
									message:@"Your payment is being processed by the store, and your purchase will be delivered as soon as possible!"
								   delegate:nil
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil]
		 show];
	} else {
		_requestedProduct = nil;
	}
}

- (void)showPurchaseUnavailableError {
	[[[UIAlertView alloc] initWithTitle:@"Purchase unavailable"
								message:@"An unexpected error happened while initiating the transaction. Please try again later, we are very sorry for the inconvenience."
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil]
	 show];
}

#pragma mark - Leave comment business logic

- (IBAction)commentPushed:(UIButton *)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=1062362784"]];
}

@end
