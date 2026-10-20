import 'dart:async';

import 'package:core/components/button/app_button.dart';
import 'package:core/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../model/request_current_response.dart';
import '../utils/document_html_sanitizer.dart';
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
  static const String _scrollChannelName = 'ScrollBridge';
  static final RegExp _htmlTagStart = RegExp(r'<[a-zA-Z/!]');

  late final List<RequestCurrentDocument> _documents;
  late final List<bool> _acceptedByIndex;
  late final List<bool> _reachedEndByIndex;
  late final WebViewController _webViewController;
  int _currentIndex = 0;
  bool _eContractBusy = false;
  Timer? _endCheckTimer;

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
    _reachedEndByIndex = List<bool>.filled(_documents.length, false);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setHorizontalScrollBarEnabled(false)
      ..addJavaScriptChannel(
        _scrollChannelName,
        onMessageReceived: (message) {
          if (message.message != 'end' || !mounted) return;
          if (_reachedEndByIndex[_currentIndex]) return;
          setState(() {
            _reachedEndByIndex[_currentIndex] = true;
          });
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _injectScrollTracking();
          },
        ),
      )
      ..setOnScrollPositionChange((_) => _scheduleEndCheck());
    _loadCurrentDocumentHtml();
  }

  @override
  void dispose() {
    _endCheckTimer?.cancel();
    super.dispose();
  }

  void _scheduleEndCheck() {
    _endCheckTimer?.cancel();
    _endCheckTimer = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      _webViewController.runJavaScript(
        'window.__tanCheckEnd && window.__tanCheckEnd();',
      );
    });
  }

  /// Cleans Word export HTML, then wraps it as a vertical RTL page.
  String _prepareDocumentHtml(String raw) {
    final trimmed = sanitizeDocumentHtml(raw.trim());
    if (trimmed.isEmpty) return _wrapFragment('<p>لا يوجد محتوى</p>');

    final isFullDocument = RegExp(
      r'<html[\s>]',
      caseSensitive: false,
    ).hasMatch(trimmed);
    if (!isFullDocument) return _wrapFragment(trimmed);

    const viewport = '''
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style id="tan-doc-base">
$documentWebViewCss
</style>
''';

    final head = RegExp(r'<head[^>]*>', caseSensitive: false);
    if (head.hasMatch(trimmed)) {
      return trimmed.replaceFirst(head, '<head>$viewport');
    }

    final htmlTag = RegExp(r'<html[^>]*>', caseSensitive: false);
    if (htmlTag.hasMatch(trimmed)) {
      return trimmed.replaceFirstMapped(htmlTag, (match) {
        return '${match.group(0)}<head>$viewport</head>';
      });
    }
    return _wrapFragment(trimmed);
  }

  String _wrapFragment(String fragment) {
    return '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style id="tan-doc-base">
$documentWebViewCss
  </style>
</head>
<body dir="rtl">
$fragment
</body>
</html>
''';
  }

  Future<void> _injectScrollTracking() async {
    await _webViewController.runJavaScript('''
(function() {
  function notify() {
    try { $_scrollChannelName.postMessage('end'); } catch (e) {}
  }

  function checkEnd() {
    try {
      var root = document.scrollingElement || document.documentElement;
      var scrollTop = window.pageYOffset || root.scrollTop || 0;
      var viewport = window.innerHeight || root.clientHeight || 0;
      var fullHeight = root.scrollHeight || 0;
      if (fullHeight > 20 && viewport > 0 &&
          (fullHeight <= viewport + 32 || scrollTop + viewport >= fullHeight - 32)) {
        notify();
        return;
      }

      var nodes = document.body ? document.body.querySelectorAll('*') : [];
      var best = null;
      var bestOverflow = 0;
      for (var i = 0; i < nodes.length; i++) {
        var el = nodes[i];
        if (el.id === 'tan-end-sentinel') continue;
        var overflow = (el.scrollHeight || 0) - (el.clientHeight || 0);
        if (overflow > bestOverflow && el.clientHeight > 80) {
          best = el;
          bestOverflow = overflow;
        }
      }
      if (best && bestOverflow > 48 &&
          best.scrollTop + best.clientHeight >= best.scrollHeight - 32) {
        notify();
      }
    } catch (e) {}
  }

  window.__tanCheckEnd = checkEnd;

  if (!window.__tanScrollTrackingInstalled) {
    window.__tanScrollTrackingInstalled = true;
    document.addEventListener('scroll', checkEnd, { passive: true, capture: true });
    window.addEventListener('scroll', checkEnd, { passive: true });
    window.addEventListener('scrollend', checkEnd, { passive: true });
    window.addEventListener('touchend', function() {
      setTimeout(checkEnd, 60);
    }, { passive: true });
    window.addEventListener('resize', checkEnd);

    if (document.body && !document.getElementById('tan-end-sentinel')) {
      var sentinel = document.createElement('div');
      sentinel.id = 'tan-end-sentinel';
      sentinel.setAttribute('aria-hidden', 'true');
      sentinel.style.cssText = 'display:block;clear:both;height:1px;width:1px;pointer-events:none;';
      document.body.appendChild(sentinel);
      if ('IntersectionObserver' in window) {
        var observer = new IntersectionObserver(function(entries) {
          for (var i = 0; i < entries.length; i++) {
            if (entries[i].isIntersecting) notify();
          }
        }, { root: null, rootMargin: '0px 0px 80px 0px', threshold: 0 });
        observer.observe(sentinel);
      }
    }
  }

  checkEnd();
  setTimeout(checkEnd, 300);
  setTimeout(checkEnd, 800);
})();
''');
  }

  void _loadCurrentDocumentHtml({bool resetAcceptance = true}) {
    if (_documents.isEmpty) return;
    if (resetAcceptance) {
      _reachedEndByIndex[_currentIndex] = false;
      _acceptedByIndex[_currentIndex] = false;
    }

    final currentDoc = _documents[_currentIndex];
    final documentHtml = _prepareDocumentHtml(currentDoc.content ?? '');
    _webViewController.loadHtmlString(documentHtml);
  }

  void _goToPreviousDocument() {
    if (_currentIndex <= 0 || _eContractBusy) return;
    setState(() {
      _currentIndex -= 1;
    });
    _loadCurrentDocumentHtml(resetAcceptance: false);
  }

  bool _handleBackNavigation() {
    if (_eContractBusy) return true;
    if (_currentIndex > 0) {
      _goToPreviousDocument();
      return true;
    }
    return false;
  }

  void _onCheckboxTapped() {
    if (_eContractBusy) return;

    if (!_reachedEndByIndex[_currentIndex]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى قراءة المستند بالكامل حتى النهاية أولاً'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _acceptedByIndex[_currentIndex] = !_acceptedByIndex[_currentIndex];
    });
  }

  Future<void> _onSavePressed() async {
    if (!_reachedEndByIndex[_currentIndex] || !_acceptedByIndex[_currentIndex]) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى قراءة المستند والموافقة على الشروط أولاً'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final isLast = _currentIndex == _documents.length - 1;
    if (!isLast) {
      setState(() {
        _currentIndex += 1;
        _reachedEndByIndex[_currentIndex] = false;
        _acceptedByIndex[_currentIndex] = false;
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
    final hasReachedEnd = _reachedEndByIndex[_currentIndex];
    final isLast = _currentIndex == _documents.length - 1;
    final busyLast = _eContractBusy && isLast;
    final checkboxColor = !hasReachedEnd
        ? AppColors.secondary.withValues(alpha: 0.4)
        : (isAccepted ? AppColors.primary : AppColors.secondary);
    final labelColor = !hasReachedEnd
        ? AppColors.secondary.withValues(alpha: 0.6)
        : AppColors.primary;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope(
        canPop: _currentIndex == 0 && !_eContractBusy,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBackNavigation();
        },
        child: Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.primary,
            leading: BackButton(
              onPressed: () {
                if (_handleBackNavigation()) return;
                Navigator.of(context).maybePop();
              },
            ),
            title: Text('المستند ${_currentIndex + 1} من ${_documents.length}'),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: AppButton(
                title: busyLast
                    ? 'جاري التحقق...'
                    : (isLast ? 'توقيع العقد' : 'التالي'),
                onPressed: (!isAccepted || busyLast) ? null : _onSavePressed,
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
                            color: AppColors.white,
                            border: Border.all(color: AppColors.border1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: WebViewWidget(
                                        controller: _webViewController,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!hasReachedEnd)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'مرر لأسفل حتى نهاية المستند لتفعيل الموافقة',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      GestureDetector(
                        onTap: busyLast ? null : _onCheckboxTapped,
                        child: Opacity(
                          opacity: hasReachedEnd ? 1 : 0.55,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isAccepted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: checkboxColor,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'أوافق على محتوى هذا المستند والشروط الواردة فيه',
                                  style: TextStyle(
                                    color: labelColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
      ),
    );
  }
}
