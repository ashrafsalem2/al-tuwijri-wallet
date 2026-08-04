import 'package:flutter/foundation.dart';
import '../models/customer.dart';

/// Reactive holder for the signed-in customer. Widgets can listen to
/// [customer] so points update live (e.g. after redeeming a reward).
class Session {
  Session._();
  static final Session instance = Session._();

  final ValueNotifier<Customer?> customer = ValueNotifier<Customer?>(null);

  void setCustomer(Customer c) => customer.value = c;

  /// Set the balance to the authoritative value returned by the server.
  void setPoints(int newPoints) {
    final c = customer.value;
    if (c == null) return;
    customer.value = c.copyWith(points: newPoints);
  }

  void clear() => customer.value = null;
}
