#import "BraintreePaymentPlugin.h"
#import <braintree_payment/braintree_payment-Swift.h>

@implementation BraintreePaymentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftBraintreePaymentPlugin registerWithRegistrar:registrar];
}
@end
