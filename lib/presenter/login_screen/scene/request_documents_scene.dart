import 'package:core/components/button/app_button.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../model/request_current_response.dart';
import '../utils/e_contract_otp_helper.dart';

class RequestDocumentsScene extends StatefulWidget {
  final dynamic requestId;
  final List<RequestCurrentDocument> documents;

  const RequestDocumentsScene({
    super.key,
    required this.requestId,
    required this.documents,
  });

  @override
  State<RequestDocumentsScene> createState() => _RequestDocumentsSceneState();
}

class _RequestDocumentsSceneState extends State<RequestDocumentsScene> {
  static final RegExp _htmlTagStart = RegExp(r'<[a-zA-Z/!]');

  late final List<RequestCurrentDocument> _documents;
  late final List<bool> _acceptedByIndex;
  late final WebViewController _webViewController;
  int _currentIndex = 0;
  bool _eContractBusy = false;

  /// API may send [RequestCurrentDocument.title] as plain text or as HTML (e.g. `<br/>` between languages).
  bool _titleLooksLikeHtml(String s) => _htmlTagStart.hasMatch(s);

  String _titleForDisplay(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return '';
    if (!_titleLooksLikeHtml(s)) return s;

    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(
      RegExp(r'</(p|div|h[1-6]|section|article|li)\s*>', caseSensitive: false),
      '\n',
    );
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return s.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  @override
  void initState() {
    super.initState();
    _documents = [...widget.documents]..sort((a, b) => a.order.compareTo(b.order));
    _acceptedByIndex = List<bool>.filled(_documents.length, false);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);
    _loadCurrentDocumentHtml();
  }

  void _loadCurrentDocumentHtml() {
    if (_documents.isEmpty) return;
    final currentDoc = _documents[_currentIndex];
    final raw = (currentDoc.content ?? '').trim();
    final wrappedHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif; padding: 12px; line-height: 1.4; color: #1F2937; }
  </style>
</head>
<body>
  ${raw.isEmpty ? '<p>لا يوجد محتوى</p>' : raw}
</body>
</html>
''';
    _webViewController.loadHtmlString(wrappedHtml);
  }

  Future<void> _onSavePressed() async {
    if (!_acceptedByIndex[_currentIndex]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى الموافقة على الشروط أولاً'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final isLast = _currentIndex == _documents.length - 1;
    if (!isLast) {
      setState(() {
        _currentIndex += 1;
      });
      _loadCurrentDocumentHtml();
      return;
    }

    setState(() {
      _eContractBusy = true;
    });
    try {
      if (!mounted) return;
      await EContractOtpHelper.run(
        context,
        widget.requestId,
      );
    } finally {
      if (mounted) {
        setState(() {
          _eContractBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_documents.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            title: const Text('المستندات'),
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.primary,
          ),
          body: const Center(
            child: Text('لا توجد مستندات متاحة حالياً'),
          ),
        ),
      );
    }

    final document = _documents[_currentIndex];
    final isAccepted = _acceptedByIndex[_currentIndex];
    final isLast = _currentIndex == _documents.length - 1;
    final busyLast = _eContractBusy && isLast;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          title: Text('المستند ${_currentIndex + 1} من ${_documents.length}'),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: AppButton(
              title: busyLast
                  ? 'جاري التحقق...'
                  : (isLast ? 'حفظ وإنهاء' : 'التالي'),
              onPressed: busyLast ? null : _onSavePressed,
            ),
          ),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text(
                  _titleForDisplay(document.title),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: WebViewWidget(controller: _webViewController),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _acceptedByIndex[_currentIndex] = !isAccepted;
                    });
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isAccepted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isAccepted ? AppColors.primary : AppColors.secondary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'أوافق على محتوى هذا المستند والشروط الواردة فيه',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                  ],
                ),
              ),
            ),
            if (busyLast)
              Positioned.fill(
                child: AbsorbPointer(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
