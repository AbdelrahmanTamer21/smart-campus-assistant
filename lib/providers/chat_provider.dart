import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../repositories/chat_repo.dart';
import '../repositories/course_repo.dart';
import '../repositories/announcement_repo.dart';
import '../services/ai_service.dart';
import '../services/ai_context_service.dart';

/// Manages the AI chat: streams history, builds the user's context snapshot,
/// runs the guarded scripted engine, and persists each turn.
class ChatProvider extends ChangeNotifier {
  final ChatRepo _chat;
  final CourseRepo _courses;
  final AnnouncementRepo _ann;
  final AiService _ai;

  ChatProvider(this._chat, this._courses, this._ann, {AiService ai = const AiService()})
      : _ai = ai;

  StreamSubscription? _sub;
  UserProfile? _profile;
  List<ChatMessage> _messages = const [];
  bool _typing = false;

  List<ChatMessage> get messages => _messages;
  bool get typing => _typing;

  void bind(UserProfile? profile) {
    if (profile?.authUid == _profile?.authUid) {
      _profile = profile;
      return;
    }
    _profile = profile;
    _sub?.cancel();
    final uid = profile?.authUid;
    if (uid == null) {
      _messages = const [];
      notifyListeners();
      return;
    }
    _sub = _chat.watch(uid).listen((m) {
      _messages = m;
      notifyListeners();
    });
  }

  Future<void> send(String text) async {
    final p = _profile;
    final uid = p?.authUid;
    final q = text.trim();
    if (uid == null || q.isEmpty) return;

    await _chat.add(uid, ChatMessage(from: 'user', text: q, time: DateTime.now()));
    _typing = true;
    notifyListeners();

    final ctx = await _buildContext(p!);
    final reply = _ai.reply(q, ctx);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    _typing = false;
    await _chat.add(uid, reply.toMessage());
    notifyListeners();
  }

  /// Cache-first one-shot read of the user's own data only (data-scoping).
  Future<AiContext> _buildContext(UserProfile p) async {
    try {
      final today = await _courses
          .watchDay(p.enrolledCourseIds, DateTime.now())
          .first
          .timeout(const Duration(seconds: 3));
      final deadlines = await _courses
          .watchAssignments(p.enrolledCourseIds)
          .first
          .timeout(const Duration(seconds: 3));
      final ann = await _ann.watchAnnouncements().first
          .timeout(const Duration(seconds: 3));
      return AiContext(
        profile: p,
        today: today,
        deadlines: deadlines,
        announcements: ann,
      );
    } catch (_) {
      return AiContext(profile: p, fromCache: true);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
