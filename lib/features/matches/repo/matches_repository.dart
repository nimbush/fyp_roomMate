import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roommate_finder/common/utils/base_repository/base_repository.dart';
import 'package:roommate_finder/common/utils/base_repository/request_input.dart';
import 'package:roommate_finder/controller/base_repo_provider.dart';
import 'package:roommate_finder/features/matches/model/match_model.dart';

final matchesRepoProvider = Provider<MatchesRepository>(
  (ref) => MatchesRepository(ref.watch(tokenBaseRepoProvider)),
);

/// Match endpoints: the accepted/pending lists plus accept/reject actions.
class MatchesRepository {
  MatchesRepository(this._repo);

  final BaseRepository _repo;

  static List<MatchModel> _parseList(dynamic json) => (json as List<dynamic>)
      .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<List<MatchModel>> getAllMatches(int userId) =>
      _repo.get(RequestInput<List<MatchModel>>(
        path: '/api/matches/user/$userId',
        parse: _parseList,
      ));

  Future<List<MatchModel>> getAcceptedMatches(int userId) =>
      _repo.get(RequestInput<List<MatchModel>>(
        path: '/api/matches/user/$userId/accepted',
        parse: _parseList,
      ));

  Future<List<MatchModel>> getPendingMatches(int userId) =>
      _repo.get(RequestInput<List<MatchModel>>(
        path: '/api/matches/user/$userId/pending',
        parse: _parseList,
      ));

  Future<MatchModel> acceptMatch(int matchId) =>
      _repo.put(RequestInput<MatchModel>(
        path: '/api/matches/accept/$matchId',
        parse: (json) => MatchModel.fromJson(json as Map<String, dynamic>),
      ));

  Future<MatchModel> rejectMatch(int matchId) =>
      _repo.put(RequestInput<MatchModel>(
        path: '/api/matches/reject/$matchId',
        parse: (json) => MatchModel.fromJson(json as Map<String, dynamic>),
      ));
}
