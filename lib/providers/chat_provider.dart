// lib/providers/chat_provider.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/voice_service.dart';

enum ChatState { idle, loading, error }

/// A message that may carry an image result alongside text
class ChatMessage extends Message {
  final Uint8List? resultImage;
  final bool isVoice;

  ChatMessage({
    required super.id,
    required super.content,
    required super.role,
    required super.timestamp,
    super.status,
    this.resultImage,
    this.isVoice = false,
  });
}

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  final _uuid = const Uuid();
  final _voiceService = VoiceService();

  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  ChatState _state = ChatState.idle;
  String? _errorMessage;
  bool _isTyping = false;

  // Image mode state
  bool _imageModeEnabled = false;
  Uint8List? _pendingImage; // image user attached

  // Track if AI is currently speaking
  bool _isSpeaking = false;

  // Extra messages list that can hold ChatMessage (with image bytes)
  final List<ChatMessage> _richMessages = [];

  List<Conversation> get conversations => _conversations;
  Conversation? get activeConversation => _activeConversation;
  List<Message> get messages => _activeConversation?.messages ?? [];
  List<ChatMessage> get richMessages => _richMessages;
  ChatState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isTyping => _isTyping;
  bool get isLoading => _state == ChatState.loading;
  bool get imageModeEnabled => _imageModeEnabled;
  bool get isSpeaking => _isSpeaking;
  Uint8List? get pendingImage => _pendingImage;

  ChatProvider({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService {
    _voiceService.setOnSpeechDone(() {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    _conversations = await _storageService.loadConversations();
    final activeId = await _storageService.loadActiveConversationId();
    if (activeId != null) {
      _activeConversation = _conversations
          .cast<Conversation?>()
          .firstWhere((c) => c?.id == activeId, orElse: () => null);
      if (_activeConversation != null) {
        _syncRichMessages();
      }
    }
    if (_conversations.isEmpty) await createNewConversation();
    notifyListeners();
  }

  // ─── Image Mode ───────────────────────────────────────────────────────────

  void toggleImageMode() {
    _imageModeEnabled = !_imageModeEnabled;
    if (!_imageModeEnabled) _pendingImage = null;
    notifyListeners();
  }

  void setPendingImage(Uint8List? bytes) {
    _pendingImage = bytes;
    notifyListeners();
  }

  // ─── Conversations ────────────────────────────────────────────────────────

  Future<void> createNewConversation() async {
    _richMessages.clear();
    final conv = Conversation(
      id: _uuid.v4(),
      title: 'New Chat',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _conversations.insert(0, conv);
    _activeConversation = conv;
    _imageModeEnabled = false;
    _pendingImage = null;
    _state = ChatState.idle;
    _errorMessage = null;
    await _persist();
    notifyListeners();
  }

  Future<void> selectConversation(Conversation conversation) async {
    _richMessages.clear();
    _activeConversation = conversation;
    _state = ChatState.idle;
    _errorMessage = null;
    _imageModeEnabled = false;
    _pendingImage = null;
    _syncRichMessages();
    await _storageService.saveActiveConversationId(conversation.id);
    notifyListeners();
  }

  Future<void> deleteConversation(String id) async {
    _conversations.removeWhere((c) => c.id == id);
    if (_activeConversation?.id == id) {
      _activeConversation = _conversations.isNotEmpty ? _conversations.first : null;
      if (_activeConversation == null) { await createNewConversation(); return; }
    }
    await _storageService.deleteConversation(id);
    await _storageService.saveActiveConversationId(_activeConversation?.id);
    notifyListeners();
  }

  // ─── Send Message ─────────────────────────────────────────────────────────

  Future<void> sendMessage(String content, {bool isVoiceInput = false}) async {
    if (content.trim().isEmpty || _activeConversation == null) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      isVoice: isVoiceInput,
    );

    _activeConversation!.messages.add(userMsg);
    _richMessages.add(userMsg);

    if (_activeConversation!.messages.length == 1) {
      _activeConversation!.title = content.trim().length > 40
          ? '${content.trim().substring(0, 40)}…'
          : content.trim();
    }

    _state = ChatState.loading;
    _isTyping = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_imageModeEnabled) {
        // IMAGE MODE: route to image handler
        final result = await _apiService.handleImageRequest(
          prompt: content.trim(),
        );

        final label = '🎨 *Image generated from:* "${content.trim()}"';

        final aiMsg = ChatMessage(
          id: _uuid.v4(),
          content: label,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
          resultImage: result.imageBytes,
          isVoice: isVoiceInput,
        );

        _activeConversation!.messages.add(aiMsg);
        _richMessages.add(aiMsg);
        _pendingImage = null; // clear after use
        
        if (isVoiceInput) {
          _isSpeaking = true;
          notifyListeners();
          await _voiceService.speak(label);
        }

      } else {
        // CHAT MODE
        final reply = await _apiService.sendMessage(_activeConversation!.messages);
        final aiMsg = ChatMessage(
          id: _uuid.v4(),
          content: reply,
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
          isVoice: isVoiceInput,
        );
        _activeConversation!.messages.add(aiMsg);
        _richMessages.add(aiMsg);

        if (isVoiceInput) {
          _isSpeaking = true;
          notifyListeners();
          await _voiceService.speak(reply);
        }
      }

      _activeConversation!.updatedAt = DateTime.now();
      _state = ChatState.idle;
    } on ApiException catch (e) {
      _state = ChatState.error;
      _errorMessage = e.message;
    } catch (e) {
      _state = ChatState.error;
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isTyping = false;
      await _persist();
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    _state = ChatState.idle;
    notifyListeners();
  }

  Future<void> clearCurrentConversation() async {
    _activeConversation?.messages.clear();
    _activeConversation?.title = 'New Chat';
    _activeConversation?.updatedAt = DateTime.now();
    _richMessages.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _storageService.saveConversations(_conversations);
    await _storageService.saveActiveConversationId(_activeConversation?.id);
  }

  void _syncRichMessages() {
    _richMessages.clear();
    if (_activeConversation != null) {
      for (final m in _activeConversation!.messages) {
        _richMessages.add(ChatMessage(
          id: m.id,
          content: m.content,
          role: m.role,
          timestamp: m.timestamp,
          status: m.status,
          isVoice: m.isVoice,
        ));
      }
    }
  }

  // ─── Voice ────────────────────────────────────────────────────────────────

  bool get isListening => _voiceService.isListening;

  Future<void> startListening() async {
    await _voiceService.startListening((text) {
      if (text.isNotEmpty) {
        sendMessage(text, isVoiceInput: true);
      }
    });
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
    _isSpeaking = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _apiService.dispose();
    _voiceService.stopSpeaking();
    super.dispose();
  }
}