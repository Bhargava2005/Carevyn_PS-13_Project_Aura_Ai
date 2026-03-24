// lib/widgets/conversation_sidebar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/conversation_model.dart';
import '../providers/chat_provider.dart';
import '../utils/app_theme.dart';
import 'neural_logo.dart';

class ConversationSidebar extends StatelessWidget {
  const ConversationSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    return Drawer(
      backgroundColor: AppTheme.bgCard,
      width: MediaQuery.of(context).size.width * 0.80,
      child: SafeArea(
        child: Column(children: [
          _buildHeader(context, provider),
          const Divider(color: AppTheme.divider, height: 1),
          Expanded(
            child: provider.conversations.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.conversations.length,
                    itemBuilder: (ctx, i) {
                      final conv = provider.conversations[i];
                      final isActive = conv.id == provider.activeConversation?.id;
                      return _buildTile(context, conv, isActive, provider);
                    },
                  ),
          ),
          const Divider(color: AppTheme.divider, height: 1),
          _buildFooter(),
        ]),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChatProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(children: [
        const NeuralLogo(size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF00C9FF), Color(0xFF7B5EA7)]).createShader(b),
              child: Text('Aura AI',
                  style: GoogleFonts.spaceGrotesk(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            Text('${provider.conversations.length} conversation${provider.conversations.length == 1 ? '' : 's'}',
                style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 11)),
          ]),
        ),
        IconButton(
          icon: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: const Icon(Icons.add, color: AppTheme.primary, size: 18),
          ),
          onPressed: () {
            provider.createNewConversation();
            Navigator.pop(context);
          },
          tooltip: 'New chat',
        ),
      ]),
    );
  }

  Widget _buildTile(BuildContext context, Conversation conv, bool isActive, ChatProvider provider) {
    return InkWell(
      onTap: () {
        provider.selectConversation(conv);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isActive ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: AppTheme.primary.withOpacity(0.3))
              : null,
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primary.withOpacity(0.15)
                  : AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 16,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(conv.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                      color: isActive ? AppTheme.primary : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400)),
              Text(_relativeTime(conv.updatedAt),
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textHint, fontSize: 11)),
            ]),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppTheme.textHint, size: 18),
            onPressed: () => provider.deleteConversation(conv.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Delete chat',
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.forum_outlined, color: AppTheme.textHint, size: 38),
        const SizedBox(height: 10),
        Text('No conversations yet',
            style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 13)),
      ]),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
          const SizedBox(width: 8),
          Text('Cloud Synced',
              style: GoogleFonts.dmSans(color: AppTheme.textHint, fontSize: 12)),
      ]),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}