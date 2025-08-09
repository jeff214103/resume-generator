import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdfWidget extends StatefulWidget {
  final String content;
  final String? fileName;
  final String? title;
  final bool isPaid;
  final int maxPages;
  final bool isModifiable; // New parameter

  const PdfWidget({
    super.key,
    required this.content,
    this.fileName,
    this.title,
    this.isPaid = true,
    this.maxPages = 2,
    this.isModifiable = true, // Default to true
  });

  @override
  State<PdfWidget> createState() => _PdfWidgetState();
}

class _PdfWidgetState extends State<PdfWidget> {
  // State from PDFPlaceholderEditor
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _replacements = {};
  bool _hasPlaceholders = false;

  final ScrollController _placeholderScrollController = ScrollController();

  // State from original PdfWidget
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    if (widget.isModifiable) {
      _initializePlaceholders();
      _loadSavedReplacements();
    }
  }

  @override
  void didUpdateWidget(PdfWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content && widget.isModifiable) {
      _initializePlaceholders();
    }
  }

  // --- Placeholder Methods (from PDFPlaceholderEditor) ---

  Future<void> _loadSavedReplacements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _controllers.keys) {
        final String saved = prefs.getString(key) ?? key;
        _replacements[key] = saved;
        _controllers[key]!.text = saved;
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading saved replacements: $e');
    }
  }

  Future<void> _saveReplacements(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('Error saving replacements: $e');
    }
  }

  void _initializePlaceholders() {
    final placeholderRegex = RegExp(r'\[([^\[\]]+)\]');
    final matches = placeholderRegex.allMatches(widget.content);
    final placeholders = matches.map((m) => m.group(1)!.trim()).toSet();

    setState(() {
      _hasPlaceholders = placeholders.isNotEmpty;

      // Initialize controllers for new placeholders
      for (final placeholder in placeholders) {
        if (!_controllers.containsKey(placeholder)) {
          _controllers[placeholder] = TextEditingController(
            text: _replacements[placeholder] ?? '',
          )..addListener(() {
              final text = _controllers[placeholder]!.text;
              _replacements[placeholder] = text;
              _saveReplacements(placeholder, text);
              setState(() {});
            });
        }
      }

      // Remove controllers for placeholders that no longer exist
      _controllers.removeWhere((key, _) => !placeholders.contains(key));
    });
  }

  String _getProcessedContent() {
    if (!widget.isModifiable) {
      return widget.content;
    }
    String result = widget.content;
    _replacements.forEach((key, value) {
      result = result.replaceAll('[$key]', value);
    });
    return result;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    // Get the processed content with replacements
    final processedContent = _getProcessedContent();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf),
              const SizedBox(width: 8),
              Text(
                '${(widget.title != null) ? '${widget.title}' : ''} - PDF Preview',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Integrated Placeholder Editor UI ---
          if (widget.isModifiable && _hasPlaceholders)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 60,
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _placeholderScrollController,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 10),
                      child: ListView(
                        controller: _placeholderScrollController,
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: _controllers.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.only(
                                left: 2, right: 2, bottom: 2),
                            width: 200,
                            child: TextField(
                              controller: entry.value,
                              decoration: InputDecoration(
                                labelText: entry.key,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (_) {
                                // setState is called by the controller's listener
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 20),
              ],
            ),

          // --- PDF Preview Area ---
          Container(
            width: double.infinity,
            height: 300,
            constraints: const BoxConstraints(minHeight: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              child: SelectionArea(
                child: MarkdownBody(
                  data: processedContent, // Use processed content here
                  styleSheet: MarkdownStyleSheet(
                    h1: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.primary),
                    code: TextStyle(
                        fontFamily: 'monospace',
                        color: Theme.of(context).colorScheme.onSurface),
                    codeblockDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generatePdf,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(
                  _isGenerating ? 'Generating...' : 'Generate & Download PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PDF Generation Methods (Unchanged, but now use processed content) ---

  Future<void> _generatePdf() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final contentToRender =
          _getProcessedContent(); // Use processed content for PDF
      pw.Document pdf = pw.Document();

      double scaleFactor = 1.0;
      int numberOfPages;

      List<pw.Widget> allContent;
      List<double> contentHeights;
      List<bool> canBreakBefore;

      double minScale = 0.5;
      double maxScale = 1.0;
      double optimalScale = 1.0;

      // First, try with maximum scale
      pdf = pw.Document();
      Map<String, dynamic> contentResult =
          _buildMarkdownContent(contentToRender, maxScale);
      allContent = contentResult['widgets'] as List<pw.Widget>;
      contentHeights = contentResult['heights'] as List<double>;
      canBreakBefore = contentResult['canBreakBefore'] as List<bool>;
      numberOfPages = _createPagesWithContent(
          allContent, contentHeights, canBreakBefore, pdf);

      if (numberOfPages <= widget.maxPages) {
        optimalScale = maxScale;
      } else {
        // Binary search to find the optimal scale factor
        while (maxScale - minScale > 0.0001) {
          double midScale = (minScale + maxScale) / 2;
          pdf = pw.Document();
          Map<String, dynamic> contentResult =
              _buildMarkdownContent(contentToRender, midScale);
          allContent = contentResult['widgets'] as List<pw.Widget>;
          contentHeights = contentResult['heights'] as List<double>;
          canBreakBefore = contentResult['canBreakBefore'] as List<bool>;
          numberOfPages = _createPagesWithContent(
              allContent, contentHeights, canBreakBefore, pdf);

          if (numberOfPages <= widget.maxPages) {
            optimalScale = midScale;
            minScale = midScale;
          } else {
            maxScale = midScale;
          }
        }
        if (numberOfPages > widget.maxPages) {
          optimalScale = minScale;
        }
        // Final check with the optimal scale
        pdf = pw.Document();
        Map<String, dynamic> contentResult =
            _buildMarkdownContent(contentToRender, optimalScale);
        allContent = contentResult['widgets'] as List<pw.Widget>;
        contentHeights = contentResult['heights'] as List<double>;
        canBreakBefore = contentResult['canBreakBefore'] as List<bool>;
        numberOfPages = _createPagesWithContent(
            allContent, contentHeights, canBreakBefore, pdf);
      }

      final pdfBytes = await pdf.save();
      setState(() {
        _isGenerating = false;
      });
      _downloadPdfBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(numberOfPages > widget.maxPages
                ? 'PDF generated with $numberOfPages pages (exceeds ${widget.maxPages} page limit)'
                : 'PDF generated and downloaded successfully!'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  int _createPagesWithContent(List<pw.Widget> allContent,
      List<double> contentHeights, List<bool> canBreakBefore, pw.Document pdf) {
    const double pageHeight = 595.0 - 64; // A4 height minus margins
    const double titleHeight = 38; // Title + spacing
    const double footerHeight = 50; // Footer for free users

    List<pw.Widget> currentPageContent = [];
    List<double> currentPageHeights = [];
    double currentHeight = 0;
    int pageIndex = 0;

    for (int i = 0; i < allContent.length; i++) {
      final widget = allContent[i];
      final widgetHeight = contentHeights[i];
      final canBreak = canBreakBefore[i];

      // Calculate available height for current page
      double availableHeight = pageHeight;
      if (!this.widget.isPaid) {
        availableHeight -= footerHeight;
      }

      // Check if widget fits on current page
      if (currentHeight + widgetHeight > availableHeight &&
          currentPageContent.isNotEmpty) {
        // Check if we can break before this widget
        if (canBreak) {
          // Create current page and start new one
          _addPageToDocument(currentPageContent, pageIndex, pdf);
          pageIndex++;
          currentPageContent = [];
          currentPageHeights = [];
          currentHeight = 0;
        }
        // If we can't break, continue adding to current page (will overflow)
      }

      // Add widget to current page
      currentPageContent.add(widget);
      currentPageHeights.add(widgetHeight);
      currentHeight += widgetHeight;
    }

    // Add the last page if it has content
    if (currentPageContent.isNotEmpty) {
      _addPageToDocument(currentPageContent, pageIndex, pdf);
      pageIndex++;
    }

    return pageIndex;
  }

  void _addPageToDocument(
      List<pw.Widget> pageContent, int pageIndex, pw.Document pdf) {
    final pageWidgets = <pw.Widget>[];
    // Add content
    pageWidgets.addAll(pageContent);

    // Add footer if needed
    if (!widget.isPaid) {
      pageWidgets.add(pw.Spacer());
      pageWidgets.add(pw.Divider());
      pageWidgets.add(pw.SizedBox(height: 10));
      pageWidgets.add(
        pw.Text(
          'Generated on: ${DateTime.now().toString().split('.')[0]} by ITDOGTICS (resume.itdogtics.com)',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey,
          ),
        ),
      );
    }

    // Add page to document
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: pageWidgets,
        ),
      ),
    );
  }

  // Helper method to estimate height based on font size
  double _estimateHeightForFontSize(double fontSize) {
    return fontSize * 1.3;
  }

  Map<String, dynamic> _buildMarkdownContent(String markdownContent,
      [double scaleFactor = 1.0]) {
    final List<pw.Widget> widgets = [];
    final List<double> heights = [];
    final List<bool> canBreakBefore = [];
    final lines = markdownContent.trim().split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.isEmpty) {
        final spacingWidget = pw.SizedBox(height: 8 * scaleFactor);
        widgets.add(spacingWidget);
        heights.add(8 * scaleFactor);
        canBreakBefore.add(true);
        continue;
      }

      // Determine if we can break before this line
      bool canBreak = _canBreakBeforeLine(line);
      canBreakBefore.add(canBreak);

      // Handle headers with regex
      final headerMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        final text = headerMatch.group(2)!.trim();
        final headerFontSize = (24 - (level * 2)) * scaleFactor;
        final headerWidget = pw.Text(
          _sanitizeText(text),
          style: pw.TextStyle(
            fontSize: headerFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        );
        widgets.add(headerWidget);
        heights.add(_estimateHeightForFontSize(headerFontSize));

        // Add spacing after header
        final spacingWidget = pw.SizedBox(height: 8 * scaleFactor);
        widgets.add(spacingWidget);
        heights.add(8 * scaleFactor);
        canBreakBefore.add(false); // Can't break before spacing
        continue;
      }

      // Handle bullet points with regex
      final bulletMatch = RegExp(r'^[-*]\s+(.+)$').firstMatch(line);
      if (bulletMatch != null) {
        final text = bulletMatch.group(1)!.trim();
        final bulletFontSize = 12 * scaleFactor;
        final bulletWidget = pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '* ',
              style: pw.TextStyle(fontSize: bulletFontSize),
            ),
            pw.Expanded(
              child: _parseInlineFormatting(text, scaleFactor),
            ),
          ],
        );
        widgets.add(bulletWidget);
        heights.add(_estimateHeightForFontSize(bulletFontSize));

        // Add spacing after bullet point
        final spacingWidget = pw.SizedBox(height: 4 * scaleFactor);
        widgets.add(spacingWidget);
        heights.add(4 * scaleFactor);
        canBreakBefore.add(false); // Can't break before spacing
        continue;
      }

      // Handle numbered lists with regex
      final numberedMatch = RegExp(r'^\d+\.\s+(.+)$').firstMatch(line);
      if (numberedMatch != null) {
        final text = numberedMatch.group(1)!.trim();
        final numberedFontSize = 12 * scaleFactor;
        final numberedWidget = pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${widgets.where((w) => w.runtimeType == pw.Row).length + 1}. ',
              style: pw.TextStyle(fontSize: numberedFontSize),
            ),
            pw.Expanded(
              child: _parseInlineFormatting(text, scaleFactor),
            ),
          ],
        );
        widgets.add(numberedWidget);
        heights.add(_estimateHeightForFontSize(numberedFontSize));

        // Add spacing after numbered item
        final spacingWidget = pw.SizedBox(height: 4 * scaleFactor);
        widgets.add(spacingWidget);
        heights.add(4 * scaleFactor);
        canBreakBefore.add(false); // Can't break before spacing
        continue;
      }

      // Handle regular text with inline formatting
      final textFontSize = 12 * scaleFactor;
      final textWidget = _parseInlineFormatting(line, scaleFactor);
      widgets.add(textWidget);
      heights.add(_estimateHeightForFontSize(textFontSize));

      // Add spacing after regular text
      final spacingWidget = pw.SizedBox(height: 8 * scaleFactor);
      widgets.add(spacingWidget);
      heights.add(8 * scaleFactor);
      canBreakBefore.add(false); // Can't break before spacing
    }

    return {
      'widgets': widgets,
      'heights': heights,
      'canBreakBefore': canBreakBefore,
    };
  }

  bool _canBreakBeforeLine(String line) {
    // Can break before lines that contain markdown formatting that encapsulates the entire text
    // Examples: "*abc*", "** hi **", "# Header"
    // Not: "- ** abc **", "*abc*123", "text **bold** text", "- item", "1. item"

    // Check for headers (lines starting with #)
    if (RegExp(r'^#{1,6}\s+').hasMatch(line)) {
      return true;
    }

    // Check for lines that are entirely bold or italic
    // Remove leading/trailing whitespace for comparison
    final trimmedLine = line.trim();

    // Check if entire line is bold (wrapped in **)
    if (RegExp(r'^\*\*.*\*\*$').hasMatch(trimmedLine)) {
      return true;
    }

    // Check if entire line is italic (wrapped in *)
    if (RegExp(r'^\*[^*]+\*$').hasMatch(trimmedLine)) {
      return true;
    }

    return false;
  }

  pw.Widget _parseInlineFormatting(String text, [double scaleFactor = 1.0]) {
    // Use RichText to handle inline formatting with proper text wrapping
    final List<pw.TextSpan> spans = [];

    // Pattern to match **bold**, *italic*, or regular text
    final pattern = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|[^*\n]+)');
    final matches = pattern.allMatches(text);

    for (final match in matches) {
      final matchedText = match.group(0)!;

      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        // Bold text
        final boldText = matchedText.substring(2, matchedText.length - 2);
        spans.add(
          pw.TextSpan(
            text: _sanitizeText(boldText),
            style: pw.TextStyle(
              fontSize: 13 * scaleFactor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        );
      } else if (matchedText.startsWith('*') &&
          matchedText.endsWith('*') &&
          matchedText.length > 2) {
        // Italic text
        final italicText = matchedText.substring(1, matchedText.length - 1);
        spans.add(
          pw.TextSpan(
            text: _sanitizeText(italicText),
            style: pw.TextStyle(
              fontSize: 12 * scaleFactor,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        );
      } else {
        // Regular text
        spans.add(
          pw.TextSpan(
            text: _sanitizeText(matchedText),
            style: pw.TextStyle(
              fontSize: 12 * scaleFactor,
            ),
          ),
        );
      }
    }

    if (spans.isEmpty) {
      // Fallback for empty text
      return pw.Text(
        _sanitizeText(text),
        style: pw.TextStyle(fontSize: 12 * scaleFactor),
      );
    }

    // Use RichText for proper text wrapping with inline formatting
    return pw.RichText(
      text: pw.TextSpan(
        children: spans,
        style: pw.TextStyle(
          fontSize: 12 * scaleFactor,
        ),
      ),
    );
  }

  String _sanitizeText(String text) {
    // Replace problematic Unicode characters with safe alternatives
    return text
        .replaceAll('–', '-') // Replace en-dash with regular hyphen
        .replaceAll('—', '-') // Replace em-dash with regular hyphen
        .replaceAll('…', '...') // Replace ellipsis with three dots
        .replaceAll('"', '"') // Replace smart quotes with regular quotes
        .replaceAll('"', '"')
        .replaceAll(
            ''', "'") // Replace smart apostrophes with regular apostrophe
        .replaceAll(''', "'")
        .replaceAll('•', '-') // Replace bullet with asterisk
        .replaceAll('·', '-') // Replace middle dot with asterisk
        .replaceAll('‣', '*') // Replace triangular bullet with asterisk
        .replaceAll('◦', '*') // Replace white bullet with asterisk
        .replaceAll('▪', '*') // Replace black square with asterisk
        .replaceAll('▫', '*') // Replace white square with asterisk
        .replaceAll('→', '->') // Replace arrow with dash and greater than
        .replaceAll('←', '<-') // Replace left arrow with less than and dash
        .replaceAll(
            '⇒', '=>') // Replace double arrow with equals and greater than
        .replaceAll(
            '⇐', '<=') // Replace double left arrow with less than and equals
        .replaceAll('©', '(c)') // Replace copyright symbol
        .replaceAll('®', '(R)') // Replace registered trademark
        .replaceAll('™', '(TM)') // Replace trademark
        .replaceAll('±', '+/-') // Replace plus-minus
        .replaceAll('×', 'x') // Replace multiplication sign
        .replaceAll('÷', '/') // Replace division sign
        .replaceAll('≤', '<=') // Replace less than or equal
        .replaceAll('≥', '>=') // Replace greater than or equal
        .replaceAll('≠', '!=') // Replace not equal
        .replaceAll('≈', '~') // Replace approximately equal
        .replaceAll('∞', 'infinity') // Replace infinity symbol
        .replaceAll('°', ' degrees') // Replace degree symbol
        .replaceAll('€', 'EUR') // Replace euro symbol
        .replaceAll('£', 'GBP') // Replace pound symbol
        .replaceAll('¥', 'JPY') // Replace yen symbol
        .replaceAll('¢', 'cents') // Replace cent symbol
        .replaceAll('§', 'Section') // Replace section symbol
        .replaceAll('¶', 'Paragraph') // Replace paragraph symbol
        .replaceAll('†', 'dagger') // Replace dagger
        .replaceAll('‡', 'double dagger') // Replace double dagger
        .replaceAll('‰', 'per mille') // Replace per mille
        .replaceAll('‱', 'per ten thousand') // Replace per ten thousand
        .replaceAll('′', "'") // Replace prime
        .replaceAll('″', '"') // Replace double prime
        .replaceAll('‴', "'''") // Replace triple prime
        .replaceAll('⁗', "''''") // Replace quadruple prime
        .replaceAll('⁰', '0') // Replace superscript zero
        .replaceAll('¹', '1') // Replace superscript one
        .replaceAll('²', '2') // Replace superscript two
        .replaceAll('³', '3') // Replace superscript three
        .replaceAll('⁴', '4') // Replace superscript four
        .replaceAll('⁵', '5') // Replace superscript five
        .replaceAll('⁶', '6') // Replace superscript six
        .replaceAll('⁷', '7') // Replace superscript seven
        .replaceAll('⁸', '8') // Replace superscript eight
        .replaceAll('⁹', '9') // Replace superscript nine
        .replaceAll('₀', '0') // Replace subscript zero
        .replaceAll('₁', '1') // Replace subscript one
        .replaceAll('₂', '2') // Replace subscript two
        .replaceAll('₃', '3') // Replace subscript three
        .replaceAll('₄', '4') // Replace subscript four
        .replaceAll('₅', '5') // Replace subscript five
        .replaceAll('₆', '6') // Replace subscript six
        .replaceAll('₇', '7') // Replace subscript seven
        .replaceAll('₈', '8') // Replace subscript eight
        .replaceAll('₉', '9') // Replace subscript nine
        .replaceAll('α', 'alpha') // Replace Greek alpha
        .replaceAll('β', 'beta') // Replace Greek beta
        .replaceAll('γ', 'gamma') // Replace Greek gamma
        .replaceAll('δ', 'delta') // Replace Greek delta
        .replaceAll('ε', 'epsilon') // Replace Greek epsilon
        .replaceAll('ζ', 'zeta') // Replace Greek zeta
        .replaceAll('η', 'eta') // Replace Greek eta
        .replaceAll('θ', 'theta') // Replace Greek theta
        .replaceAll('ι', 'iota') // Replace Greek iota
        .replaceAll('κ', 'kappa') // Replace Greek kappa
        .replaceAll('λ', 'lambda') // Replace Greek lambda
        .replaceAll('μ', 'mu') // Replace Greek mu
        .replaceAll('ν', 'nu') // Replace Greek nu
        .replaceAll('ξ', 'xi') // Replace Greek xi
        .replaceAll('ο', 'omicron') // Replace Greek omicron
        .replaceAll('π', 'pi') // Replace Greek pi
        .replaceAll('ρ', 'rho') // Replace Greek rho
        .replaceAll('σ', 'sigma') // Replace Greek sigma
        .replaceAll('τ', 'tau') // Replace Greek tau
        .replaceAll('υ', 'upsilon') // Replace Greek upsilon
        .replaceAll('φ', 'phi') // Replace Greek phi
        .replaceAll('χ', 'chi') // Replace Greek chi
        .replaceAll('ψ', 'psi') // Replace Greek psi
        .replaceAll('ω', 'omega'); // Replace Greek omega
  }

  void _downloadPdfBytes(Uint8List pdfBytes) {
    final fileName = widget.fileName ??
        'document_${DateTime.now().millisecondsSinceEpoch}.pdf';

    // Create blob and download link for web
    final blob = html.Blob([pdfBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();

    // Clean up the URL object
    html.Url.revokeObjectUrl(url);
  }
}
