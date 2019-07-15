# Braintree Payment
    
    Available for Android and IOS


<img src="https://apps.oscommerce.com/public/sites/Apps/schokoladenseite/0/0o/0oEmU-NcKOp.png" width="300" height="200"> <img src="https://media.licdn.com/dms/image/C4D0BAQH109445BY2gA/company-logo_200_200/0?e=2159024400&v=beta&t=dbU_2Y_ULhxJ1a2Q3mBmCKNbgVeqPjcL_g5CKsmy4CY" width="300" height="200">


Braintree Payment plugin for Flutter apps by [Deligence Technologies]("https://www.deligence.com/"). This plugin lets you integrate [Braintree DropIn payment UI]("https://developers.braintreepayments.com/guides/drop-in/overview") in just 4 easy steps.



### Minimum Requirements

> Android :  To use this plugin you must [`migrate to AndroidX`](`https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility`) and set your `minSdkVersion` to at least `21`.


## Steps to Enable Payment
`Step 1`- To enable the payment support follow below given steps:

### Paypal


#### Android:
To add support for Paypal Payment add below lines inside AndroidManifest.xml.
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


#### IOS:

    To add support for Paypal Payment on IOS. 

    Basic insturctions from braintree:

    1. Register URL Type
    2. Update application delegate to setReturnUrlScheme
    3. Update application delegate to pass the payment authorization URL to Braintree for finalization

    For Detailed instuction follow steps here :- https://developers.braintreepayments.com/guides/paypal/client-side/ios/v4


#### Google Pay
To add support for Google Pay add below lines inside AndroidManifest.xml.
```xml
<meta-data android:name="com.google.android.gms.wallet.api.enabled" android:value="true"/>
```

`Step 2`- Import the plugin:
```dart
import 'package:braintree_payment/braintree_payment.dart';
```

`Step 3`- Create a object of BraintreePayment and pass Client nonce.

```dart
String clientNonce = " GET YOUR CLIENT NONCE FROM THE YOUR SERVER";

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
<img src="https://drive.google.com/uc?authuser=0&id=1ZN0057InSjNATdlJBVt-0kmMXZ72DZLU&export=download" width="200">


