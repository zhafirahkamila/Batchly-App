import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class ChatbotPlaceholderScreen extends StatelessWidget {
  const ChatbotPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Chatbot')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Coming soon',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Soon you\'ll be able to ask Batchly AI: "Why is my brownie margin so thin?" or "How can I reduce ingredient costs?"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
