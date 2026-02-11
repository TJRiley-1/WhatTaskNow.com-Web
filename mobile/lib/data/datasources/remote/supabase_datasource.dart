import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/task.dart';
import '../../models/completed_task.dart';
import '../../models/profile.dart' as app;
import '../../models/group.dart' as app;

class SupabaseDatasource {
  static const String supabaseUrl = 'https://jntgomnsvixoroponjcx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpudGdvbW5zdml4b3JvcG9uamN4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4OTUzMDYsImV4cCI6MjA4NTQ3MTMwNn0.nP6ZmxeOZthqkisBBYXfz8OZrWssuocpLNj5ITs_KIw';

  static Future<void> init() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  User? get currentUser => auth.currentUser;
  String? get userId => currentUser?.id;

  // --- Auth ---

  Future<AuthResponse> signInWithGoogle() async {
    return await auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.whatnow.app://login-callback',
    ) as AuthResponse;
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, {String? displayName}) async {
    return await auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'full_name': displayName} : null,
    );
  }

  Future<void> signOut() async {
    await auth.signOut();
  }

  Future<void> resendConfirmation(String email) async {
    await auth.resend(type: OtpType.signup, email: email);
  }

  Future<void> resetPasswordForEmail(String email) async {
    await auth.resetPasswordForEmail(
      email,
      redirectTo: 'com.whatnow.app://reset-callback',
    );
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    return await auth.updateUser(UserAttributes(password: newPassword));
  }

  // --- Profiles ---

  Future<app.Profile?> getProfile(String userId) async {
    final data = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return app.Profile.fromSupabaseMap(data);
  }

  Future<void> upsertProfile(app.Profile profile) async {
    await client.from('profiles').upsert(profile.toSupabaseMap());
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await client
        .from('profiles')
        .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  // --- Tasks ---

  Future<List<Task>> getTasks(String userId) async {
    final data = await client
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List).map((m) => Task.fromSupabaseMap(m)).toList();
  }

  Future<void> syncTasks(String userId, List<Task> tasks) async {
    if (tasks.isEmpty) return;
    final cloudTasks = tasks.map((t) => t.toSupabaseMap(userId)).toList();
    await client.from('tasks').upsert(cloudTasks);
  }

  Future<void> deleteTaskRemote(String userId, String localId) async {
    await client.from('tasks').delete().eq('user_id', userId).eq('local_id', localId);
  }

  // --- Completed Tasks ---

  Future<void> logCompleted(String userId, CompletedTask task) async {
    await client.from('completed_tasks').insert(task.toSupabaseMap(userId));
  }

  Future<List<CompletedTask>> getCompletedTasks(String userId) async {
    final data = await client
        .from('completed_tasks')
        .select()
        .eq('user_id', userId)
        .order('completed_at', ascending: false)
        .limit(200);
    return (data as List).map((m) => CompletedTask.fromSupabaseMap(m)).toList();
  }

  // --- Groups ---

  Future<List<app.Group>> getMyGroups(String userId) async {
    final data = await client
        .from('group_members')
        .select('group_id, groups(*)')
        .eq('user_id', userId);
    return (data as List)
        .map((m) => m['groups'])
        .where((g) => g != null)
        .map((g) => app.Group.fromSupabaseMap(g))
        .toList();
  }

  Future<app.Group?> createGroup(String userId, String name, String? description) async {
    final inviteCode = _generateInviteCode();
    final data = await client.from('groups').insert({
      'name': name,
      'description': description,
      'invite_code': inviteCode,
      'created_by': userId,
    }).select().single();

    // Join as creator
    await client.from('group_members').insert({
      'group_id': data['id'],
      'user_id': userId,
    });

    return app.Group.fromSupabaseMap(data);
  }

  Future<app.Group?> joinGroup(String userId, String inviteCode) async {
    final groups = await client
        .from('groups')
        .select()
        .eq('invite_code', inviteCode.toUpperCase());

    if ((groups as List).isEmpty) return null;

    await client.from('group_members').insert({
      'group_id': groups[0]['id'],
      'user_id': userId,
    });

    return app.Group.fromSupabaseMap(groups[0]);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(String groupId) async {
    final members = await client
        .from('group_members')
        .select()
        .eq('group_id', groupId);

    if ((members as List).isEmpty) return [];

    final userIds = members.map((m) => m['user_id'] as String).toList();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final profiles = await client
        .from('profiles')
        .select()
        .inFilter('id', userIds);

    final completed = await client
        .from('completed_tasks')
        .select()
        .inFilter('user_id', userIds)
        .gte('completed_at', weekAgo);

    final profileMap = <String, Map<String, dynamic>>{};
    for (final p in profiles as List) {
      profileMap[p['id']] = p;
    }

    final statsMap = <String, Map<String, int>>{};
    for (final c in completed as List) {
      statsMap.putIfAbsent(c['user_id'], () => {'points': 0, 'tasks': 0});
      statsMap[c['user_id']]!['points'] =
          (statsMap[c['user_id']]!['points'] ?? 0) + (c['points'] as int);
      statsMap[c['user_id']]!['tasks'] =
          (statsMap[c['user_id']]!['tasks'] ?? 0) + 1;
    }

    final leaderboard = <Map<String, dynamic>>[];
    for (final uid in userIds) {
      final profile = profileMap[uid];
      if (profile == null) continue;
      final stats = statsMap[uid] ?? {'points': 0, 'tasks': 0};
      leaderboard.add({
        'user_id': uid,
        'display_name': profile['display_name'],
        'avatar_url': profile['avatar_url'],
        'current_rank': profile['current_rank'],
        'weekly_points': stats['points'] ?? 0,
        'weekly_tasks': stats['tasks'] ?? 0,
      });
    }

    leaderboard.sort((a, b) =>
        (b['weekly_points'] as int).compareTo(a['weekly_points'] as int));

    return leaderboard;
  }

  Future<void> leaveGroup(String userId, String groupId) async {
    await client
        .from('group_members')
        .delete()
        .eq('user_id', userId)
        .eq('group_id', groupId);
  }

  Future<void> updateGroup(String groupId, Map<String, dynamic> updates) async {
    await client.from('groups').update(updates).eq('id', groupId);
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final data = await client
        .from('group_members')
        .select('user_id, joined_at, profiles(id, display_name, avatar_url, current_rank)')
        .eq('group_id', groupId);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> removeMember(String groupId, String userId) async {
    await client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> getGroupActivity(String groupId, {int days = 7}) async {
    final members = await client
        .from('group_members')
        .select()
        .eq('group_id', groupId);

    if ((members as List).isEmpty) return [];

    final userIds = members.map((m) => m['user_id'] as String).toList();
    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    final completed = await client
        .from('completed_tasks')
        .select()
        .inFilter('user_id', userIds)
        .gte('completed_at', since)
        .order('completed_at', ascending: false)
        .limit(20);

    final profiles = await client
        .from('profiles')
        .select()
        .inFilter('id', userIds);

    final profileMap = <String, String>{};
    for (final p in profiles as List) {
      profileMap[p['id']] = p['display_name'] ?? 'User';
    }

    return (completed as List).map<Map<String, dynamic>>((c) => {
          ...(c as Map<String, dynamic>),
          'display_name': profileMap[c['user_id']] ?? 'User',
        }).toList();
  }

  Future<Map<String, dynamic>?> getActiveChallenge(String groupId) async {
    final data = await client
        .from('group_challenges')
        .select()
        .eq('group_id', groupId)
        .gt('end_date', DateTime.now().toIso8601String())
        .order('created_at', ascending: false)
        .limit(1);
    return (data as List).isNotEmpty ? data[0] : null;
  }

  Future<void> createChallenge(String groupId, String userId, Map<String, dynamic> challenge) async {
    final endDate = DateTime.now().add(Duration(days: challenge['duration'] as int? ?? 7));
    await client.from('group_challenges').insert({
      'group_id': groupId,
      'title': challenge['title'],
      'target_tasks': challenge['targetTasks'],
      'bonus_points': challenge['bonusPoints'],
      'start_date': DateTime.now().toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_by': userId,
    });
  }

  Future<int> getChallengeProgress(String groupId, String startDate) async {
    final members = await client
        .from('group_members')
        .select()
        .eq('group_id', groupId);

    if ((members as List).isEmpty) return 0;

    final userIds = members.map((m) => m['user_id'] as String).toList();
    final tasks = await client
        .from('completed_tasks')
        .select()
        .inFilter('user_id', userIds)
        .gte('completed_at', startDate);

    return (tasks as List).length;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final buffer = StringBuffer();
    for (var i = 0; i < 6; i++) {
      buffer.write(chars[DateTime.now().microsecond % chars.length]);
    }
    return buffer.toString();
  }
}
