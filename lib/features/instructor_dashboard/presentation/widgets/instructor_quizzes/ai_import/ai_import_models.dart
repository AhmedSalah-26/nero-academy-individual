class AiPreviewQuestion {
  final String questionAr;
  final String questionEn;
  final String type;
  final int points;
  final List<AiPreviewOption> options;
  final String? correctAnswer;

  AiPreviewQuestion({
    required this.questionAr,
    required this.questionEn,
    required this.type,
    required this.points,
    required this.options,
    this.correctAnswer,
  });
}

class AiPreviewOption {
  final String textAr;
  final String textEn;
  final bool isCorrect;

  AiPreviewOption({
    required this.textAr,
    required this.textEn,
    required this.isCorrect,
  });
}
