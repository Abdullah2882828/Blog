import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:your_app_name/services/ai_analysis_service.dart';
import 'package:your_app_name/models/ai_response.dart';

/// شاشة المحادثة الذكية التي تسمح للمستخدم بطرح أسئلة برمجية
/// وتلقي إجابات عربية مفصلة مع شيفرات مقترحة.
///
/// تم تصميم الواجهة لتكون بسيطة، تدعم الاتجاه من اليمين إلى اليسار
/// (Arabic) وتظهر الرسائل في فقاعة مميزة حسب الطرف (المستخدم أو الذكاء
/// الاصطناعي).
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// يضيف رسالة من المستخدم ثم يستدعي خدمة التحليل للذكاء الاصطناعي.
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(content: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    // إخفاء لوحة المفاتيح بعد الإرسال
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    try {
      final AIResponse response = await AIAnalysisService.instance.analyzeCode(text);
      setState(() {
        _messages.add(_ChatMessage(content: response.explanation, isUser: false));
        if (response.generatedCode != null && response.generatedCode!.trim().isNotEmpty) {
          _messages.add(_ChatMessage(content: response.generatedCode!, isUser: false, isCode: true));
        }
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(content: "حدث خطأ أثناء الاتصال بالذكاء الاصطناعي: $e", isUser: false));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محادثة ذكية'),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[_messages.length - 1 - index]; // عكس الترتيب لعرض الأحدث في الأسفل
                  return _MessageBubble(message: msg);
                },
              ),
            ),
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 2),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Theme.of(context).cardColor,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'اكتب سؤالك أو الكود هنا... ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              color: Theme.of(context).primaryColor,
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

/// نموذج داخلي بسيط لتمثيل رسالة في المحادثة.
class _ChatMessage {
  final String content;
  final bool isUser; // true إذا كانت الرسالة من المستخدم
  final bool isCode; // true إذا كان المحتوى شيفرة برمجية

  _ChatMessage({required this.content, required this.isUser, this.isCode = false});
}

/// واجهة فقاعة الرسالة التي تدعم تلوين مختلف للرسائل النصية والشفرة.
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = message.isUser ? Colors.blue[200] : (message.isCode ? Colors.grey[850] : Colors.grey[300]);
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = message.isUser
        ? const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12))
        : const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12));

    final textStyle = TextStyle(
      color: message.isCode ? Colors.white : Colors.black87,
      fontFamily: message.isCode ? 'SourceCodePro' : null,
      fontSize: 15,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: radius,
            ),
            child: SelectableText(
              message.content,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}
