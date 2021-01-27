#import "BraintreePaymentPlugin.h"
#import "BraintreeCore.h"
#import "BraintreeDropIn.h"
@import PassKit;
#import "BraintreeApplePay.h"
#import "BraintreePayPal.h"
#import "PayPalFlowViewController.h"
#import "BTDataCollector.h"
#import "PPDataCollector.h"
#import "BTThreeDSecureRequest.h"

NSString *clientToken;
NSString *amount;
BOOL nameRequired;
NSString *currency;
BOOL useVault;
BTAPIClient *braintreeClient;
BOOL collectDeviceData;
BOOL nameRequired;
BOOL threeDs2;
BOOL disableCard;
FlutterResult _flutterResult;


@interface BraintreePaymentPlugin () <PayPalFlowDelegate, BTDataCollectorDelegate>
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic, strong) BTDataCollector *dataCollector;
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
        currency = call.arguments[@"currency"];
        useVault = [call.arguments[@"useVault"]boolValue] == YES;
        nameRequired = [call.arguments[@"nameRequired"]boolValue] == YES;
        collectDeviceData = call.arguments[@"collectDeviceData"];
        threeDs2 = call.arguments[@"threeDs2"];
        disableCard = [call.arguments[@"disableCard"]boolValue] == YES;
        [self showDropIn:clientToken withResult:result];
    } else if ([@"startPayPalFlow" isEqualToString:call.method]) {
        _flutterResult = result;
        clientToken = call.arguments[@"clientToken"];
        amount =call.arguments[@"amount"];
        currency = call.arguments[@"currency"];
        collectDeviceData = call.arguments[@"collectDeviceData"];
        [self showPayPalFlow:clientToken];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)showPayPalFlow:(NSString *)clientTokenOrTokenizationKey {
    // Create view controller for the PayPal payment process
    // todo - figure out how to make this transparent or show a hud while loading
    PayPalFlowViewController *payPalController = [[PayPalFlowViewController alloc] init];
    payPalController.clientToken = clientToken;
    payPalController.amount = amount;
    payPalController.currency = currency;
    payPalController.delegate = self;
    
    [_viewController presentViewController: payPalController animated:YES completion:nil];
    //[self.viewController showViewController:payPalController sender:self];
    
}

- (void)showDropIn:(NSString *)clientTokenOrTokenizationKey withResult:(FlutterResult)flutterResult {
    BTDropInRequest *request = [[BTDropInRequest alloc] init];
    if(nameRequired)
        request.cardholderNameSetting = BTFormFieldRequired;
    if(!useVault) {
        BTPayPalRequest *payPalRequest = [[BTPayPalRequest alloc] initWithAmount:amount];
        payPalRequest.currencyCode = currency;
        request.payPalRequest = payPalRequest;
    }
    if(disableCard){
        request.cardDisabled = disableCard;
    }
    request.threeDSecureVerification = threeDs2;
    if(threeDs2){
        BTThreeDSecureRequest *threeDSecureRequest = [[BTThreeDSecureRequest alloc] init];
        threeDSecureRequest.amount = [NSDecimalNumber decimalNumberWithString:amount];
        threeDSecureRequest.versionRequested = BTThreeDSecureVersion2;
        request.threeDSecureRequest = threeDSecureRequest;
    }
    
    braintreeClient = [[BTAPIClient alloc] initWithAuthorization:clientToken];
    self.dataCollector = [[BTDataCollector alloc] initWithAPIClient:braintreeClient];
    self.dataCollector.delegate = self;

    BTDropInController *dropInController = [[BTDropInController alloc] initWithAuthorization:clientTokenOrTokenizationKey request:request handler:^(BTDropInController * _Nonnull controller, BTDropInResult * _Nullable result, NSError * _Nullable error) {
    
       NSMutableDictionary * map = [[NSMutableDictionary alloc] init];
    
        if (error != nil) {
            map[@"status"] = @"fail";
            map[@"message"] = @"Payment Nonce is Empty.";
            flutterResult(map);
        } else if (result.cancelled) {
            map[@"status"] = @"fail";
            map[@"message"] = @"User canceled the Payment.";
            flutterResult(map);
        }
        else if(result.paymentOptionType == BTUIKPaymentOptionTypeApplePay){
            [self setupPaymentRequest:^(PKPaymentRequest*  _Nullable paymentRequest, NSError*  _Nullable error) {
                if (error) {
                    map[@"status"] = @"fail";
                    map[@"message"] = @"ApplePay error.";
                    flutterResult(map);
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
            map[@"status"] = @"success";
            map[@"message"] = @"Payment Nonce is ready.";
            map[@"nonce"] = result.paymentMethod.nonce;
            flutterResult(map);
            [self sendResult: result.paymentMethod.nonce];
        }
        [self.viewController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [_viewController presentViewController: dropInController animated:YES completion:nil];
}

- (void)sendResult:(NSString*) nonce {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    if(collectDeviceData){
        [self.dataCollector collectFraudData:^(NSString * _Nonnull deviceData) {
            [dict setValue:nonce forKey:@"nonce"];
            [dict setValue:deviceData forKey:@"deviceData"];
            NSError * err;
            NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
            NSString * result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            _flutterResult(result);
        }];
    } else {
        [dict setValue:nonce forKey:@"nonce"];
        [dict setValue:@"" forKey:@"deviceData"];
        NSError * err;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&err];
        NSString * result = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        _flutterResult(result);
    }
    
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController* )controller didAuthorizePayment:(PKPayment* )payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    NSLog(@"*****************************something  went wrong  Nonce***********");
    NSLog(@"*****************************Started main executionße************");
    
    BTApplePayClient *applePayClient = [[BTApplePayClient alloc] initWithAPIClient:braintreeClient];
    
    [applePayClient tokenizeApplePayPayment:payment completion:^(BTApplePayCardNonce* tokenizedApplePayPayment,NSError* error) {
        
        if (tokenizedApplePayPayment) {
            // On success, send nonce to your server for processing.
            NSLog(@"*****************************Apple payment Nonce************");
            NSLog(@"nonce = %@", tokenizedApplePayPayment.nonce);
            //            _flutterResult(tokenizedApplePayPayment.nonce);
            [self sendResult: tokenizedApplePayPayment.nonce];
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

- (void)resultDataFromPayPalFlow:(NSMutableDictionary *)data {
    [self sendResult: data];
}

#pragma mark - BTDataCollectorDelegate

/// The collector has started.
- (void)dataCollectorDidStart:(__unused BTDataCollector *)dataCollector {
    NSLog(@"Data collector did start...");
}

/// The collector finished successfully.
- (void)dataCollectorDidComplete:(__unused BTDataCollector *)dataCollector {
    NSLog(@"Data collector did complete.");
}

/// An error occurred.
///
/// @param error Triggering error
- (void)dataCollector:(__unused BTDataCollector *)dataCollector didFailWithError:(NSError *)error {
    _flutterResult(@"error");
    NSLog(@"Error collecting data. error = %@", error);
}

@end
