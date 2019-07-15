import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class BraintreePayment {
  static const MethodChannel _channel =
      const MethodChannel('braintree_payment');

  Future showDropIn(
      {String nonce = "",
      String amount = "",
      bool enableGooglePay = true,
      bool inSandbox = true,
      String googleMerchantId = ""}) async {
    if (Platform.isAndroid) {
      var result;
      if (inSandbox == false && googleMerchantId.isEmpty) {
        print(
            "ERROR BRAINTREE PAYMENT : googleMerchantId is required in production evnvironment");
      } else if (nonce.isEmpty) {
        print("ERROR BRAINTREE PAYMENT : Nonce cannot be empty");
      } else if (amount.isEmpty) {
        print("ERROR BRAINTREE PAYMENT : Amount cannot be empty");
      } else if (inSandbox == false && googleMerchantId.isNotEmpty) {
        result = await _channel.invokeMethod<Map>('showDropIn', {
          'clientToken': nonce,
          'amount': amount,
          'enableGooglePay': enableGooglePay,
          'inSandbox': inSandbox,
          'googleMerchantId': googleMerchantId
        });
      } else if (inSandbox) {
        result = await _channel.invokeMethod<Map>('showDropIn', {
          'clientToken': nonce,
          'amount': amount,
          'inSandbox': inSandbox,
          'enableGooglePay': enableGooglePay,
          'googleMerchantId': googleMerchantId
        });
      }
      return result;
    } else {
      String result = await _channel
          .invokeMethod('showDropIn', {'clientToken': nonce, 'amount': amount});
      return result;
    }
  }
}
