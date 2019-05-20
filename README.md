# Braintree Payment

 ![Braintree](https://apps.oscommerce.com/public/sites/Apps/schokoladenseite/0/0o/0oEmU-NcKOp.png) |![Deligence](https://www.deligence.com/static/media/logo.42f93d7b.png)  


Braintree Payment plugin for Flutter apps by [Deligence Technologies]("https://www.deligence.com/"). This plugin lets you integrate Braintree DropIn payment UI("https://developers.braintreepayments.com/guides/drop-in/overview/android/v3") in just 4 easy steps.

## To Enable Payment Support
`Step 1`- To enable the payment support follow below given steps:

#### Paypal
To add support for Paypal Payment add below lines inside AndroidManifest.xml. <br>
```xml
<activity android:name="com.braintreepayments.api.BraintreeBrowserSwitchActivity"
    android:launchMode="singleTask">
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="${applicationId}.braintree" />
    </intent-filter>
</activity>
```
#### Google Pay
To add support for Google Pay add below lines inside AndroidManifest.xml.
```xml
<meta-data android:name="com.google.android.gms.wallet.api.enabled" android:value="true"/>
```

`Step 2`- Import the plugin:
```dart
import 'package:braintree_payment/braintree_payment.dart';
```

`Step 3`- Create a object of BraintreePayment and send Client nonce. You can also use 

```dart
BraintreePayment braintreePayment = new BraintreePayment();
var data = await braintreePayment.showDropIn(
        nonce: clientNonce, amount: "2.0", enableGooglePay: true);
```

`Step 4`- Variable data will have the payment nonce. Send the paymne nonce to the server for further processing of the payment:
```dart
var data = await braintreePayment.showDropIn(
        nonce: clientNonce, amount: "2.0", enableGooglePay: true);
print("Response of the payment $data");
// In case of success
//{"status":"success","message":"Payment successful. Send the payment nonce to the server for the further processing.":"paymentNonce":"jdsfhedbyq772_34dfsf"}

// In case of Failure
//{"status":"fail","message":"User canceled the payment"}
```

### Screenshot
|![Deligence](https://drive.google.com/uc?authuser=0&id=1ZN0057InSjNATdlJBVt-0kmMXZ72DZLU&export=download)

### Android

To use this package you must [migrate to AndroidX](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)  
In `/app/build.gradle`, set your `minSdkVersion` to at least `21`.

For more information on the Braintree DropIn UI checkout [documentation]("https://www.braintreepayments.com/features/seamless-checkout/drop-in-ui")