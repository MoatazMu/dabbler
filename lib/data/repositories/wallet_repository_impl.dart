import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/failure.dart';
import '../../core/types/result.dart';
import '../../services/supabase_service.dart';
import '../models/payout.dart';
import '../models/wallet.dart';
import 'base_repository.dart';
import 'wallet_repository.dart';

class WalletRepositoryImpl extends BaseRepository implements WalletRepository {
  WalletRepositoryImpl(SupabaseService service) : super(service);

  SupabaseClient get _client => svc.client;

  void _ensureSignedIn() {
    if (_client.auth.currentUser?.id == null) {
      throw AuthFailure('Not signed in');
    }
  }

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<Result<Wallet>> getMyWallet() {
    return guard(() async {
      _ensureSignedIn();

      final dynamic row = await _client
          .from('wallets')
          .select()
          .eq('user_id', _uid)
          .maybeSingle();

      if (row == null) {
        throw NotFoundFailure('Wallet not found');
      }

      return Wallet.fromJson(Map<String, dynamic>.from(row as Map));
    });
  }

  @override
  Future<Result<List<Payout>>> listMyPayouts({
    int limit = 50,
    int offset = 0,
  }) {
    return guard(() async {
      _ensureSignedIn();

      final dynamic rows = await _client
          .from('payouts')
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final list = (rows as List)
          .map((entry) => Payout.fromJson(Map<String, dynamic>.from(entry as Map)))
          .toList();

      return list;
    });
  }

  @override
  Future<Result<Payout>> requestPayout({
    required int amountCents,
    required String currency,
    String? note,
  }) {
    return guard(() async {
      _ensureSignedIn();

      final response = await _client.rpc(
        'request_payout',
        params: {
          'amount_cents': amountCents,
          'currency': currency,
          if (note != null) 'note': note,
        },
      );

      if (response == null) {
        throw UnknownFailure('Empty response from request_payout');
      }

      return Payout.fromJson(Map<String, dynamic>.from(response as Map));
    });
  }

  @override
  Future<Result<Wallet>> refreshWallet() {
    return guard(() async {
      _ensureSignedIn();

      final response = await _client.rpc('wallet_refresh');
      if (response != null) {
        return Wallet.fromJson(Map<String, dynamic>.from(response as Map));
      }

      final dynamic row = await _client
          .from('wallets')
          .select()
          .eq('user_id', _uid)
          .maybeSingle();

      if (row == null) {
        throw NotFoundFailure('Wallet not found');
      }

      return Wallet.fromJson(Map<String, dynamic>.from(row as Map));
    });
  }
}
