import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class BraintreePayment {
  static const MethodChannel _channel =
      const MethodChannel('braintree_payment');

  Future showDropIn({String nonce, String amount, bool enableGooglePay}) async {
    if (Platform.isAndroid) {
      var result = await _channel.invokeMethod<Map>('showDropIn', {
        'clientToken': nonce,
        'amount': amount,
        'enableGooglePay': enableGooglePay
      });
      return result;
    } else {
      print("-----------------Inside IOS-------------------------");
      String result = await _channel.invokeMethod('showDropIn', {
        'clientToken': nonce,
      });
      return result;
    }
  }
}
