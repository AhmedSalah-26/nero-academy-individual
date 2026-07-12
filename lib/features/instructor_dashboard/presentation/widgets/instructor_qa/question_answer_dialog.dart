import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lms_platform/features/instructor_dashboard/data/models/instructor_question_model.dart';

/// Dialog for answering a student question
class QuestionAnswerDialog extends StatefulWidget {
  final InstructorQuestionModel question;
  final Function(String answer) onSubmit;

  const QuestionAnswerDialog({
    super.key,
    required this.question,
    required this.onSubmit,
  });

  @override
  State<QuestionAnswerDialog> createState() => _QuestionAnswerDialogState();
}

class _QuestionAnswerDialogState extends State<QuestionAnswerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _answerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.question_answer_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isArabic ? 'الرد على السؤال' : 'Answer Question',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question info
                      _buildQuestionCard(isArabic),
                      const SizedBox(height: 24),

                      // Answer input
                      Text(
                        isArabic ? 'إجابتك' : 'Your Answer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _answerController,
                        maxLines: 6,
                        decoration: InputDecoration(
                          hintText: isArabic
                              ? 'اكتب إجابتك هنا...'
                              : 'Write your answer here...',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return isArabic
                                ? 'الرجاء كتابة إجابة'
                                : 'Please write an answer';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(isArabic ? 'إلغاء' : 'Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(isArabic ? 'إرسال الإجابة' : 'Submit Answer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: widget.question.userAvatar != null
                    ? NetworkImage(widget.question.userAvatar!)
                    : null,
                child: widget.question.userAvatar == null
                    ? Text(widget.question.userName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('MMM d, yyyy - h:mm a')
                          .format(widget.question.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Course info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.question.courseTitle,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Question title
          Text(
            widget.question.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          // Question content
          Text(
            widget.question.content,
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      widget.onSubmit(_answerController.text.trim());
      Navigator.pop(context);
    }
  }
}
