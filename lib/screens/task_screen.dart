// lib/screens/task_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/ai_task_model.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';

class TaskScreen extends StatefulWidget {
  final AiTask task;
  const TaskScreen({super.key, required this.task});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _run() {
    final provider = context.read<TaskProvider>();
    provider.runTask(textInput: _textController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Column(
      children: [
        Expanded(
          child: provider.results.isEmpty && !provider.isLoading
              ? _buildEmptyState()
              : _buildResultsList(provider),
        ),
        if (provider.errorMessage != null) _buildErrorBanner(provider),
        _buildInputArea(provider),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.task.emoji,
              style: const TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            widget.task.label,
            style: GoogleFonts.spaceGrotesk(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.description,
            style: GoogleFonts.dmSans(
                color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildModelBadge(),
        ],
      ),
    );
  }

  Widget _buildModelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.memory_rounded,
              color: AppTheme.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            widget.task.modelId.split('/').last,
            style: GoogleFonts.jetBrainsMono(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(TaskProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount:
          provider.results.length + (provider.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (provider.isLoading && index == 0) {
          return _buildLoadingCard();
        }
        final offset = provider.isLoading ? 1 : 0;
        return _buildResultCard(provider.results[index - offset]);
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            _loadingMessage(),
            style: GoogleFonts.dmSans(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _loadingMessage() {
    switch (widget.task.type) {
      case AiTaskType.textToImage:
        return 'Generating image…';
      default:
        return 'Processing…';
    }
  }

  Widget _buildResultCard(TaskResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(
                  AiTasks.byType(result.taskType).emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  AiTasks.byType(result.taskType).label,
                  style: GoogleFonts.dmSans(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(result.timestamp),
                  style: GoogleFonts.dmSans(
                      color: AppTheme.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Content
          if (result.isImage)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.memory(
                result.imageBytes!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: MarkdownBody(
                data: result.text ?? '',
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.dmSans(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                  strong: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  code: GoogleFonts.jetBrainsMono(
                    color: AppTheme.secondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(TaskProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  decoration: BoxDecoration(
                    color: AppTheme.bgInput,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: _hintText(),
                      hintStyle: GoogleFonts.dmSans(
                          color: AppTheme.textHint, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: provider.isLoading ? null : _run,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: provider.isLoading
                        ? AppTheme.bgInput
                        : AppTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: provider.isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            )
                          ],
                  ),
                  child: provider.isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primary,
                            ),
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(TaskProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppTheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style:
                  GoogleFonts.dmSans(color: AppTheme.error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: provider.clearError,
            child:
                const Icon(Icons.close, color: AppTheme.error, size: 16),
          ),
        ],
      ),
    );
  }

  String _hintText() {
    switch (widget.task.type) {
      case AiTaskType.textToImage:
        return 'Describe the image you want…';
      default:
        return 'Enter your input…';
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}