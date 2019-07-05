//
//  PayPalFlowViewController.m
//  Braintree
//
//  Created by Michael Polt on 04.07.19.
//

#import "PayPalFlowViewController.h"
#import "BraintreePayPal.h"


@interface PayPalFlowViewController () <BTViewControllerPresentingDelegate>
@end

@implementation PayPalFlowViewController

BTAPIClient *apiClient;


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSLocalizedString(@"BTUIPayPalButton", nil);
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIView *payPalView = [[UIView alloc] initWithFrame:screenRect];
    //payPalView.superview.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
    payPalView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    self.view = payPalView;
    
    [self startPayPalFlow];
    
    
}

/*
- (UIView *)createPaymentButton {
    BTUIPayPalButton *payPalButton = [[BTUIPayPalButton alloc] init];
    [payPalButton addTarget:self action:@selector(tappedPayPalButton) forControlEvents:UIControlEventTouchUpInside];
    return payPalButton;
}
*/

- (void)startPayPalFlow {
    
    NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
    
    apiClient = [[BTAPIClient alloc] initWithAuthorization:_clientToken];
    
    [apiClient fetchOrReturnRemoteConfiguration:^(BTConfiguration * _Nullable configuration, NSError * _Nullable error) {
     if (error) {
     //self.progressBlock(@"Failed to fetch configuration");
     NSLog(@"Failed to fetch configuration: %@", error);
     return;
     }
     if (!configuration.isPayPalEnabled) {
     //self.progressBlock(@"canCreatePaymentMethodWithProviderType: returns NO, hiding PayPal button");
     } else {
     NSLog(@"Paypal is enabled ");
     //self.paymentButton.hidden = NO;
     
     }
     }];
    
    BTPayPalDriver *payPalDriver = [[BTPayPalDriver alloc] initWithAPIClient:apiClient];
    payPalDriver.viewControllerPresentingDelegate = self;
    // TODO implement appSwitchDelegate
    //payPalDriver.appSwitchDelegate = self;
    
    BTPayPalRequest *request= [[BTPayPalRequest alloc] initWithAmount:_amount];
    request.currencyCode = _currency; // Optional; see BTPayPalRequest.h for other options
    
    [payPalDriver requestOneTimePayment:request completion:^(BTPayPalAccountNonce * _Nullable tokenizedPayPalAccount, NSError * _Nullable error) {
        if (tokenizedPayPalAccount) {
            NSLog(@"Got a nonce: %@", tokenizedPayPalAccount.nonce);
            // Access additional information
            NSString *email = tokenizedPayPalAccount.email;
            NSString *firstName = tokenizedPayPalAccount.firstName;
            NSString *lastName = tokenizedPayPalAccount.lastName;
            NSString *phone = tokenizedPayPalAccount.phone;
            
            // See BTPostalAddress.h for details
            //BTPostalAddress *billingAddress = tokenizedPayPalAccount.billingAddress;
            //BTPostalAddress *shippingAddress = tokenizedPayPalAccount.shippingAddress;
            [results setValue:@"success" forKey:@"status"];
            [results setValue:@"Payment nonce is ready." forKey:@"message"];
            [results setValue:tokenizedPayPalAccount.nonce forKey:@"nonce"];
            [results setValue:email forKey:@"email"];
            [results setValue:firstName forKey:@"firstName"];
            [results setValue:lastName forKey:@"lastName"];
            [results setValue:phone forKey:@"phone"];
             
            [self returnPayPalFlowResult:results];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else if (error) {
            [results setValue:@"fail" forKey:@"status"];
            [results setValue:error.description forKey:@"message"];
            NSLog(@"Error PayPal flow: %@", error.description);
            [self returnPayPalFlowResult:results];
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            // Buyer canceled payment approval
            [results setValue:@"canceled" forKey:@"status"];
            [results setValue:@"Payment nonce is ready." forKey:@"message"];
            NSLog(@"Canceled PayPal flow");
            [self returnPayPalFlowResult:results];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    //Vault flow - currently not implemented
    /*
    [payPalDriver authorizeAccountWithCompletion:^(BTPayPalAccountNonce * _Nullable tokenizedPayPalAccount, NSError * _Nullable error) {
        if (tokenizedPayPalAccount) {
            //self.progressBlock(@"Got a nonce 💎!");
            NSLog(@"%@", [tokenizedPayPalAccount debugDescription]);
            //self.completionBlock(tokenizedPayPalAccount);
            [self dismissViewControllerAnimated:YES completion:nil];
        } else if (error) {
            NSLog(@"Error PayPal flow");
            //self.progressBlock(error.localizedDescription);
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            NSLog(@"Canceled PayPal flow");
            //self.progressBlock(@"Canceled 🔰");
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
     */
}

- (void)paymentDriver:(__unused id)driver requestsPresentationOfViewController:(UIViewController *)viewController {
    [self presentViewController:viewController animated:YES completion:nil];
}

- (void)paymentDriver:(__unused id)driver requestsDismissalOfViewController:(UIViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

//@synthesize delegate;

- (void) returnPayPalFlowResult:(NSMutableDictionary*)result {
    [_delegate resultDataFromPayPalFlow:result];
}


@end
