package com.deligence.braintree_payment;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;

import com.braintreepayments.api.BraintreeFragment;
import com.braintreepayments.api.dropin.DropInActivity;
import com.braintreepayments.api.dropin.DropInRequest;
import com.braintreepayments.api.dropin.DropInResult;
import com.braintreepayments.api.models.GooglePaymentRequest;
import com.braintreepayments.api.models.ThreeDSecureRequest;
import com.braintreepayments.cardform.view.CardForm;

import com.google.android.gms.wallet.TransactionInfo;
import com.google.android.gms.wallet.WalletConstants;

import java.util.HashMap;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class BraintreePaymentPlugin implements MethodCallHandler, ActivityResultListener {
    private Activity activity;
    private Context context;
    Result activeResult;
    private static final int REQUEST_CODE = 0x1337;
    private static final int PAYPAL_REQUEST_CODE = 0x1338;
    String clientToken = "";
    String amount = "";
    String googleMerchantId = "";
    boolean inSandbox;
    boolean enableGooglePay;
    boolean threeDs2;
    boolean collectDeviceData;
    HashMap<String, String> map = new HashMap<String, String>();
    String payPalFlow = ""; //either "Vault" or "Checkout"
    BraintreeFragment mBraintreeFragment;


    public BraintreePaymentPlugin(Registrar registrar) {
        activity = registrar.activity();
        context = registrar.context();
        registrar.addActivityResultListener(this);
    }

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "braintree_payment");
        channel.setMethodCallHandler(new BraintreePaymentPlugin(registrar));
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("showDropIn")) {
            this.activeResult = result;
            this.clientToken = call.argument("clientToken");
            this.amount = call.argument("amount");
            this.inSandbox = call.argument("inSandbox");
            this.googleMerchantId = call.argument("googleMerchantId");
            this.enableGooglePay = call.argument("enableGooglePay");
            this.threeDs2 = call.argument("threeDs2");
            this.collectDeviceData = call.argument("collectDeviceData");
            payNow();
        } else if (call.method.equals("startPayPalFlow")) {
            this.activeResult = result;
            this.clientToken = call.argument("clientToken");
            this.amount = call.argument("amount");
            this.payPalFlow = call.argument("payPalFlow");
            startPayPalFlow();
        } else {
            result.notImplemented();
        }
    }

    void payNow() {
        DropInRequest dropInRequest = new DropInRequest().clientToken(clientToken);
        if (enableGooglePay) {
            enableGooglePay(dropInRequest);
        }
        if(collectDeviceData){
            dropInRequest.collectDeviceData(true);
        }
        if(threeDs2){
            ThreeDSecureRequest threeDSecureRequest = new ThreeDSecureRequest()
                    .amount(amount)
                    .versionRequested(ThreeDSecureRequest.VERSION_2);
            dropInRequest.threeDSecureRequest(threeDSecureRequest);
            dropInRequest.requestThreeDSecureVerification(true);
        }
        activity.startActivityForResult(dropInRequest.getIntent(context), REQUEST_CODE);
    }

    void startPayPalFlow() {
        Intent p = new Intent(this.context, PayPalFlowActivity.class);
        p.putExtra("clientToken", clientToken);
        p.putExtra("amount", amount);
    }

    private void enableGooglePay(DropInRequest dropInRequest) {
        if (inSandbox) {
            GooglePaymentRequest googlePaymentRequest = new GooglePaymentRequest()
                    .transactionInfo(TransactionInfo.newBuilder()
                            .setTotalPrice(amount)
                            .setTotalPriceStatus(WalletConstants.TOTAL_PRICE_STATUS_FINAL)
                            .setCurrencyCode("USD")
                            .build())
                    .billingAddressRequired(true);
            dropInRequest.googlePaymentRequest(googlePaymentRequest);
        } else {
            GooglePaymentRequest googlePaymentRequest = new GooglePaymentRequest()
                    .transactionInfo(TransactionInfo.newBuilder()
                            .setTotalPrice(amount)
                            .setTotalPriceStatus(WalletConstants.TOTAL_PRICE_STATUS_FINAL)
                            .setCurrencyCode("USD")
                            .build())
                    .billingAddressRequired(true)
                    .googleMerchantId(googleMerchantId);
            dropInRequest.googlePaymentRequest(googlePaymentRequest);
        }
    }

    @Override
//     public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    public boolean onActivityResult(int requestCode, int resultCode, Intent data)  {
      if(activeResult == null) return false;
        switch (requestCode) {
            case REQUEST_CODE:
                if (resultCode == Activity.RESULT_OK) {
                    DropInResult result = data.getParcelableExtra(DropInResult.EXTRA_DROP_IN_RESULT);
                    String deviceData = result.getDeviceData();
                    String paymentNonce = result.getPaymentMethodNonce().getNonce();
                    if (paymentNonce == null && paymentNonce.isEmpty()) {
                        map.put("status", "fail");
                        map.put("message", "Payment Nonce is Empty.");
                        activeResult.success(map);
                    } else {
                        map.put("status", "success");
                        map.put("message", "Payment Nonce is ready.");
                        map.put("nonce", paymentNonce);
                        map.put("deviceData", deviceData);
                        activeResult.success(map);
                    }
                } else if (resultCode == Activity.RESULT_CANCELED) {
                    map.put("status", "fail");
                    map.put("message", "User canceled the Payment");
                    activeResult.success(map);
                } else {
                    Exception error = (Exception) data.getSerializableExtra(DropInActivity.EXTRA_ERROR);
                    map.put("status", "fail");
                    map.put("message", error.getMessage());
                    activeResult.success(map);
                }
                return true;
            case PAYPAL_REQUEST_CODE:
                if (resultCode == PayPalFlowActivity.RESULT_OK) {
                    String paymentNonce = data.getExtras().getString("nonce");
                    map.put("status", "success");
                    map.put("message", "Payment Nonce is ready.");
                    map.put("nonce", paymentNonce);
                    activeResult.success(map);
                } else if (resultCode == PayPalFlowActivity.RESULT_CANCELED) {
                    map.put("status", "canceled");
                    map.put("message", "Paypal Flow was canceled by user.");
                    activeResult.success(map);
                } else if (resultCode == PayPalFlowActivity.RESULT_ERROR) {
                    String errorMessage = data.getExtras().getString("ErrorMessage");
                    map.put("status", "fail");
                    map.put("message", errorMessage);
                    activeResult.success(map);
                }
                return true;
            default:
                return false;
        }
    }
}
