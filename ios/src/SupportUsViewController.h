#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"

@interface SupportUsViewController : UIViewController <SKProductsRequestDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) MBProgressHUD *hud;
@property (strong, nonatomic) IBOutlet UIButton *getInTouchButton;
@property (nonatomic, strong) IBOutlet UIButton *restorePurchasesButton;
@property (strong, nonatomic) IBOutlet UIButton *commentButton;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

- (IBAction)commentPushed:(UIButton *)sender;
- (IBAction)getInTouchPushed:(UIButton *)sender;
- (IBAction)restorePurchasesPushed:(UIButton *)sender;

@property (strong, nonatomic) SKProductsRequest *productsRequest;
@property (strong, nonatomic) SKProduct *requestedProduct;

- (void)showPurchaseUnavailableError;

@end
