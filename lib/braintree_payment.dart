import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class BraintreePayment {
  static const MethodChannel _channel =
  const MethodChannel('braintree_payment');

  Future showDropIn({String nonce = "",
    String amount = "",
    bool enableGooglePay = true,
    bool inSandbox = true,
    bool useVault = true,
    bool disableCard = false,
    String currency = "USD",
    bool nameRequired = false,
    bool collectDeviceData = false,
    bool threeDs2 = false,
    String googleMerchantId = ""}) async {
    var result;
    if (Platform.isAndroid) {
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
          'useVault': useVault,
          'disableCard': disableCard,
          'currency': currency,
          'nameRequired': nameRequired,
          'collectDeviceData': collectDeviceData,
          'threeDs2': threeDs2,
          'googleMerchantId': googleMerchantId
        });
      } else if (inSandbox) {
        result = await _channel.invokeMethod<Map>('showDropIn', {
          'clientToken': nonce,
          'amount': amount,
          'useVault': useVault,
          'disableCard': disableCard,
          'currency': currency,
          'inSandbox': inSandbox,
          'nameRequired': nameRequired,
          'enableGooglePay': enableGooglePay,
          'collectDeviceData': collectDeviceData,
          'threeDs2': threeDs2,
          'googleMerchantId': googleMerchantId
        });
      }
      return result;
    } else {
      result = await _channel.invokeMethod('showDropIn', {
        'clientToken': nonce,
        'amount': amount,
        'useVault': useVault,
        'disableCard': disableCard,
        'currency': currency,
        'threeDs2': threeDs2,
        'collectDeviceData': collectDeviceData,
        'nameRequired': nameRequired
      });
      return result;
    }
  }

  Future startPayPalFlow({String nonce, String amount, String currency}) async {
    if (Platform.isAndroid) {
      Map result = await _channel.invokeMethod<Map>('startPayPalFlow',
          {'clientToken': nonce, 'amount': amount, 'currency': currency});
      return result;
    } else {
      print("-----------------Inside IOS-------------------------");
      Map result = await _channel.invokeMethod('startPayPalFlow', {
        'clientToken': nonce,
        'amount': amount,
        'currency': currency,
      });
      return result;
    }
  }
}
