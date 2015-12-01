#import "StoreObserver.h"

@implementation StoreObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
				// Call the appropriate custom method for the transaction state.
			case SKPaymentTransactionStatePurchasing:
//				[self showTransactionAsInProgress:transaction deferred:NO];
				break;
			case SKPaymentTransactionStateDeferred:
//				[self showTransactionAsInProgress:transaction deferred:YES];
				break;
			case SKPaymentTransactionStateFailed:
				[self failedTransaction:transaction];
				break;
			case SKPaymentTransactionStatePurchased:
				[self completeTransaction:transaction];
				break;
			case SKPaymentTransactionStateRestored:
				[self restoreTransaction:transaction];
				break;
			default:
				// For debugging
				NSLog(@"Unexpected transaction state %@", @(transaction.transactionState));
				break;
		}
	}
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
	if([transaction.payment.productIdentifier isEqualToString:@"net.morpheu5.circularbells.removeads"]) {
		[[NSUserDefaults standardUserDefaults] setObject:transaction.transactionReceipt forKey:@"RemoveAds"];
		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveAdsPurchased" object:self];
	}
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
	if([transaction.payment.productIdentifier isEqualToString:@"net.morpheu5.circularbells.removeads"]) {
		[[NSUserDefaults standardUserDefaults] setObject:transaction.transactionReceipt forKey:@"RemoveAds"];
		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveAdsPurchased" object:self];
	}
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
	[[[UIAlertView alloc] initWithTitle:@"Purchase failed"
								message:[NSString stringWithFormat:@"The purchase could not be completed (error: %@). Please try again later, we are very sorry for the inconvenience.", transaction.error.localizedDescription]
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil]
	 show];
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

@end