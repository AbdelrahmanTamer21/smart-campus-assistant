import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../routing/routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/widgets.dart';

const _suggestions = [
  'What do I have today?',
  'Summarize announcements',
  'Find a study room',
  'When is my next exam?',
];

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final q = (text ?? _input.text).trim();
    if (q.isEmpty) return;
    _input.clear();
    context.read<ChatProvider>().send(q);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SCAppBar(
              leading: const IconCircle(
                  icon: Icons.auto_awesome,
                  tint: AppColors.primaryNavy,
                  color: AppColors.inversePrimary,
                  size: 42),
              title: 'Campus AI',
              subtitle: 'Always here to help',
              trailing: CircleIconButton(
                  icon: Icons.refresh, onTap: () {}),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screen, 4, AppSpacing.screen, 8),
                children: [
                  Text('How can I help\nyou today?',
                      style: AppText.headlineLg.copyWith(fontSize: 26)),
                  const SizedBox(height: 18),
                  if (chat.messages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Ask me about your schedule, courses, deadlines, events, '
                        'the campus map, or announcements.',
                        style: AppText.bodyMd.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  for (final m in chat.messages) _bubble(m),
                  if (chat.typing) _typing(),
                ],
              ),
            ),
            _InputDock(
              controller: _input,
              onSend: _send,
              onSuggestion: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage m) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ChatBubble(
          isAI: m.isAI,
          text: m.text,
          time: m.timeLabel.isEmpty ? null : m.timeLabel,
          rich: m.rich == 'room'
              ? _RoomCard(
                  title: m.roomTitle ?? 'Room',
                  sub: m.roomSub ?? '',
                  onGo: () => context.go(Routes.map),
                )
              : null,
        ),
      );

  Widget _typing() => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ChatBubble(
          isAI: true,
          rich: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.4),
                      shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ),
      );
}

class _RoomCard extends StatelessWidget {
  final String title;
  final String sub;
  final VoidCallback onGo;
  const _RoomCard({required this.title, required this.sub, required this.onGo});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadow.l1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 96,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryNavy, Color(0xFF1F4068)],
              ),
            ),
            child: Icon(Icons.place_outlined,
                size: 30, color: Colors.white.withValues(alpha: 0.85)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppText.labelLg.copyWith(fontSize: 13.5)),
                      Text(sub, style: AppText.labelSm.copyWith(color: AppColors.hint)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onGo,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(AppRadius.pill)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.navigation_outlined, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text('Go',
                            style: AppText.labelLg.copyWith(fontSize: 13, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputDock extends StatelessWidget {
  final TextEditingController controller;
  final void Function([String?]) onSend;
  final ValueChanged<String> onSuggestion;
  const _InputDock({
    required this.controller,
    required this.onSend,
    required this.onSuggestion,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.screen, 8, AppSpacing.screen,
          8 + MediaQuery.of(context).padding.bottom),
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final s in _suggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => onSuggestion(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 13, color: AppColors.accentAcademic),
                            const SizedBox(width: 5),
                            Text(s, style: AppText.labelLg.copyWith(fontSize: 12.5, color: AppColors.primaryNavy)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppShadow.l1,
            ),
            padding: const EdgeInsets.only(left: 16, right: 6, top: 6, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: AppText.bodyLg.copyWith(fontSize: 15),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Ask anything about campus.',
                      hintStyle: AppText.bodyLg.copyWith(color: AppColors.hint, fontSize: 15),
                    ),
                    onSubmitted: onSend,
                  ),
                ),
                const Icon(Icons.mic_none, size: 20, color: AppColors.hint),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onSend(),
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: AppColors.primaryNavy, shape: BoxShape.circle),
                    child: const Icon(Icons.send, size: 19, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
