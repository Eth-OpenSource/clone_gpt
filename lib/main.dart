import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'data/local/chat_database.dart';
import 'features/chat/chat_controller.dart';
import 'features/chat/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ChatDatabase.initializeFfiIfNeeded();

  final controller = ChatController();
  await controller.initialize();

  runApp(CloneGptApp(controller: controller));
}

class CloneGptApp extends StatelessWidget {
  final ChatController controller;

  const CloneGptApp({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'cloneGPT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: ChatScreen(controller: controller),
    );
  }
}
