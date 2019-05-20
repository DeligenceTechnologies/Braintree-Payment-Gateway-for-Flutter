import 'dart:async';
import 'package:flutter/services.dart';

class BraintreePayment {
  static const MethodChannel _channel =
      const MethodChannel('braintree_payment');

  Future showDropIn({String nonce, String amount, bool enableGooglePay}) async {
    var result = await _channel.invokeMethod<Map>('showDropIn', {
      'clientToken': nonce,
      'amount': amount,
      'enableGooglePay': enableGooglePay
    });
    return result;
  }
}
