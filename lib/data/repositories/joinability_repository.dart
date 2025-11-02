import 'package:dabbler/core/fp/result.dart' as core;
import 'package:dabbler/core/fp/failure.dart';
import '../models/joinability_rule.dart';

typedef Result<T> = core.Result<T, Failure>;

/// Pure client-side joinability matrix.
/// Server remains the source of truth (RLS / RPC can still deny).
abstract class JoinabilityRepository {
  /// Evaluate joinability for current viewer given declarative inputs.
  /// Must be deterministic and fail-closed where security is concerned,
  /// but should avoid unnecessary blocking when information is obviously safe.
  Result<JoinabilityDecision> evaluate(JoinabilityInputs inputs);
}
