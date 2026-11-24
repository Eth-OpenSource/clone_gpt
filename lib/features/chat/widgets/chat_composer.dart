import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ChatComposer extends StatefulWidget {
  final bool isStreaming;
  final ValueChanged<String> onSend;
  final VoidCallback onStop;

  const ChatComposer({
    super.key,
    required this.isStreaming,
    required this.onSend,
    required this.onStop,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final TextEditingController _textController;
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final canSend = _textController.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.isStreaming) return;
    widget.onSend(text);
    _textController.clear();
    setState(() => _canSend = false);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewPadding.bottom > 0
            ? MediaQuery.of(context).viewPadding.bottom + 8
            : 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colors.border, width: 1),
            ),
            padding: const EdgeInsets.only(left: 16, right: 6, top: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 5,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    style: TextStyle(
                      color: colors.inkPrimary,
                      fontSize: 15,
                      height: 1.4,
                      fontFamilyFallback: AppTheme.proseFontFallbacks,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Message cloneGPT...',
                      hintStyle: TextStyle(
                        color: colors.inkMuted,
                        fontSize: 15,
                        fontFamilyFallback: AppTheme.proseFontFallbacks,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) {
                      if (_canSend && !widget.isStreaming) {
                        _handleSend();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: widget.isStreaming
                      ? _ComposerButton(
                          onTap: widget.onStop,
                          backgroundColor: colors.accent,
                          iconColor: colors.background,
                          icon: Icons.stop_rounded,
                          tooltip: 'Stop generation',
                        )
                      : _ComposerButton(
                          onTap: _canSend ? _handleSend : null,
                          backgroundColor: _canSend ? colors.accent : colors.border,
                          iconColor: _canSend ? colors.background : colors.inkMuted,
                          icon: Icons.arrow_upward_rounded,
                          tooltip: 'Send message',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String tooltip;

  const _ComposerButton({
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
