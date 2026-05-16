// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_braintree/otel_braintree.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_braintree-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('transaction.sale records card + 3DS + amount', () async {
    await tracedBraintree<String>(
      operation: 'transaction.sale',
      invoke: () async => const BraintreeCallResult(
        value: 'ok',
        result: BraintreeResult(
          environment: 'production',
          merchantId: 'mid_1',
          paymentMethodType: 'card',
          cardNetwork: 'visa',
          cardLast4: '4242',
          threeDSecureRequired: true,
          threeDSecureStatus: 'authenticate_successful',
          transactionId: 'tx_1',
          transactionStatus: 'submitted_for_settlement',
          transactionAmountCents: 9999,
          transactionCurrency: 'USD',
          processorResponseCode: '1000',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('braintree transaction.sale')!);
    expect(a['braintree.card.network'], 'visa');
    expect(a['braintree.three_d_secure.status'], 'authenticate_successful');
    expect(a['braintree.transaction.amount_cents'], 9999);
  });

  test('processor_declined sets span error', () async {
    await tracedBraintree<String>(
      operation: 'transaction.sale',
      invoke: () async => const BraintreeCallResult(
        value: 'ok',
        result: BraintreeResult(
          transactionStatus: 'processor_declined',
          processorResponseCode: '2001',
        ),
      ),
    );
    expect(
      spans.findSpanByName('braintree transaction.sale')!.status,
      SpanStatusCode.Error,
    );
  });

  test('gateway_rejected (fraud) sets span error', () async {
    await tracedBraintree<String>(
      operation: 'transaction.sale',
      invoke: () async => const BraintreeCallResult(
        value: 'ok',
        result: BraintreeResult(
          transactionStatus: 'gateway_rejected',
          gatewayRejectionReason: 'fraud',
        ),
      ),
    );
    final s = spans.findSpanByName('braintree transaction.sale')!;
    expect(s.status, SpanStatusCode.Error);
    expect(attrsOf(s)['braintree.gateway.rejection_reason'], 'fraud');
  });

  test('suppression skips spans', () async {
    await runWithoutBraintreeInstrumentationAsync(() async {
      await tracedBraintree<String>(
        operation: 'getClientToken',
        invoke: () async => const BraintreeCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('braintree '), isEmpty);
  });
}
