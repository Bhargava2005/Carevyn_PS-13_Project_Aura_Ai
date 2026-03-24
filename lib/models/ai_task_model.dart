// lib/models/ai_task_model.dart

enum AiTaskType {
  chat,
  textToImage,
}


class AiTask {
  final AiTaskType type;
  final String label;
  final String description;
  final String emoji;
  final String modelId;
  final bool requiresImageInput;
  final bool producesImageOutput;

  const AiTask({
    required this.type,
    required this.label,
    required this.description,
    required this.emoji,
    required this.modelId,
    this.requiresImageInput = false,
    this.producesImageOutput = false,
  });
}

/// All supported tasks with their FREE Hugging Face models
class AiTasks {
  static const List<AiTask> all = [
    AiTask(
      type: AiTaskType.chat,
      label: 'AI Chat',
      description: 'Chat with an AI assistant',
      emoji: '💬',
      modelId: 'microsoft/Phi-3-mini-4k-instruct',
    ),
    AiTask(
      type: AiTaskType.textToImage,
      label: 'Text → Image',
      description: 'Generate images from text',
      emoji: '🎨',
      modelId: 'black-forest-labs/FLUX.1-schnell',
      producesImageOutput: true,
    ),
  ];

  static AiTask byType(AiTaskType type) =>
      all.firstWhere((t) => t.type == type);
}