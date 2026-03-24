// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/ai_task_model.dart';
import '../providers/task_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/neural_logo.dart';
import 'chat_screen.dart';
import 'task_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final activeTask = taskProvider.activeTask;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Column(
        children: [
          _buildHeader(context),
          _buildTaskSelector(taskProvider),
          const Divider(color: AppTheme.divider, height: 1),
          Expanded(
            child: activeTask.type == AiTaskType.chat
                ? const ChatScreen(embedded: true)
                : TaskScreen(task: activeTask),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: AppTheme.bgDark,
          border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            // Phoenix logo — small in header
            const NeuralLogo(size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFD700)],
                  ).createShader(bounds),
                  child: Text(
                    'Aura AI',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'HuggingFace powered',
                  style: GoogleFonts.dmSans(
                    color: AppTheme.textHint,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Online badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withOpacity(0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Online',
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textHint, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSelector(TaskProvider provider) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: AiTasks.all.length,
        itemBuilder: (context, index) {
          final task = AiTasks.all[index];
          final isActive = provider.activeTask.type == task.type;
          return _buildTaskChip(task, isActive, provider);
        },
      ),
    );
  }

  Widget _buildTaskChip(AiTask task, bool isActive, TaskProvider provider) {
    return GestureDetector(
      onTap: () => provider.selectTask(task),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.15)
              : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.divider,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(task.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              task.label,
              style: GoogleFonts.dmSans(
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}