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
  static const String _scrollChannelName = 'ScrollBridge';
  static final RegExp _htmlTagStart = RegExp(r'<[a-zA-Z/!]');

  late final List<RequestCurrentDocument> _documents;
  late final List<bool> _acceptedByIndex;
  late final List<bool> _reachedEndByIndex;
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
    _reachedEndByIndex = List<bool>.filled(_documents.length, false);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
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
            _injectDocumentLayoutAndScrollTracking();
          },
        ),
      );
    _loadCurrentDocumentHtml();
  }

  /// Pulls inner body markup when API sends a full HTML document, and strips
  /// embedded styles that would override our mobile layout CSS.
  String _normalizeDocumentHtml(String raw) {
    var html = raw.trim();
    if (html.isEmpty) return '<p>لا يوجد محتوى</p>';

    final lower = html.toLowerCase();
    final bodyOpen = lower.indexOf('<body');
    if (bodyOpen >= 0) {
      final bodyTagEnd = html.indexOf('>', bodyOpen);
      final bodyClose = lower.lastIndexOf('</body>');
      if (bodyTagEnd >= 0) {
        html = bodyClose > bodyTagEnd
            ? html.substring(bodyTagEnd + 1, bodyClose)
            : html.substring(bodyTagEnd + 1);
      }
    }

    html = html.replaceAll(
      RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
      '',
    );
    html = html.replaceAll(
      RegExp(r'<link[^>]*>', caseSensitive: false),
      '',
    );
    // Drop fixed widths / nowrap that force horizontal overflow on mobile.
    html = html.replaceAll(
      RegExp(r'''\swidth\s*=\s*["'][^"']*["']''', caseSensitive: false),
      '',
    );
    html = html.replaceAllMapped(
      RegExp(r'''style\s*=\s*["']([^"']*)["']''', caseSensitive: false),
      (match) {
        final cleaned = match
            .group(1)!
            .replaceAll(
              RegExp(
                r'(?:^|;)\s*(?:width|min-width|max-width|margin-left|margin-right|white-space)\s*:[^;]*',
                caseSensitive: false,
              ),
              '',
            )
            .replaceAll(RegExp(r'^;+|;+$'), '')
            .trim();
        if (cleaned.isEmpty) return '';
        return 'style="$cleaned"';
      },
    );

    return html.trim().isEmpty ? '<p>لا يوجد محتوى</p>' : html.trim();
  }

  Future<void> _injectDocumentLayoutAndScrollTracking() async {
    await _webViewController.runJavaScript('''
(function() {
  function applyDocumentLayout() {
    try {
      document.documentElement.setAttribute('dir', 'rtl');
      document.documentElement.style.overflowX = 'hidden';
      document.body.setAttribute('dir', 'rtl');
      document.body.style.margin = '0';
      document.body.style.padding = '0';
      document.body.style.overflowX = 'hidden';
      document.body.style.direction = 'rtl';
      document.body.style.textAlign = 'right';
      document.body.style.background = '#FFFFFF';

      var pad = document.getElementById('pad');
      if (!pad) {
        pad = document.createElement('td');
        pad.id = 'pad';
        var shell = document.createElement('table');
        shell.id = 'shell';
        var tr = document.createElement('tr');
        while (document.body.firstChild) {
          pad.appendChild(document.body.firstChild);
        }
        tr.appendChild(pad);
        shell.appendChild(tr);
        document.body.appendChild(shell);
      }
      pad.style.padding = '16px';
      pad.style.direction = 'rtl';
      pad.style.textAlign = 'right';
      pad.style.verticalAlign = 'top';
      pad.style.wordWrap = 'break-word';
      pad.style.overflowWrap = 'anywhere';
      pad.style.boxSizing = 'border-box';

      var all = pad.querySelectorAll('*');
      for (var i = 0; i < all.length; i++) {
        var el = all[i];
        if (el.id === 'shell' || el.id === 'pad') continue;
        el.style.maxWidth = '100%';
        el.style.boxSizing = 'border-box';
        el.style.whiteSpace = 'normal';
        el.style.overflowWrap = 'anywhere';
        el.removeAttribute('width');
        if (el.tagName !== 'IMG' && el.tagName !== 'SVG' && el.tagName !== 'CANVAS') {
          el.style.direction = 'rtl';
          el.style.textAlign = 'right';
        }
      }

      var tables = pad.querySelectorAll('table');
      for (var t = 0; t < tables.length; t++) {
        var table = tables[t];
        if (table.id === 'shell') continue;
        table.classList.add('data-table');
        table.removeAttribute('width');
        table.style.width = '100%';
        table.style.maxWidth = '100%';
        table.style.margin = '0 0 10px 0';
        table.style.display = 'block';
        table.setAttribute('dir', 'rtl');

        var rows = table.querySelectorAll('tr');
        var headers = [];
        if (rows.length > 0) {
          var headerCells = rows[0].querySelectorAll('th, td');
          for (var h = 0; h < headerCells.length; h++) {
            headers.push((headerCells[h].innerText || '').trim());
          }
        }

        for (var r = 0; r < rows.length; r++) {
          var row = rows[r];
          row.style.display = 'block';
          row.style.width = '100%';
          row.style.maxWidth = '100%';
          row.style.boxSizing = 'border-box';
          row.style.margin = '0 0 10px 0';
          row.style.border = '1px solid #E5E7EB';
          row.style.borderRadius = '8px';
          row.style.padding = '8px';
          row.style.background = '#FFFFFF';

          var cells = row.querySelectorAll('th, td');
          for (var c = 0; c < cells.length; c++) {
            var cell = cells[c];
            cell.removeAttribute('width');
            cell.style.display = 'block';
            cell.style.width = '100%';
            cell.style.maxWidth = '100%';
            cell.style.boxSizing = 'border-box';
            cell.style.direction = 'rtl';
            cell.style.textAlign = 'right';
            cell.style.whiteSpace = 'normal';
            cell.style.wordBreak = 'normal';
            cell.style.overflowWrap = 'break-word';
            cell.style.padding = '8px';
            cell.style.border = 'none';
            cell.style.borderBottom = '1px solid #F3F4F6';

            if (r === 0 && cell.tagName === 'TH') {
              cell.style.fontWeight = '700';
              cell.style.background = '#F3F4F6';
            } else if (headers[c] && r > 0 && !cell.getAttribute('data-stacked')) {
              cell.setAttribute('data-stacked', '1');
              var label = document.createElement('div');
              label.textContent = headers[c];
              label.style.fontWeight = '700';
              label.style.color = '#6B7280';
              label.style.fontSize = '12px';
              label.style.marginBottom = '4px';
              label.style.textAlign = 'right';
              cell.insertBefore(label, cell.firstChild);
            }
          }
        }
      }

      var media = pad.querySelectorAll('img, video, iframe, svg, canvas');
      for (var m = 0; m < media.length; m++) {
        media[m].style.maxWidth = '100%';
        media[m].style.height = 'auto';
      }
    } catch (e) {}
  }

  applyDocumentLayout();

  function checkEnd() {
    var doc = document.documentElement;
    var body = document.body;
    var scrollTop = window.pageYOffset || doc.scrollTop || body.scrollTop || 0;
    var viewport = window.innerHeight || doc.clientHeight || 0;
    var fullHeight = Math.max(
      body.scrollHeight || 0,
      doc.scrollHeight || 0,
      body.offsetHeight || 0,
      doc.offsetHeight || 0,
      body.clientHeight || 0,
      doc.clientHeight || 0
    );
    if (scrollTop + viewport >= fullHeight - 24) {
      $_scrollChannelName.postMessage('end');
    }
  }

  if (!window.__tanScrollTrackingInstalled) {
    window.__tanScrollTrackingInstalled = true;
    window.addEventListener('scroll', checkEnd, { passive: true });
    window.addEventListener('resize', function() {
      applyDocumentLayout();
      checkEnd();
    });
    document.addEventListener('touchmove', checkEnd, { passive: true });
  }

  setTimeout(function() { applyDocumentLayout(); checkEnd(); }, 50);
  setTimeout(function() { applyDocumentLayout(); checkEnd(); }, 300);
  setTimeout(function() { applyDocumentLayout(); checkEnd(); }, 800);
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
    final bodyHtml = _normalizeDocumentHtml(currentDoc.content ?? '');
    // Platform WebViews often ignore Flutter Padding; bake inset into HTML
    // with a full-width shell cell so text never touches the card edges.
    final wrappedHtml = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    html, body {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow-x: hidden;
      background: #FFFFFF;
      direction: rtl;
      text-align: right;
      -webkit-text-size-adjust: 100%;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
      line-height: 1.6;
      color: #1F2937;
    }
    #shell {
      width: 100%;
      border-collapse: collapse;
      table-layout: fixed;
    }
    #shell > tbody > tr > td#pad {
      padding: 16px !important;
      direction: rtl !important;
      text-align: right !important;
      vertical-align: top;
      word-wrap: break-word;
      overflow-wrap: anywhere;
    }
    #pad, #pad * {
      max-width: 100% !important;
      box-sizing: border-box !important;
      white-space: normal !important;
      direction: rtl !important;
      text-align: right !important;
    }
    #pad img, #pad video, #pad iframe, #pad svg, #pad canvas {
      max-width: 100% !important;
      height: auto !important;
    }
    #pad table.data-table {
      width: 100% !important;
      display: block !important;
      margin: 0 0 10px 0 !important;
    }
    #pad table.data-table, #pad table.data-table thead,
    #pad table.data-table tbody, #pad table.data-table tr,
    #pad table.data-table th, #pad table.data-table td {
      display: block !important;
      width: 100% !important;
      max-width: 100% !important;
      box-sizing: border-box !important;
    }
    #pad table.data-table tr {
      margin: 0 0 10px 0 !important;
      border: 1px solid #E5E7EB !important;
      border-radius: 8px !important;
      padding: 8px !important;
      background: #FFF !important;
    }
    #pad table.data-table th, #pad table.data-table td {
      padding: 8px !important;
      border: none !important;
      border-bottom: 1px solid #F3F4F6 !important;
      word-break: normal !important;
      overflow-wrap: break-word !important;
    }
  </style>
</head>
<body>
  <table id="shell"><tr><td id="pad">
    $bodyHtml
  </td></tr></table>
</body>
</html>
''';
    _webViewController.loadHtmlString(wrappedHtml);
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
