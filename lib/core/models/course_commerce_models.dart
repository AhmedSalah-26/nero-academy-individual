class CoursePricingOption {
  final String label;
  final double price;
  final int? durationDays;

  const CoursePricingOption({
    required this.label,
    required this.price,
    this.durationDays,
  });

  factory CoursePricingOption.fromJson(Map<String, dynamic> json) {
    return CoursePricingOption(
      label: (json['label'] as String? ?? '').trim(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      durationDays: (json['duration_days'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label.trim(),
        'price': price,
        if (durationDays != null) 'duration_days': durationDays,
      };

  bool get isValid => label.trim().isNotEmpty && price >= 0;

  String displayLabel(String currency) {
    final days = durationDays;
    final duration = days == null || days <= 0 ? '' : ' - $days days';
    return '$label$duration - ${price.toStringAsFixed(0)} $currency';
  }
}

class CourseGroupLinks {
  final String? whatsapp;
  final String? telegram;
  final String? facebook;

  const CourseGroupLinks({
    this.whatsapp,
    this.telegram,
    this.facebook,
  });

  factory CourseGroupLinks.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CourseGroupLinks();
    return CourseGroupLinks(
      whatsapp: _clean(json['whatsapp']),
      telegram: _clean(json['telegram']),
      facebook: _clean(json['facebook']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (whatsapp != null && whatsapp!.trim().isNotEmpty)
          'whatsapp': whatsapp!.trim(),
        if (telegram != null && telegram!.trim().isNotEmpty)
          'telegram': telegram!.trim(),
        if (facebook != null && facebook!.trim().isNotEmpty)
          'facebook': facebook!.trim(),
      };

  bool get hasAny =>
      (whatsapp?.trim().isNotEmpty ?? false) ||
      (telegram?.trim().isNotEmpty ?? false) ||
      (facebook?.trim().isNotEmpty ?? false);

  static String? _clean(dynamic value) {
    final text = (value as String?)?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

List<CoursePricingOption> parseCoursePricingOptions(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(CoursePricingOption.fromJson)
      .where((option) => option.isValid)
      .toList();
}
