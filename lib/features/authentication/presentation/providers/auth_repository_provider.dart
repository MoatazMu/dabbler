import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/supabase_auth_datasource.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimpleNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true; // Always true for now
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = Supabase.instance.client;
  final remoteDataSource = SupabaseAuthDataSource(client);
  final networkInfo = SimpleNetworkInfo();
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    networkInfo: networkInfo,
  );
});
