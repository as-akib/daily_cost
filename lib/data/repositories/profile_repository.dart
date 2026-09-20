import '../models/user_profile.dart';
import '../services/supabase_service.dart';

class ProfileRepository {
  final SupabaseService supabaseService;

  ProfileRepository({required this.supabaseService});

  Stream<UserProfile?> streamProfile(String uid) =>
      supabaseService.streamProfile(uid);

  Future<UserProfile?> getProfile(String uid) =>
      supabaseService.getProfile(uid);

  Future<void> saveProfile(UserProfile profile, {String? email, String? displayName, String? photoUrl}) =>
      supabaseService.saveProfile(
        profile,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
      );
}
