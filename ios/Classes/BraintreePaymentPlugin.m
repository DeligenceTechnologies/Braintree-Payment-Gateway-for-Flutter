#import "BraintreePaymentPlugin.h"
#import "BraintreeCore.h"
#import "BraintreeDropIn.h"
@import PassKit;
#import "BraintreeApplePay.h"

NSString *clientToken;
NSString *amount;
FlutterResult _flutterResult;

@interface BraintreePaymentPlugin ()
@property (nonatomic, strong) UIViewController *viewController;
@end

@implementation BraintreePaymentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"braintree_payment"
                                     binaryMessenger:[registrar messenger]];
    UIViewController *viewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    BraintreePaymentPlugin *instance = [[BraintreePaymentPlugin alloc] initWithViewController:viewController];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
    self = [super init];
    
    if (self) {
        _viewController = viewController;
    }
    
    return self;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"showDropIn" isEqualToString:call.method]) {
        _flutterResult = result;
        clientToken = call.arguments[@"clientToken"];
        amount =call.arguments[@"amount"];
        [self showDropIn:clientToken withResult:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)showDropIn:(NSString *)clientTokenOrTokenizationKey withResult:(FlutterResult)flutterResult {
    BTDropInRequest *request = [[BTDropInRequest alloc] init];
    
   BTDropInController *dropInController = [[BTDropInController alloc] initWithAuthorization:clientTokenOrTokenizationKey request:request handler:^(BTDropInController * _Nonnull controller, BTDropInResult * _Nullable result, NSError * _Nullable error) {
        
        if (error != nil) {
            flutterResult(@"error");
        } else if (result.cancelled) {
            flutterResult(@"cancelled");
        }
        else if(result.paymentOptionType == BTUIKPaymentOptionTypeApplePay){
            [self setupPaymentRequest:^(PKPaymentRequest*  _Nullable paymentRequest, NSError*  _Nullable error) {
                if (error) {
                    flutterResult(@"error");
                    return;
                }
                NSLog(@"***************************** Starting payment************");
                PKPaymentAuthorizationViewController *vc = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];
                NSLog(@"*****************************Got payment Nonce***********");
                vc.delegate = self;
                NSLog(@"*****************************something  went wrong  Nonce***********");
                [self.viewController presentViewController:vc animated:YES completion:nil];
            }];
        }
        else {
            flutterResult(result.paymentMethod.nonce);
        }
        [self.viewController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [_viewController presentViewController: dropInController animated:YES completion:nil];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController* )controller didAuthorizePayment:(PKPayment* )payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    NSLog(@"*****************************something  went wrong  Nonce***********");
    BTAPIClient *braintreeClient;
    NSLog(@"*****************************Started main executionße************");
    braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
    
    BTApplePayClient *applePayClient = [[BTApplePayClient alloc] initWithAPIClient:braintreeClient];
    
    [applePayClient tokenizeApplePayPayment:payment completion:^(BTApplePayCardNonce* tokenizedApplePayPayment,NSError* error) {
        
        if (tokenizedApplePayPayment) {
            // On success, send nonce to your server for processing.
            NSLog(@"*****************************Apple payment Nonce************");
            NSLog(@"nonce = %@", tokenizedApplePayPayment.nonce);
            _flutterResult(tokenizedApplePayPayment.nonce);
            //                                         [self postNonceToServer:tokenizedApplePayPayment.nonce];
            NSLog(@"billingPostalCode = %@", payment.billingContact.postalAddress.postalCode);
            // Then indicate success or failure via the completion callback, e.g.
            completion(PKPaymentAuthorizationStatusSuccess);
            
        } else {
            
            // Tokenization failed. Check `error` for the cause of the failure.
            
            // Indicate failure via the completion callback:
            
            completion(PKPaymentAuthorizationStatusFailure);
        }
    }];
}

- (void)setupPaymentRequest:(void (^)(PKPaymentRequest*  _Nullable, NSError*  _Nullable))completion {
    
    BTAPIClient *braintreeClient;
    
    braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
    
    BTApplePayClient *applePayClient = [[BTApplePayClient alloc]
                                        
                                        initWithAPIClient:braintreeClient];
    // You can use the following helper method to create a PKPaymentRequest which will set the `countryCode`,
    // `currencyCode`, `merchantIdentifier`, and `supportedNetworks` properties.
    // You can also create the PKPaymentRequest manually. Be aware that you'll need to keep these in
    // sync with the gateway settings if you go this route.
    [applePayClient paymentRequest:^(PKPaymentRequest*  _Nullable paymentRequest, NSError*  _Nullable error) {
        if (error) {
            completion(nil, error);
            return;
        }
        // We recommend collecting billing address information, at minimum
        // billing postal code, and passing that billing postal code with all
        // Apple Pay transactions as a best practice.
        
        paymentRequest.requiredBillingContactFields = [NSSet setWithObject:PKContactFieldPostalAddress];
        
        // Set other PKPaymentRequest properties here
        
        paymentRequest.merchantCapabilities = PKMerchantCapability3DS;
        
        paymentRequest.paymentSummaryItems =
        
        @[
          [PKPaymentSummaryItem summaryItemWithLabel:@"Collective Giving" amount:[NSDecimalNumber decimalNumberWithString:amount]],
          ];
        // Save the PKPaymentRequest or start the payment flow
        completion(paymentRequest, nil);
    }];
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end