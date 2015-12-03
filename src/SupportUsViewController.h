#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"

@interface SupportUsViewController : UIViewController <SKProductsRequestDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) IBOutlet UIButton *removeAdsButton;
@property (retain, nonatomic) IBOutlet UILabel *removeAdsLabel;
@property (strong, nonatomic) IBOutlet UIButton *getInTouchButton;
@property (strong, nonatomic) IBOutlet UIButton *commentButton;

- (void)removeAdsPurchased;
- (IBAction)removeAdsPushed:(UIButton *)sender;
- (IBAction)commentPushed:(UIButton *)sender;
- (IBAction)getInTouchPushed:(UIButton *)sender;
- (IBAction)restorePurchasesPushed:(UIButton *)sender;

@property (strong, nonatomic) SKProductsRequest *productsRequest;
@property (strong, nonatomic) SKProduct *requestedProduct;

- (void)showPurchaseUnavailableError;

@end
