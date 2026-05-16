// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_braintree_suppression.dart';

const _tracerName = 'dartastic_otel_libs_braintree';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class BraintreeResult {
  const BraintreeResult({
    this.environment,
    this.merchantId,
    this.merchantAccountId,
    this.paymentMethodNonce,
    this.paymentMethodType,
    this.cardNetwork,
    this.cardLast4,
    this.cardBin,
    this.paypalEmail,
    this.venmoUsername,
    this.applePay,
    this.googlePay,
    this.threeDSecureRequired,
    this.threeDSecureStatus,
    this.transactionId,
    this.transactionStatus,
    this.transactionAmountCents,
    this.transactionCurrency,
    this.processorResponseCode,
    this.gatewayRejectionReason,
    this.errorCode,
    this.statusCode,
  });

  /// `sandbox` / `production`.
  final String? environment;

  final String? merchantId;
  final String? merchantAccountId;

  /// Tokenized payment method nonce returned from the SDK.
  final String? paymentMethodNonce;

  /// `card`, `paypal`, `venmo`, `apple_pay`, `google_pay`,
  /// `local_payment` (Sofort/iDEAL/etc), `us_bank_account`.
  final String? paymentMethodType;

  /// `visa`, `mastercard`, `amex`, `discover`, `jcb`, `unionpay`,
  /// `diners`, `maestro`.
  final String? cardNetwork;
  final String? cardLast4;
  final String? cardBin;

  final String? paypalEmail;
  final String? venmoUsername;

  final bool? applePay;
  final bool? googlePay;

  /// 3DS step required by the merchant config.
  final bool? threeDSecureRequired;

  /// `authenticate_successful`, `authenticate_failed`,
  /// `authenticate_attempt_successful`, `lookup_enrolled`,
  /// `lookup_not_enrolled`, `lookup_error`, `unsupported_card`.
  final String? threeDSecureStatus;

  final String? transactionId;

  /// `submitted_for_settlement`, `settled`, `voided`, `failed`,
  /// `gateway_rejected`, `processor_declined`, `authorized`,
  /// `authorization_expired`, `settling`, `settlement_pending`.
  final String? transactionStatus;

  final int? transactionAmountCents;

  /// ISO 4217 currency.
  final String? transactionCurrency;

  /// 4-digit processor response code (`1000` approved, `2xxx` declined,
  /// `3xxx` processor errors).
  final String? processorResponseCode;

  /// `avs`, `cvv`, `fraud`, `duplicate`, `three_d_secure`,
  /// `application_incomplete`, `risk_threshold`.
  final String? gatewayRejectionReason;

  final String? errorCode;
  final int? statusCode;
}

class BraintreeCallResult<T> {
  const BraintreeCallResult({required this.value, this.result});
  final T value;
  final BraintreeResult? result;
}

/// Wraps a Braintree call in a CLIENT span. [operation] is one of
/// `getClientToken`, `tokenize`, `startDropIn`, `requestThreeDSecure`,
/// `requestPayPalCheckout`, `requestVenmo`, `requestApplePay`,
/// `requestGooglePay`, `requestLocalPayment`, `transaction.sale`,
/// `transaction.submitForSettlement`, `transaction.refund`,
/// `transaction.void`, `customer.create`, `customer.find`,
/// `paymentMethod.create`, `paymentMethod.delete`, `subscription.create`,
/// `subscription.cancel`, `webhookNotification.parse`.
Future<T> tracedBraintree<T>({
  required String operation,
  required Future<BraintreeCallResult<T>> Function() invoke,
}) async {
  if (braintreeInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'braintree',
    'rpc.method': operation,
    'braintree.operation': operation,
  };

  final span = _tracer().startSpan(
    'braintree $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.environment != null) {
        extras.add(OTel.attributeString(
          'braintree.environment',
          res.environment!,
        ));
      }
      if (res.merchantId != null) {
        extras.add(OTel.attributeString(
          'braintree.merchant.id',
          res.merchantId!,
        ));
      }
      if (res.merchantAccountId != null) {
        extras.add(OTel.attributeString(
          'braintree.merchant_account.id',
          res.merchantAccountId!,
        ));
      }
      if (res.paymentMethodNonce != null) {
        extras.add(OTel.attributeString(
          'braintree.payment_method.nonce',
          res.paymentMethodNonce!,
        ));
      }
      if (res.paymentMethodType != null) {
        extras.add(OTel.attributeString(
          'braintree.payment_method.type',
          res.paymentMethodType!,
        ));
      }
      if (res.cardNetwork != null) {
        extras.add(OTel.attributeString(
          'braintree.card.network',
          res.cardNetwork!,
        ));
      }
      if (res.cardLast4 != null) {
        extras.add(OTel.attributeString(
          'braintree.card.last4',
          res.cardLast4!,
        ));
      }
      if (res.cardBin != null) {
        extras.add(OTel.attributeString('braintree.card.bin', res.cardBin!));
      }
      if (res.paypalEmail != null) {
        extras.add(OTel.attributeString(
          'braintree.paypal.email',
          res.paypalEmail!,
        ));
      }
      if (res.venmoUsername != null) {
        extras.add(OTel.attributeString(
          'braintree.venmo.username',
          res.venmoUsername!,
        ));
      }
      if (res.applePay != null) {
        extras.add(OTel.attributeBool('braintree.apple_pay', res.applePay!));
      }
      if (res.googlePay != null) {
        extras.add(OTel.attributeBool('braintree.google_pay', res.googlePay!));
      }
      if (res.threeDSecureRequired != null) {
        extras.add(OTel.attributeBool(
          'braintree.three_d_secure.required',
          res.threeDSecureRequired!,
        ));
      }
      if (res.threeDSecureStatus != null) {
        extras.add(OTel.attributeString(
          'braintree.three_d_secure.status',
          res.threeDSecureStatus!,
        ));
        if (res.threeDSecureStatus == 'authenticate_failed' ||
            res.threeDSecureStatus == 'lookup_error') {
          span.setStatus(
            SpanStatusCode.Error,
            'Braintree 3DS ${res.threeDSecureStatus}',
          );
        }
      }
      if (res.transactionId != null) {
        extras.add(OTel.attributeString(
          'braintree.transaction.id',
          res.transactionId!,
        ));
      }
      if (res.transactionStatus != null) {
        extras.add(OTel.attributeString(
          'braintree.transaction.status',
          res.transactionStatus!,
        ));
        if (res.transactionStatus == 'failed' ||
            res.transactionStatus == 'gateway_rejected' ||
            res.transactionStatus == 'processor_declined') {
          span.setStatus(
            SpanStatusCode.Error,
            'Braintree transaction ${res.transactionStatus}',
          );
        }
      }
      if (res.transactionAmountCents != null) {
        extras.add(OTel.attributeInt(
          'braintree.transaction.amount_cents',
          res.transactionAmountCents!,
        ));
      }
      if (res.transactionCurrency != null) {
        extras.add(OTel.attributeString(
          'braintree.transaction.currency',
          res.transactionCurrency!,
        ));
      }
      if (res.processorResponseCode != null) {
        extras.add(OTel.attributeString(
          'braintree.processor.response_code',
          res.processorResponseCode!,
        ));
      }
      if (res.gatewayRejectionReason != null) {
        extras.add(OTel.attributeString(
          'braintree.gateway.rejection_reason',
          res.gatewayRejectionReason!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'braintree.error.code',
          res.errorCode!,
        ));
        span.setStatus(
          SpanStatusCode.Error,
          'Braintree ${res.errorCode}',
        );
      }
      if (res.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Braintree HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
