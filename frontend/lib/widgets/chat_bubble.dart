import 'package:flutter/material.dart';
import '../theme.dart';

class ChatBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isComplete;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ChatBubble({
    Key? key,
    required this.content,
    required this.isUser,
    this.isComplete = true,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          minWidth: 80,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: isUser 
                ? BoxDecoration(
                    color: AuraTheme.accentBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AuraTheme.accentBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  )
                : AuraTheme.solidDecoration(radius: 20, shadow: true).copyWith(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.isEmpty ? "..." : content, // 🛡️ Anti-empty bubble
                    style: TextStyle(
                      color: isUser ? Colors.white : AuraTheme.textPrimary,
                      fontSize: 15,
                      height: 1.45,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.2, 
                          color: isUser ? Colors.white60 : AuraTheme.accentBlue
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
                child: InkWell(
                  onTap: onAction,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AuraTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AuraTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_outward_rounded, size: 14, color: AuraTheme.textPrimary),
                        const SizedBox(width: 8),
                        Text(
                          actionLabel!.toUpperCase(),
                          style: const TextStyle(
                            color: AuraTheme.textPrimary, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
