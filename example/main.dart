// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_braintree/otel_braintree.dart';

/// Traces Braintree calls with OpenTelemetry.
///
/// `otel_braintree` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Braintree call in
/// [tracedBraintree]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'braintree-example');

  // Wraps a Braintree call in a CLIENT span.
  final braintreeId = await tracedBraintree<String>(
    operation: 'customer.create',
    invoke: () async {
      // Make the Braintree call here, then report what it returned.
      const id = 'braintree_8f3a2c';
      return const BraintreeCallResult(
          value: id,
          result: BraintreeResult(
              environment: 'sandbox',
              merchantId: 'merchant_8f3a2c',
              merchantAccountId: 'merchantaccount_8f3a2c',
              paymentMethodNonce: 'card',
              paymentMethodType: 'card',
              cardNetwork: 'visa',
              cardLast4: 'example',
              cardBin: 'example',
              paypalEmail: 'ada@example.com',
              venmoUsername: 'example',
              applePay: true,
              googlePay: true,
              threeDSecureRequired: true,
              threeDSecureStatus: 'authenticate_successful',
              transactionId: 'transaction_8f3a2c',
              transactionStatus: 'submitted_for_settlement',
              transactionAmountCents: 1999,
              transactionCurrency: 'usd',
              processorResponseCode: '1000',
              gatewayRejectionReason: 'avs',
              errorCode: 'example',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedBraintree customer.create returned $braintreeId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutBraintreeInstrumentationAsync.
  await runWithoutBraintreeInstrumentationAsync(
    () => tracedBraintree<String>(
      operation: 'customer.create',
      invoke: () async {
        const id = 'braintree_8f3a2c';
        return const BraintreeCallResult(
            value: id,
            result: BraintreeResult(
                environment: 'sandbox',
                merchantId: 'merchant_8f3a2c',
                merchantAccountId: 'merchantaccount_8f3a2c',
                paymentMethodNonce: 'card',
                paymentMethodType: 'card',
                cardNetwork: 'visa',
                cardLast4: 'example',
                cardBin: 'example',
                paypalEmail: 'ada@example.com',
                venmoUsername: 'example',
                applePay: true,
                googlePay: true,
                threeDSecureRequired: true,
                threeDSecureStatus: 'authenticate_successful',
                transactionId: 'transaction_8f3a2c',
                transactionStatus: 'submitted_for_settlement',
                transactionAmountCents: 1999,
                transactionCurrency: 'usd',
                processorResponseCode: '1000',
                gatewayRejectionReason: 'avs',
                errorCode: 'example',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
