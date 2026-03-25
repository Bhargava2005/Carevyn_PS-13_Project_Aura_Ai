// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/neural_logo.dart';
import '../widgets/conversation_sidebar.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required bool embedded});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(() {
      setState(() => _hasText = _inputCtrl.text.trim().isNotEmpty);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  void _sendMessage() {
    final provider = context.read<ChatProvider>();
    if (_hasText && !provider.isLoading) {
      provider.sendMessage(_inputCtrl.text, isVoiceInput: false);
      _inputCtrl.clear();
      setState(() => _hasText = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (provider.richMessages.isNotEmpty || provider.isTyping) {
          _scrollToBottom();
        }
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          drawer: const ConversationSidebar(),
          body: Column(
            children: [
              _buildAppBar(context, provider),
              Expanded(
                child: provider.richMessages.isEmpty
                    ? _buildWelcome(provider)
                    : _buildMessageList(provider),
              ),
              if (provider.errorMessage != null) _buildErrorBanner(provider),
              _buildInputArea(provider),
            ],
          ),
        );
      },
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, ChatProvider provider) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: AppTheme.bgDark,
          border:
              Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            // Hamburger menu
            Builder(
              builder: (ctx) => IconButton(
                icon: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _menuLine(1.0),
                    const SizedBox(height: 4),
                    _menuLine(0.7),
                    const SizedBox(height: 4),
                    _menuLine(0.5),
                  ],
                ),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            // Logo + title
            const NeuralLogo(size: 34),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF00C9FF), Color(0xFF7B5EA7)],
                  ).createShader(b),
                  child: Text('Aura AI',
                      style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                Text(
                  provider.activeConversation?.title == 'New Chat'
                      ? 'Start a conversation'
                      : (provider.activeConversation?.title ?? ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textHint, fontSize: 10.5),
                ),
              ],
            ),
            const Spacer(),
            // New chat button
            if (provider.richMessages.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.add,
                    color: AppTheme.textSecondary, size: 24),
                tooltip: 'New chat',
                onPressed: () => provider.createNewConversation(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _menuLine(double widthFactor) => Container(
        width: 22 * widthFactor,
        height: 2,
        decoration: BoxDecoration(
          color: AppTheme.textSecondary,
          borderRadius: BorderRadius.circular(1),
        ),
      );

  // ─── Welcome ──────────────────────────────────────────────────────────────

  Widget _buildWelcome(ChatProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const SizedBox(height: 36),
          const NeuralLogo(size: 88),
          const SizedBox(height: 22),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF00C9FF), Color(0xFF7B5EA7)],
            ).createShader(b),
            child: Text('Aura AI',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 6),
          Text('What can I help you with today?',
              style: GoogleFonts.dmSans(
                  color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 36),
          ...[
            ('💬', 'Write a cover letter', 'for a software engineering role'),
            ('🎨', 'Generate an image', 'from your description'),
            ('🧠', 'Explain machine learning', 'in simple terms'),
            ('💻', 'Debug my code', 'and explain the fix'),
          ].map((s) => _suggestionCard(s.$1, s.$2, s.$3, provider)),
        ],
      ),
    );
  }

  Widget _suggestionCard(
      String emoji, String title, String sub, ChatProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
      onTap: () {
        if (title == 'Generate an image') {
          provider.toggleImageMode();
          _inputFocusNode.requestFocus();
        } else {
          provider.sendMessage('$title $sub', isVoiceInput: false);
        }
      },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.dmSans(
                            color: AppTheme.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500)),
                    Text(sub,
                        style: GoogleFonts.dmSans(
                            color: AppTheme.textHint, fontSize: 12)),
                  ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppTheme.textHint),
          ]),
        ),
      ),
    );
  }

  // ─── Message List ─────────────────────────────────────────────────────────

  Widget _buildMessageList(ChatProvider provider) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      itemCount: provider.richMessages.length + (provider.isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.richMessages.length && provider.isTyping) {
          return const TypingIndicator();
        }
        return _buildBubble(provider.richMessages[index]);
      },
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) _aiAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.content));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Copied',
                      style: GoogleFonts.dmSans(color: Colors.white)),
                  backgroundColor: AppTheme.bgCard,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ));
              },
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78),
                decoration: BoxDecoration(
                  color: isUser ? AppTheme.userBubble : AppTheme.aiBubble,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isUser ? null : Border.all(color: AppTheme.divider),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? AppTheme.primary.withOpacity(0.2)
                          : Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show image if result is an image
                    if (msg.resultImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(msg.resultImage!,
                            width: double.infinity, fit: BoxFit.cover),
                      ),
                      if (msg.content.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (isUser)
                      Text(msg.content,
                          style: GoogleFonts.dmSans(
                              color: Colors.white, fontSize: 14.5, height: 1.5))
                    else if (msg.content.isNotEmpty)
                      MarkdownBody(
                        data: msg.content,
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.dmSans(
                              color: AppTheme.textPrimary,
                              fontSize: 14.5,
                              height: 1.6),
                          code: GoogleFonts.jetBrainsMono(
                              color: AppTheme.primary,
                              backgroundColor: AppTheme.bgInput,
                              fontSize: 13),
                          codeblockDecoration: BoxDecoration(
                              color: AppTheme.bgInput,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.divider)),
                          strong: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700),
                          listBullet: TextStyle(color: AppTheme.primary),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(msg.timestamp),
                          style: GoogleFonts.dmSans(
                              color: isUser ? Colors.white38 : AppTheme.textHint,
                              fontSize: 10.5),
                        ),
                        if (!isUser && msg.isVoice) ...[
                          const SizedBox(width: 8),
                          Consumer<ChatProvider>(
                            builder: (context, provider, _) {
                              if (provider.isSpeaking) {
                                return GestureDetector(
                                  onTap: () => provider.stopSpeaking(),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.volume_off_rounded,
                                        size: 20, color: AppTheme.primary),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _userAvatar(),
        ],
      ),
    );
  }

  Widget _aiAvatar() => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF00C9FF), Color(0xFF7B5EA7)]).createShader(b),
            child:
                const Icon(Icons.hub_outlined, size: 16, color: Colors.white),
          ),
        ),
      );

  Widget _userAvatar() => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const Icon(Icons.person_outline,
            size: 16, color: AppTheme.textSecondary),
      );

  // ─── Input Area ───────────────────────────────────────────────────────────

  Widget _buildInputArea(ChatProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image mode banner + pending image preview
          if (provider.imageModeEnabled) _buildImageModeBanner(provider),
          if (provider.imageModeEnabled && provider.pendingImage != null)
            _buildImagePreview(provider),
          const SizedBox(height: 6),
          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Text field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 110),
                  decoration: BoxDecoration(
                    color: AppTheme.bgInput,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: TextField(
                    controller: _inputCtrl,
                    focusNode: _inputFocusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textPrimary, fontSize: 14.5),
                    decoration: InputDecoration(
                      hintText: provider.imageModeEnabled
                          ? 'Describe the image…'
                          : 'Message Aura AI…',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Mic button
              _MicButton(
                active: provider.isListening,
                onTap: () {
                  if (provider.isListening) {
                    provider.stopListening();
                  } else {
                    provider.startListening();
                  }
                },
              ),
              const SizedBox(width: 8),
              // Send button
              GestureDetector(
                onTap: provider.isLoading ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: (_hasText && !provider.isLoading)
                        ? const LinearGradient(
                            colors: [Color(0xFF00C9FF), Color(0xFF7B5EA7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight)
                        : null,
                    color: (!_hasText || provider.isLoading)
                        ? AppTheme.bgInput
                        : null,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: (_hasText && !provider.isLoading)
                        ? [
                            BoxShadow(
                                color: AppTheme.primary.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: provider.isLoading
                      ? const Center(
                          child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.primary)))
                      : const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageModeBanner(ChatProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF00C9FF), Color(0xFF7B5EA7)]).createShader(b),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.pendingImage == null
                  ? 'Image mode on — type a prompt to generate, or attach an image to transform it'
                  : 'Image attached — type what changes you want, or send to caption it',
              style: GoogleFonts.dmSans(
                  color: AppTheme.textSecondary, fontSize: 11.5),
            ),
          ),
          GestureDetector(
            onTap: provider.toggleImageMode,
            child: const Icon(Icons.close, color: AppTheme.textHint, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ChatProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      height: 90,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(provider.pendingImage!,
                height: 90, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => provider.setPendingImage(null),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ChatProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.error, size: 16),
        const SizedBox(width: 8),
        Expanded(
            child: Text(provider.errorMessage!,
                style:
                    GoogleFonts.dmSans(color: AppTheme.error, fontSize: 13))),
        GestureDetector(
            onTap: provider.clearError,
            child: const Icon(Icons.close, color: AppTheme.error, size: 16)),
      ]),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _MicButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _MicButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: active ? AppTheme.error.withOpacity(0.15) : AppTheme.bgInput,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: active ? AppTheme.error : AppTheme.divider,
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: AppTheme.error.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Icon(
          active ? Icons.mic_rounded : Icons.mic_none_rounded,
          color: active ? AppTheme.error : AppTheme.textHint,
          size: 20,
        ),
      ),
    );
  }
}

