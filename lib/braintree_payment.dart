import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

class BraintreePayment {
  static const MethodChannel _channel =
      const MethodChannel('braintree_payment');

  Future showDropIn({String nonce}) async {
    var result =
        await _channel.invokeMethod<Map>('showDropIn', {'clientToken': nonce});
    return result;
  }
}
