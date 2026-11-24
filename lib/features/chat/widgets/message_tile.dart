import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../core/theme/app_theme.dart';
import '../../../data/models/chat_models.dart';
import 'code_block.dart';

class MessageTile extends StatelessWidget {
  final ChatMessage message;
  final bool isStreamingActive;
  final ValueNotifier<String>? streamingNotifier;

  const MessageTile({
    super.key,
    required this.message,
    this.isStreamingActive = false,
    this.streamingNotifier,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _UserMessageTile(content: message.content);
    } else {
      return _AssistantMessageTile(
        message: message,
        isStreamingActive: isStreamingActive,
        streamingNotifier: streamingNotifier,
      );
    }
  }
}

class _UserMessageTile extends StatelessWidget {
  final String content;

  const _UserMessageTile({required this.content});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border, width: 1),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              color: colors.inkPrimary,
              fontSize: AppTheme.bodyFontSize,
              height: AppTheme.bodyLineHeight,
              fontFamilyFallback: AppTheme.proseFontFallbacks,
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantMessageTile extends StatefulWidget {
  final ChatMessage message;
  final bool isStreamingActive;
  final ValueNotifier<String>? streamingNotifier;

  const _AssistantMessageTile({
    required this.message,
    required this.isStreamingActive,
    this.streamingNotifier,
  });

  @override
  State<_AssistantMessageTile> createState() => _AssistantMessageTileState();
}

class _AssistantMessageTileState extends State<_AssistantMessageTile> {
  bool _copied = false;

  void _copyContent(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStreamingActive && widget.streamingNotifier != null) {
      return ValueListenableBuilder<String>(
        valueListenable: widget.streamingNotifier!,
        builder: (context, streamedText, _) {
          return _buildAssistantBody(
            context,
            content: streamedText,
            isStreaming: true,
          );
        },
      );
    }

    return _buildAssistantBody(
      context,
      content: widget.message.content,
      isStreaming: false,
    );
  }

  Widget _buildAssistantBody(
    BuildContext context, {
    required String content,
    required bool isStreaming,
  }) {
    final colors = context.colors;

    if (content.isEmpty && isStreaming) {
      // Waiting for first token: quiet calm cursor only
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _CalmPulsingDot(),
        ),
      );
    }

    final mdStyleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(
        color: colors.inkPrimary,
        fontSize: AppTheme.bodyFontSize,
        height: AppTheme.bodyLineHeight,
        fontFamilyFallback: AppTheme.proseFontFallbacks,
      ),
      h1: TextStyle(
        color: colors.inkPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        fontFamilyFallback: AppTheme.proseFontFallbacks,
      ),
      h2: TextStyle(
        color: colors.inkPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        fontFamilyFallback: AppTheme.proseFontFallbacks,
      ),
      h3: TextStyle(
        color: colors.inkPrimary,
        fontSize: 16.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
        fontFamilyFallback: AppTheme.proseFontFallbacks,
      ),
      strong: TextStyle(
        color: colors.inkPrimary,
        fontWeight: FontWeight.w600,
      ),
      em: const TextStyle(fontStyle: FontStyle.italic),
      blockquote: TextStyle(
        color: colors.inkMuted,
        fontSize: AppTheme.bodyFontSize,
        height: AppTheme.bodyLineHeight,
      ),
      blockquoteDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: colors.border, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      listBullet: TextStyle(
        color: colors.inkMuted,
        fontSize: AppTheme.bodyFontSize,
      ),
      tableBorder: TableBorder.all(color: colors.border, width: 1),
      tableHead: TextStyle(
        color: colors.inkPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      tableBody: TextStyle(
        color: colors.inkPrimary,
        fontSize: 14,
      ),
      code: TextStyle(
        backgroundColor: Colors.transparent,
        color: colors.inkPrimary,
        fontFamilyFallback: AppTheme.monoFontFallbacks,
        fontSize: 13.5,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarkdownBody(
            data: content,
            selectable: true,
            styleSheet: mdStyleSheet,
            builders: {
              'code': _CodeMarkdownBuilder(context),
            },
          ),
          if (isStreaming) ...[
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: _CalmPulsingDot(),
            ),
          ],
          if (!isStreaming && content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => _copyContent(content),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy_outlined,
                        size: 14,
                        color: _copied ? colors.inkPrimary : colors.inkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied' : 'Copy',
                        style: TextStyle(
                          color: _copied ? colors.inkPrimary : colors.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeMarkdownBuilder extends MarkdownElementBuilder {
  final BuildContext context;

  _CodeMarkdownBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final colors = context.colors;
    final text = element.textContent;

    var language = '';
    final className = element.attributes['class'];
    if (className != null && className.startsWith('language-')) {
      language = className.substring(9);
    }

    final isBlock = className != null || text.contains('\n');
    if (isBlock) {
      final trimmedCode = text.endsWith('\n') ? text.substring(0, text.length - 1) : text;
      return CodeBlockWidget(code: trimmedCode, language: language);
    }

    // Inline code snippet
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.inkPrimary,
          fontSize: 13.5,
          fontFamilyFallback: AppTheme.monoFontFallbacks,
        ),
      ),
    );
  }
}

class _CalmPulsingDot extends StatefulWidget {
  const _CalmPulsingDot();

  @override
  State<_CalmPulsingDot> createState() => _CalmPulsingDotState();
}

class _CalmPulsingDotState extends State<_CalmPulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: colors.inkPrimary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
