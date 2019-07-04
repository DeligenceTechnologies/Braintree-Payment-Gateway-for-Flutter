#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "BraintreeCore.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  
  //required for braintree integration
  //see https://developers.braintreepayments.com/guides/paypal/client-side/ios/v4
  [BTAppSwitch setReturnURLScheme:@"com.example.example.payments"];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

//Required for braintree integration
//See https://developers.braintreepayments.com/guides/paypal/client-side/ios/v4
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if ([url.scheme localizedCaseInsensitiveCompare:@"com.example.example.payments"] == NSOrderedSame) {
        return [BTAppSwitch handleOpenURL:url options:options];
    }
    return NO;
}

@end
