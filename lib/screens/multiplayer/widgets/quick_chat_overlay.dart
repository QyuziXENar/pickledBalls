// lib/screens/multiplayer/widgets/quick_chat_overlay.dart

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/online_profile_models.dart';
import '../../../widgets/game_components.dart';

class QuickChatBubble extends StatelessWidget {
  final String text;

  const QuickChatBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B26),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.opticYellow, width: 1.8),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
      ),
    );
  }
}

class QuickChatPickerSheet extends StatelessWidget {
  final Function(QuickChatCall call) onSend;

  const QuickChatPickerSheet({super.key, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.opticYellow, width: 2.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('COURTSIDE CHAT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
              IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 6),
          for (final call in QuickChatCall.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: BouncyButton(
                onTap: () {
                  onSend(call);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(call.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}