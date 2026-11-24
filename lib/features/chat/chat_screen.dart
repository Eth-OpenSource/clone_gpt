import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'chat_controller.dart';
import 'widgets/chat_composer.dart';
import 'widgets/history_drawer.dart';
import 'widgets/message_tile.dart';

class ChatScreen extends StatefulWidget {
  final ChatController controller;

  const ChatScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _userScrolledUp = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.controller.activeStreamNotifier.addListener(_onStreamChunk);
    widget.controller.addListener(_onControllerChanged);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    final distanceToBottom = max - current;

    final isScrolledUp = distanceToBottom > 80;
    if (isScrolledUp != _userScrolledUp) {
      setState(() => _userScrolledUp = isScrolledUp);
    }
  }

  void _onStreamChunk() {
    if (!_userScrolledUp && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_userScrolledUp && _scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  void _onControllerChanged() {
    // When a new message is added or thread changes, scroll to bottom if not scrolled up
    if (!_userScrolledUp && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_userScrolledUp && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    setState(() => _userScrolledUp = false);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    widget.controller.activeStreamNotifier.removeListener(_onStreamChunk);
    widget.controller.removeListener(_onControllerChanged);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final controller = widget.controller;
    final currentThread = controller.currentThread;
    final title = currentThread?.title ?? 'cloneGPT';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, size: 20),
            tooltip: 'Chat history',
            onPressed: () {
              FocusScope.of(context).unfocus();
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.inkPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              fontFamilyFallback: AppTheme.proseFontFallbacks,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_square, size: 19),
              tooltip: 'New Chat',
              onPressed: () {
                FocusScope.of(context).unfocus();
                controller.createNewChat();
              },
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              color: colors.border,
              height: 1,
            ),
          ),
        ),
        drawer: HistoryDrawer(
          threads: controller.threads,
          currentThread: controller.currentThread,
          onSelectThread: (threadId) {
            controller.selectThread(threadId);
          },
          onDeleteThread: (threadId) {
            controller.deleteThread(threadId);
          },
          onNewChat: () {
            controller.createNewChat();
          },
        ),
        body: Column(
          children: [
            // Inline Error Banner
            if (controller.errorMessage != null)
              _ErrorBanner(
                message: controller.errorMessage!,
                onRetry: controller.lastFailedPrompt != null
                    ? () => controller.retryLastTurn()
                    : null,
                onDismiss: () => controller.clearError(),
              ),

            // Message List or Empty State
            Expanded(
              child: Stack(
                children: [
                  controller.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : controller.messages.isEmpty
                          ? _EmptyChatView()
                          : Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: AppTheme.maxContentWidth,
                                ),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  itemCount: controller.messages.length,
                                  itemBuilder: (context, index) {
                                    final message = controller.messages[index];
                                    final isLastMessage =
                                        index == controller.messages.length - 1;
                                    final isStreamingThisMessage =
                                        isLastMessage &&
                                            controller.isStreaming &&
                                            message.isAssistant;

                                    return MessageTile(
                                      key: ValueKey(message.id),
                                      message: message,
                                      isStreamingActive: isStreamingThisMessage,
                                      streamingNotifier: isStreamingThisMessage
                                          ? controller.activeStreamNotifier
                                          : null,
                                    );
                                  },
                                ),
                              ),
                            ),

                  // Floating "Scroll to Bottom" Button
                  if (_userScrolledUp)
                    Positioned(
                      bottom: 12,
                      right: 16,
                      child: _ScrollToBottomButton(onTap: _scrollToBottom),
                    ),
                ],
              ),
            ),

            // Grounded Bottom Composer
            ChatComposer(
              isStreaming: controller.isStreaming,
              onSend: (text) => controller.sendMessage(text),
              onStop: () => controller.stopStreaming(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  'c',
                  style: TextStyle(
                    color: colors.inkPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'What would you like to build or solve today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.inkMuted,
                  fontSize: 14.5,
                  height: 1.4,
                  fontFamilyFallback: AppTheme.proseFontFallbacks,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  const _ErrorBanner({
    required this.message,
    this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.destructive.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(
            color: colors.destructive.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 16,
                color: colors.destructive,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: colors.destructive,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: colors.destructive,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Retry',
                          style: TextStyle(
                            color: colors.destructive,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                color: colors.destructive,
                splashRadius: 14,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrollToBottomButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScrollToBottomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: colors.inkPrimary,
          ),
        ),
      ),
    );
  }
}
