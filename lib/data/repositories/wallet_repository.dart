import '../../core/types/result.dart';
import '../models/wallet.dart';
import '../models/payout.dart';

abstract class WalletRepository {
  /// Current user’s wallet (fail if not signed in or not found).
  Future<Result<Wallet>> getMyWallet();

  /// List payouts for current user, newest first.
  Future<Result<List<Payout>>> listMyPayouts({
    int limit = 50,
    int offset = 0,
  });

  /// Server-side action to request a payout for current user’s wallet.
  Future<Result<Payout>> requestPayout({
    required int amountCents,
    required String currency,
    String? note,
  });

  /// Optional helper to trigger a server recompute and fetch the updated wallet.
  Future<Result<Wallet>> refreshWallet();
}
