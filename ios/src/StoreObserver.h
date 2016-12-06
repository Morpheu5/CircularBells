#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface StoreObserver : NSObject <SKPaymentTransactionObserver>

- (void)completeTransaction:(SKPaymentTransaction *)transaction;
- (void)restoreTransaction:(SKPaymentTransaction *)transaction;
- (void)failedTransaction:(SKPaymentTransaction *)transaction;

@end
