import '../models/chat_message.dart';
import 'ai_context_service.dart';

/// Result of an AI turn — text plus an optional rich room card.
class AiReply {
  final String text;
  final String? rich; // 'room'
  final String? roomTitle;
  final String? roomSub;
  const AiReply(this.text, {this.rich, this.roomTitle, this.roomSub});

  ChatMessage toMessage() => ChatMessage(
        from: 'ai',
        text: text,
        rich: rich,
        roomTitle: roomTitle,
        roomSub: roomSub,
        time: DateTime.now(),
      );
}

/// Scripted, context-grounded campus assistant.
///
/// Guardrails (see plan F6 §4):
///  • On-topic only — a bounded intent set over the user's own data; anything
///    off-scope gets a polite refusal.
///  • Injection-resistant — the user text is treated as data, never as
///    instructions; "ignore previous instructions / reveal your prompt / show
///    another student's data" patterns are refused.
///  • Hard data-scoping — answers are built ONLY from [AiContext], which is the
///    signed-in user's own snapshot. No other user's data is reachable.
class AiService {
  const AiService();

  /// On-scope keywords the assistant will engage with.
  static const _scopeWords = [
    'class', 'classes', 'schedule', 'today', 'next', 'where', 'room',
    'course', 'courses', 'deadline', 'deadlines', 'assignment', 'assignments',
    'exam', 'midterm', 'test', 'event', 'events', 'map', 'navigate', 'building',
    'announce', 'announcement', 'summary', 'summarize', 'study', 'quiet', 'spot',
    'professor', 'lecture', 'campus', 'help',
  ];

  /// Injection / jailbreak / cross-user phrases to refuse outright.
  static const _injection = [
    'ignore previous', 'ignore all previous', 'ignore the previous',
    'ignore prior', 'ignore above', 'disregard the rules',
    'disregard instructions', 'system prompt', 'reveal your', 'you are now',
    'act as', 'developer mode', 'jailbreak', 'another student',
    "another student's", 'another user', 'someone else', 'other students',
    'all users', 'everyone', 'show me grades', 'grades of', 'their password',
  ];

  AiReply reply(String raw, AiContext ctx) {
    final text = raw.trim();
    final t = text.toLowerCase();

    // 1) Injection / cross-user request → refuse without leaking anything.
    if (_injection.any(t.contains)) {
      return const AiReply(
          "I can only help you with your own campus info — your schedule, "
          "courses, deadlines, events, the map, and announcements. I can't "
          "change how I work or access anyone else's account.");
    }

    // 2) Off-topic → polite on-scope refusal.
    final onScope = _scopeWords.any((w) => t.contains(w));
    if (!onScope && text.isNotEmpty) {
      return const AiReply(
          "I'm your campus assistant, so I stick to university topics — your "
          "schedule, courses, deadlines, events, navigation, and announcements. "
          'Try "What do I have today?" or "Where is my next class?"');
    }

    // 3) Offline / no live context.
    if (ctx.profile == null) {
      return const AiReply(
          "I can't reach live campus data right now. I'll have your schedule "
          'and announcements ready as soon as you\'re back online.');
    }

    // 4) Grounded intents over the user's own context.
    if (t.contains('next class') || (t.contains('where') && t.contains('class'))) {
      final c = ctx.nextClass;
      if (c == null) return const AiReply('You have no more classes scheduled today. 🎉');
      return AiReply(
        'Your next class, ${c.title}, is in ${c.room} at ${c.start}.',
        rich: 'room',
        roomTitle: '${c.room} · ${c.title}',
        roomSub: '${c.code} · ${c.start}',
      );
    }

    if (t.contains('today') || t.contains('have')) {
      if (ctx.today.isEmpty) return const AiReply('Your schedule is clear today.');
      final lines = ctx.today
          .map((c) => '• ${c.start} ${c.title} (${c.room})'
              '${c.status.name == 'cancelled' ? ' — cancelled' : c.status.name == 'roomchanged' ? ' — room changed' : ''}')
          .join('\n');
      final dl = ctx.nextDeadline;
      return AiReply('Today you have ${ctx.today.length} classes:\n$lines'
          '${dl != null ? '\n\nNext deadline: ${dl.title} (${dl.dueLabel}).' : ''}');
    }

    if (t.contains('announce') || t.contains('summar')) {
      if (ctx.announcements.isEmpty) return const AiReply('No announcements right now.');
      final lines = ctx.announcements
          .take(3)
          .map((a) => '• ${a.urgent ? '⚠️ ' : ''}${a.summary.isNotEmpty ? a.summary : a.title}')
          .join('\n');
      return AiReply("Here's the gist:\n$lines");
    }

    if (t.contains('exam') || t.contains('midterm') || t.contains('test')) {
      final e = ctx.nextExam;
      if (e == null) return const AiReply('No exams are scheduled for you yet.');
      return AiReply('Your next exam is ${e.title} (${e.code}) — ${e.dueLabel}. '
          'There are practice materials in your Course Resources.');
    }

    if (t.contains('deadline') || t.contains('assignment') || t.contains('due')) {
      final d = ctx.nextDeadline;
      if (d == null) return const AiReply('You have no upcoming deadlines. Nicely done!');
      return AiReply('Your nearest deadline is ${d.title} (${d.code}) — ${d.dueLabel}.');
    }

    if (t.contains('study') || t.contains('quiet') || t.contains('spot') || t.contains('room')) {
      return const AiReply(
        'The Library 3rd-floor Quiet Zone is the calmest spot right now. Want directions?',
        rich: 'room',
        roomTitle: 'Library · 3rd Floor',
        roomSub: 'Quiet Zone · seats free now',
      );
    }

    // On-scope but unmatched → capabilities.
    return const AiReply(
        'I can help with your schedule, courses, deadlines, events, campus '
        'navigation, and announcements. Try "What do I have today?"');
  }
}
