import 'package:flutter/foundation.dart';

/// نموذج يمثل استجابة الذكاء الاصطناعي لتحليل وتصحيح الشيفرة.
///
/// يحتوي على الشيفرة الأصلية، الشيفرة المقترحة (إن وجدت)، شرح عربي
/// للمشكلة والحل، قائمة اقتراحات إضافية، درجة الثقة وتاريخ الإنشاء.
class AIResponse {
  /// الشيفرة الأصلية التي تم إرسالها إلى نموذج الذكاء الاصطناعي.
  final String originalCode;

  /// الشيفرة المصححة أو المقترحة من قبل الذكاء الاصطناعي.
  /// قد تكون null إذا لم يتطلب الأمر تعديلًا في الشيفرة.
  final String? correctedCode;

  /// شرح باللغة العربية يوضح طبيعة الخطأ وكيفية إصلاحه.
  final String explanationAr;

  /// قائمة اختياريّة من الاقتراحات أو نصائح أفضل الممارسات.
  final List<String>? suggestions;

  /// درجة الثقة (من 0 إلى 1) التي أعادها نموذج الذكاء الاصطناعي.
  final double? confidence;

  /// الوقت الذي تم فيه إنشاء الاستجابة.
  final DateTime timestamp;

  const AIResponse({
    required this.originalCode,
    this.correctedCode,
    required this.explanationAr,
    this.suggestions,
    this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// إنشاء كائن [AIResponse] من خريطة JSON.
  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      originalCode: json['originalCode'] as String,
      correctedCode: json['correctedCode'] as String?,
      explanationAr: json['explanationAr'] as String,
      suggestions: (json['suggestions'] as List<dynamic>?)?.cast<String>(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// تحويل الكائن الحالي إلى خريطة JSON.
  Map<String, dynamic> toJson() => {
        'originalCode': originalCode,
        'correctedCode': correctedCode,
        'explanationAr': explanationAr,
        'suggestions': suggestions,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
      };

  /// إنشاء نسخة معدّلة من الكائن مع استبدال القيم المحددة فقط.
  AIResponse copyWith({
    String? originalCode,
    String? correctedCode,
    String? explanationAr,
    List<String>? suggestions,
    double? confidence,
    DateTime? timestamp,
  }) {
    return AIResponse(
      originalCode: originalCode ?? this.originalCode,
      correctedCode: correctedCode ?? this.correctedCode,
      explanationAr: explanationAr ?? this.explanationAr,
      suggestions: suggestions ?? this.suggestions,
      confidence: confidence ?? this.confidence,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIResponse &&
        other.originalCode == originalCode &&
        other.correctedCode == correctedCode &&
        other.explanationAr == explanationAr &&
        listEquals(other.suggestions, suggestions) &&
        other.confidence == confidence &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return originalCode.hashCode ^
        correctedCode.hashCode ^
        explanationAr.hashCode ^
        (suggestions?.hashCode ?? 0) ^
        confidence.hashCode ^
        timestamp.hashCode;
  }

  @override
  String toString() {
    return 'AIResponse('
        'originalCode: $originalCode, '
        'correctedCode: $correctedCode, '
        'explanationAr: $explanationAr, '
        'suggestions: $suggestions, '
        'confidence: $confidence, '
        'timestamp: $timestamp'
        ')';
  }
}
