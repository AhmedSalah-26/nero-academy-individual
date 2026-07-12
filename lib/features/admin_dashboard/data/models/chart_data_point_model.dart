/// Chart Data Point Model
class ChartDataPointModel {
  final String label;
  final double value;
  final DateTime? date;

  const ChartDataPointModel({
    required this.label,
    required this.value,
    this.date,
  });

  factory ChartDataPointModel.fromJson(Map<String, dynamic> json) {
    return ChartDataPointModel(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      date:
          json['date'] != null ? DateTime.parse(json['date'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'date': date?.toIso8601String(),
    };
  }
}
