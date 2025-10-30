import 'package:meta/meta.dart';

import '../../core/types/result.dart';
import '../../core/utils/json.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/payout.dart';
import '../models/wallet.dart';
import 'base_repository.dart';
import 'wallet_repository.dart';

@immutable
class WalletRepositoryImpl extends BaseRepository implements WalletRepository {
  const WalletRepositoryImpl(super.svc);

  @override
  Future<Result<Wallet?>> getWallet() {
    return guard<Wallet?>(() async {
      // RLS should scope to the caller's row; we fetch one.
      final row = await svc.client
          .from('wallets')
          .select<Map<String, dynamic>>()
          .maybeSingle();

      if (row == null) return null;
      return Wallet.fromMap(asMap(row));
    });
  }

  @override
  Future<Result<List<WalletLedgerEntry>>> getLedger({
    int limit = 50,
    int offset = 0,
  }) {
    return guard<List<WalletLedgerEntry>>(() async {
      final rows = await svc.client
          .from('wallet_ledger')
          .select<List<Map<String, dynamic>>>()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return rows.map((m) => WalletLedgerEntry.fromMap(asMap(m))).toList();
    });
  }

  @override
  Future<Result<List<Payout>>> getPayouts({int limit = 50, int offset = 0}) {
    return guard<List<Payout>>(() async {
      final rows = await svc.client
          .from('payouts')
          .select<List<Map<String, dynamic>>>()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return rows.map((m) => Payout.fromMap(asMap(m))).toList();
    });
  }
}
