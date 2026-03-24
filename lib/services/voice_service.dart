// lib/services/voice_service.dart
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isSpeechInitialized = false;
  Function()? _onSpeechDone;

  Future<bool> init() async {
    final micStatus = await Permission.microphone.request();
    final speechStatus = await Permission.speech.request();
    
    if (micStatus.isGranted && speechStatus.isGranted) {
      _isSpeechInitialized = await _speech.initialize(
        onStatus: (status) => print('STT Status: $status'),
        onError: (error) => print('STT Error: $error'),
      );
      
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(0.85); // Lower pitch for a more masculine sound

      _tts.setCompletionHandler(() {
        if (_onSpeechDone != null) _onSpeechDone!();
      });

      _tts.setErrorHandler((msg) {
        if (_onSpeechDone != null) _onSpeechDone!();
      });

      // Try to find a male voice explicitly if available
      try {
        List<dynamic> voices = await _tts.getVoices;
        for (var voice in voices) {
          if (voice is Map) {
            final name = (voice['name'] ?? '').toString().toLowerCase();
            if (name.contains('male') || name.contains('guy') || name.contains('david')) {
              await _tts.setVoice({"name": voice["name"], "locale": voice["locale"]});
              break;
            }
          }
        }
      } catch (e) {
        print('Error selecting specific voice: $e');
      }
      
      return _isSpeechInitialized;
    }
    return false;
  }

  void setOnSpeechDone(Function() callback) {
    _onSpeechDone = callback;
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isSpeechInitialized) await init();
    
    if (_isSpeechInitialized) {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
      );
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> speak(String text) async {
    if (!_isSpeechInitialized) await init();
    // Basic cleaning of markdown if necessary
    final cleanText = text.replaceAll(RegExp(r'[*#_`]'), '');
    await _tts.speak(cleanText);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  bool get isListening => _speech.isListening;
}
