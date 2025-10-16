import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/friend_model.dart';
import '../repositories/friends_repository.dart';

/// Lightweight parameters for fetching friend suggestions.
class GetFriendSuggestionsParams {
  final int? limit;
  final int? offset;
  const GetFriendSuggestionsParams({this.limit, this.offset});
}

/// Use case: delegate to FriendsRepository to fetch friend suggestions.
class GetFriendSuggestionsUseCase {
  final FriendsRepository _friendsRepository;
  const GetFriendSuggestionsUseCase(this._friendsRepository);

  Future<Either<Failure, List<FriendModel>>> call(
    GetFriendSuggestionsParams params,
  ) async {
    return _friendsRepository.getFriendSuggestions(
      limit: params.limit,
      offset: params.offset,
    );
  }
}
