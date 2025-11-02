import 'package:fpdart/fpdart.dart';

import 'package:dabbler/core/fp/failure.dart';

typedef Result<T> = Either<Failure, T>;

abstract class ModerationRepository {
  /// Quick admin check via RPC. Cache at call-site if you like; repo stays stateless.
  Future<Result<bool>> isAdmin();

  // ----- Flags (read-only, admin) -----
  Future<Result<List<Map<String, dynamic>>>> listFlags({
    int limit = 50,
    int offset = 0,
    Map<String, dynamic>? where, // optional simple filters
  });

  // ----- Tickets (admin) -----
  Future<Result<List<Map<String, dynamic>>>> listTickets({
    int limit = 50,
    int offset = 0,
    Map<String, dynamic>? where,
  });

  /// Insert a ticket row. Caller provides the map with correct columns.
  Future<Result<Map<String, dynamic>>> createTicket(Map<String, dynamic> values);

  /// Patch a ticket by id (string or uuid in text form).
  Future<Result<Map<String, dynamic>>> updateTicket(
    String id,
    Map<String, dynamic> patch,
  );

  /// Optional convenience to close/resolve tickets if the schema has a status field.
  Future<Result<int>> setTicketStatus(String id, String status);

  // ----- Actions (admin) -----
  Future<Result<List<Map<String, dynamic>>>> listActions({
    int limit = 50,
    int offset = 0,
    Map<String, dynamic>? where,
  });

  Future<Result<Map<String, dynamic>>> recordAction(Map<String, dynamic> values);

  // ----- Ban terms (admin) -----
  Future<Result<List<Map<String, dynamic>>>> listBanTerms({
    int limit = 100,
    int offset = 0,
    Map<String, dynamic>? where,
  });

  /// Upsert by unique constraint (caller supplies keys present in DB).
  Future<Result<Map<String, dynamic>>> upsertBanTerm(Map<String, dynamic> values);

  Future<Result<int>> deleteBanTerm(String id);
}
