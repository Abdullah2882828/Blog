import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/themes/atom-one-dark.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import '../services/ai_analysis_service.dart';

/// شاشة محرر الشيفرة المتقدمة.
///
/// تدعم:
/// * تلوين بناء الجملة للغات البرمجة (حاليًا Dart كمثال).
/// * إدخال النص من صورة باستخدام OCR (Google ML Kit).
/// * إرسال الشيفرة إلى خدمة الذكاء الاصطناعي لتحليل الأخطاء وتقديم شرح عربي.
class CodeEditorScreen extends StatefulWidget {
  const CodeEditorScreen({Key? key}) : super(key: key);

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> {
  late final CodeController _codeController;
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  String? _analysisResult;

  @override
  void initState() {
    super.initState();
    _codeController = CodeController(
      text: '',
      language: dart,
      theme: atomOneDarkTheme,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// يلتقط صورة من الكاميرا أو المعرض ثم يستخرج النص باستخدام OCR.
  Future<void> _pickImageAndExtract() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (image == null) return;

      final InputImage inputImage = InputImage.fromFilePath(image.path);
      final TextRecognizer recognizer = GoogleMlKit.vision.textRecognizer();
      final RecognizedText recognizedText = await recognizer.processImage(inputImage);
      await recognizer.close();

      final String extracted = recognizedText.text;
      if (extracted.isNotEmpty) {
        // أضف النص المستخرج إلى محرر الشيفرة.
        final newText = _codeController.text + '\n' + extracted;
        setState(() {
          _codeController.text = newText;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ أثناء استخراج النص: $e')),
        );
      }
    }
  }

  /// يرسل الشيفرة إلى خدمة الذكاء الاصطناعي للحصول على تحليل.
  Future<void> _analyzeCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال الشيفرة أولاً')),
      );
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      final result = await AIAnalysisService.analyzeCode(code);
      setState(() => _analysisResult = result);
    } catch (e) {
      setState(() => _analysisResult = 'فشل التحليل: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محرر الشيفرة'),
        actions: [
          IconButton(
            tooltip: 'إضافة من صورة',
            icon: const Icon(Icons.image),
            onPressed: _pickImageAndExtract,
          ),
          IconButton(
            tooltip: 'تحليل الشيفرة',
            icon: const Icon(Icons.auto_fix_high),
            onPressed: _isAnalyzing ? null : _analyzeCode,
          ),
        ],
      ),
      body: Column(
        children: [
          // محرر الشيفرة
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CodeField(
                controller: _codeController,
                textStyle: const TextStyle(fontFamily: 'SourceCodePro', fontSize: 14),
                expands: true,
                lineNumberStyle: const LineNumberStyle(width: 40),
              ),
            ),
          ),
          // منطقة عرض نتيجة التحليل
          if (_analysisResult != null)
            Container(
              width: double.infinity,
              color: Colors.grey.shade900,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  _analysisResult!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          if (_isAnalyzing)
            const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
