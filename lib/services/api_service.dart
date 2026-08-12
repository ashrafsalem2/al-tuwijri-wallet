import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

import '../models/customer.dart';
import '../models/points_entry.dart';
import '../models/reward.dart';
import '../models/sales_transaction.dart';

/// All network calls to the backend.
///
/// Users live in the separate TuwijriWallet database (register = POST,
/// login = GET). The other endpoints return ALL data; the app filters by the
/// signed-in [currentMobile] to show a member and their transactions/points.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static String baseUrl = _defaultBaseUrl();

  /// The signed-in user's Saudi mobile (05XXXXXXXX) — the filter key.
  static String? currentMobile;

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://localhost:5080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Physical-device build: reach the backend over a Cloudflare tunnel, so it
      // works on any network (bypasses the router's client isolation). HTTPS also
      // satisfies Android's cleartext-traffic restriction.
      return 'https://marina-almost-demonstration-are.trycloudflare.com';
    }
    return 'http://localhost:5080';
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'),
        headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Request failed (${res.statusCode})'));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  String _errorMessage(http.Response res, String fallback) {
    try {
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return json['message'] as String? ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  List<Map<String, dynamic>> _dataList(Map<String, dynamic> json) =>
      (json['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

  bool _isMine(Map<String, dynamic> row) => row['mobile'] == currentMobile;

  // ---------------- Auth (TuwijriWallet DB) ----------------

  /// GET /auth/login?mobile=..&password=..
  Future<void> login({required String mobile, required String password}) async {
    final uri = Uri.parse('$baseUrl/auth/login').replace(queryParameters: {
      'mobile': mobile.trim(),
      'password': password,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      int? locked;
      try {
        locked = (jsonDecode(res.body)['lockedSeconds'] as num?)?.toInt();
      } catch (_) {}
      throw ApiException(
        _errorMessage(res, 'Invalid credentials'),
        lockedSeconds: locked,
      );
    }
    currentMobile = mobile.trim();
  }

  /// POST /auth/register
  Future<void> register({
    required String name,
    required String mobile,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'mobile': mobile.trim(),
        'email': email,
        'password': password,
      }),
    );
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Registration failed'));
    }
    currentMobile = mobile.trim();
  }

  // ---------------- Data (filtered by mobile) ----------------

  /// GET /users → the signed-in member's profile (+ points balance).
  Future<Customer> getCustomer() async {
    final mobile = currentMobile ?? '';
    final users = _dataList(await _get('/users'));
    final me = users.firstWhere(
      (u) => u['mobile'] == mobile,
      orElse: () => <String, dynamic>{},
    );
    final points = await _balanceFor(mobile);
    return Customer(
      customerId: me['customerId'] as String? ?? '',
      name: me['name'] as String? ?? '',
      mobile: me['mobile'] as String? ?? mobile,
      email: me['email'] as String? ?? '',
      points: points,
      tier: '',
      memberSince: '',
    );
  }

  Future<int> _balanceFor(String mobile) async {
    final entries = _dataList(await _get('/points')).where(_isMine);
    var earned = 0, redeemed = 0;
    for (final e in entries) {
      final p = (e['points'] as num?)?.toInt() ?? 0;
      if ((e['type'] as String?)?.toLowerCase() == 'earned') {
        earned += p;
      } else {
        redeemed += p;
      }
    }
    return earned - redeemed;
  }

  /// GET /bc/members/transactions — the member's LIVE Business Central transactions.
  Future<List<SalesTransaction>> getTransactions() async {
    final json = await _get('/bc/members/transactions?mobile=${currentMobile ?? ''}');
    final list = (json['data'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return list.map((e) => SalesTransaction.fromJson(e)).toList();
  }

  /// GET /bc/members/transactions/{id} — one BC transaction with its lines.
  Future<TransactionDetail> getTransactionDetail(String id) async {
    final json = await _get('/bc/members/transactions/$id?mobile=${currentMobile ?? ''}');
    return TransactionDetail.fromJson(json['data'] as Map<String, dynamic>);
  }

  /// GET /points → the member's points summary.
  Future<PointsSummary> getPoints() async {
    final mine = _dataList(await _get('/points')).where(_isMine).toList();
    var earned = 0, redeemed = 0;
    final history = <PointsEntry>[];
    for (final e in mine) {
      final entry = PointsEntry.fromJson(e);
      history.add(entry);
      if (entry.isEarned) {
        earned += entry.points;
      } else {
        redeemed += entry.points;
      }
    }
    return PointsSummary(
      balance: earned - redeemed,
      totalEarned: earned,
      totalRedeemed: redeemed,
      history: history,
    );
  }

  /// GET /bc/members/verify?mobile=05... — checks the mobile against the live
  /// Business Central members list. Returns {isMember, name, memberNo, clubCode}.
  Future<Map<String, dynamic>> verifyMembership(String mobile) async {
    final json = await _get('/bc/members/verify?mobile=$mobile');
    return (json['data'] as Map<String, dynamic>?) ?? const {};
  }

  /// GET /rewards
  Future<List<Reward>> getRewards() async {
    final list = _dataList(await _get('/rewards'));
    return list.map((e) => Reward.fromJson(e)).toList();
  }

  /// POST /rewards/{id}/redeem?mobile=05... — returns the new balance.
  Future<int> redeemReward({
    required String rewardId,
    required int currentBalance,
    required int cost,
  }) async {
    final uri = Uri.parse('$baseUrl/rewards/$rewardId/redeem')
        .replace(queryParameters: {'mobile': currentMobile ?? ''});
    final res = await http.post(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Redeem failed'));
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>?;
    return (data?['balance'] as num?)?.toInt() ?? (currentBalance - cost);
  }

  /// PUT /users/{mobile} — update the member's name and email.
  Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/${currentMobile ?? ''}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email}),
    );
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not update profile'));
    }
  }

  /// POST /users/{mobile}/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/users/${currentMobile ?? ''}/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not change password'));
    }
  }

  /// POST /auth/forgot-password — sends an OTP. In dev the code is returned
  /// (so it can be tested without a real SMS); returns null in production.
  Future<String?> forgotPassword({required String mobile}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile.trim()}),
    );
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not send the code'));
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return json['devOtp'] as String?;
  }

  /// POST /users/{mobile}/biometric/enroll — record that this device enabled
  /// biometric login for the user. Best-effort: never blocks the login flow.
  Future<void> enrollBiometric({
    required String mobile,
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/users/${mobile.trim()}/biometric/enroll'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': deviceId, 'deviceName': deviceName}),
      );
    } catch (_) {
      // Enrollment is a convenience record; ignore transient failures.
    }
  }

  /// DELETE /users/{mobile}/biometric/{deviceId} — remove this device's record.
  Future<void> disableBiometric({
    required String mobile,
    required String deviceId,
  }) async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/users/${mobile.trim()}/biometric/$deviceId'),
      );
    } catch (_) {}
  }

  /// POST /auth/reset-password — verify the OTP and set a new password.
  Future<void> resetPassword({
    required String mobile,
    required String otp,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      throw ApiException(_errorMessage(res, 'Could not reset password'));
    }
  }
}

class ApiException implements Exception {
  final String message;
  /// Present when the server locked the account (login throttling).
  final int? lockedSeconds;
  ApiException(this.message, {this.lockedSeconds});
  @override
  String toString() => message;
}
