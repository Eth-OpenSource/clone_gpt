import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/chat_models.dart';

class HistoryDrawer extends StatelessWidget {
  final List<ChatThread> threads;
  final ChatThread? currentThread;
  final ValueChanged<String> onSelectThread;
  final ValueChanged<String> onDeleteThread;
  final VoidCallback onNewChat;

  const HistoryDrawer({
    super.key,
    required this.threads,
    required this.currentThread,
    required this.onSelectThread,
    required this.onDeleteThread,
    required this.onNewChat,
  });

  void _confirmDelete(BuildContext context, ChatThread thread) {
    final colors = context.colors;
    showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.border, width: 1),
        ),
        title: Text(
          'Delete Chat',
          style: TextStyle(
            color: colors.inkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${thread.title}"? This cannot be undone.',
          style: TextStyle(
            color: colors.inkMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.inkMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: colors.destructive,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        onDeleteThread(thread.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Drawer(
      backgroundColor: colors.background,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: colors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'c',
                      style: TextStyle(
                        color: colors.background,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'cloneGPT',
                    style: TextStyle(
                      color: colors.inkPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      fontFamilyFallback: AppTheme.proseFontFallbacks,
                    ),
                  ),
                ],
              ),
            ),
            // New Chat Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onNewChat();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: colors.inkPrimary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'New Chat',
                        style: TextStyle(
                          color: colors.inkPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamilyFallback: AppTheme.proseFontFallbacks,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Recents label
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 6),
              child: Text(
                'RECENTS',
                style: TextStyle(
                  color: colors.inkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  fontFamilyFallback: AppTheme.proseFontFallbacks,
                ),
              ),
            ),
            // Thread List
            Expanded(
              child: threads.isEmpty
                  ? Center(
                      child: Text(
                        'No chat history yet',
                        style: TextStyle(
                          color: colors.inkMuted,
                          fontSize: 13,
                          fontFamilyFallback: AppTheme.proseFontFallbacks,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: threads.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemBuilder: (context, index) {
                        final thread = threads[index];
                        final isSelected = currentThread?.id == thread.id;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? colors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? colors.border : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 0,
                            ),
                            title: Text(
                              thread.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected
                                    ? colors.inkPrimary
                                    : colors.inkMuted,
                                fontSize: 13.5,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontFamilyFallback: AppTheme.proseFontFallbacks,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16),
                              color: colors.inkMuted,
                              splashRadius: 16,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              tooltip: 'Delete thread',
                              onPressed: () => _confirmDelete(context, thread),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              onSelectThread(thread.id);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
