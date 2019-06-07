#import "BraintreePaymentPlugin.h"
#import "BraintreeCore.h"
#import "BraintreeDropIn.h"

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
     NSString *clientToken = call.arguments[@"clientToken"];
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
        } else {
            flutterResult(result.paymentMethod.nonce);
        }
        
        [self.viewController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [_viewController presentViewController:dropInController animated:YES completion:nil];
}

@end
