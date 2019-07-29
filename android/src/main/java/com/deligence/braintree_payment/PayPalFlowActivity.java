package com.deligence.braintree_payment;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;

import com.braintreepayments.api.BraintreeFragment;
import com.braintreepayments.api.PayPal;
import com.braintreepayments.api.exceptions.BraintreeError;
import com.braintreepayments.api.exceptions.ErrorWithResponse;
import com.braintreepayments.api.exceptions.InvalidArgumentException;
import com.braintreepayments.api.interfaces.BraintreeCancelListener;
import com.braintreepayments.api.interfaces.BraintreeErrorListener;
import com.braintreepayments.api.interfaces.PaymentMethodNonceCreatedListener;
import com.braintreepayments.api.models.PayPalAccountNonce;
import com.braintreepayments.api.models.PayPalRequest;
import com.braintreepayments.api.models.PaymentMethodNonce;

public class PayPalFlowActivity extends AppCompatActivity implements PaymentMethodNonceCreatedListener,
        BraintreeErrorListener, BraintreeCancelListener {

    public static final int RESULT_ERROR = -2;

    private BraintreeFragment mBraintreeFragment;
    private String clientToken;
    private String amount;
    private String currency;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        Log.d(this.getLocalClassName(), "onCreateStart: Paypal activity onCreate Start");
        super.onCreate(savedInstanceState);
        clientToken = getIntent().getExtras().getString("clientToken");
        amount = getIntent().getExtras().getString("amount");
        currency = getIntent().getExtras().getString("currency");

        try {
            mBraintreeFragment = BraintreeFragment.newInstance(this, clientToken);
            Log.d(this.getLocalClassName(), "onCreate: Init Braintree Fragment done" );
        } catch (InvalidArgumentException e) {
            // There was an issue with your authorization string.
        }

        PayPalRequest request = new PayPalRequest(amount)
                .currencyCode(currency)
                .intent(PayPalRequest.INTENT_AUTHORIZE);

        PayPal.requestOneTimePayment(mBraintreeFragment, request);
        setContentView(R.layout.activity_pay_pal_flow);
        Log.d(this.getLocalClassName(), "onCreate: finished" );
    }

    @Override
    public void onPaymentMethodNonceCreated(PaymentMethodNonce paymentMethodNonce) {
        // Send nonce to server
        String nonce = paymentMethodNonce.getNonce();
        Log.d(this.getLocalClassName(), "onPaymentMethodNonceCreated: " + nonce);
        Intent data = new Intent();
        data.putExtra("nonce", nonce);
        if (paymentMethodNonce instanceof PayPalAccountNonce) {
            PayPalAccountNonce payPalAccountNonce = (PayPalAccountNonce)paymentMethodNonce;

            // Access additional information
            String email = payPalAccountNonce.getEmail();
            String firstName = payPalAccountNonce.getFirstName();
            String lastName = payPalAccountNonce.getLastName();
            String phone = payPalAccountNonce.getPhone();

            data.putExtra("email", email);
            data.putExtra("firstName", firstName);
            data.putExtra("lastName", lastName);
            data.putExtra("phone", phone);

            // See PostalAddress.java for details
            //PostalAddress billingAddress = payPalAccountNonce.getBillingAddress();
            //PostalAddress shippingAddress = payPalAccountNonce.getShippingAddress();
            Log.d(this.getLocalClassName(), "onPaymentNonceCreated: Paypal payment process created a nonce");
        }
        setResult(RESULT_OK, data);
        finish();
    }

    @Override
    public void onCancel(int requestCode) {
        // Use this to handle a canceled activity, if the given requestCode is important.
        // You may want to use this callback to hide loading indicators, and prepare your UI for input
        Log.d(this.getLocalClassName(), "onCancel: Paypal payment process was canceled");
        setResult(RESULT_CANCELED);
        finish();
    }

    @Override
    public void onError(Exception error) {
        String errorMessage = "Unknown error";

        if (error instanceof ErrorWithResponse) {
            ErrorWithResponse errorWithResponse = (ErrorWithResponse) error;
            BraintreeError cardErrors = errorWithResponse.errorFor("creditCard");
            if (cardErrors != null) {
                errorMessage = cardErrors.getMessage();
                // There is an issue with the credit card.
                BraintreeError expirationMonthError = cardErrors.errorFor("expirationMonth");
                if (expirationMonthError != null) {
                    // There is an issue with the expiration month.
                    Log.d(this.getLocalClassName(), "onError: expiration Month error");
                    errorMessage = expirationMonthError.getMessage();
                }
            }
        }
        Intent data = new Intent();
        data.putExtra("errorMessage", errorMessage);
        setResult(RESULT_OK, data);
        finish();
    }
}
