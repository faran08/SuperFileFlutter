import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:xml/xml.dart' as xml;
import '../../core/models/file_item.dart';
import '../../core/state/superfile_state_manager.dart';
import '../../core/theme/superfile_themes.dart';

class DocumentPreviewWidget extends StatefulWidget {
  const DocumentPreviewWidget({super.key});

  @override
  State<DocumentPreviewWidget> createState() => _DocumentPreviewWidgetState();
}

class _DocumentPreviewWidgetState extends State<DocumentPreviewWidget> {
  String? _previewPath;
  String? _extractedText;
  List<String>? _pptxSlidesText;
  String? _pdfPreviewImagePath;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDocumentContent();
  }

  void _loadDocumentContent() {
    final manager = context.watch<SuperfileStateManager>();
    final activePanel = manager.activePanel;
    final item = activePanel?.currentItem;

    if (item == null || item.isDirectory) {
      if (_previewPath != null) {
        setState(() {
          _previewPath = null;
          _extractedText = null;
          _pptxSlidesText = null;
          _pdfPreviewImagePath = null;
        });
      }
      return;
    }

    if (item.path == _previewPath) return;

    _previewPath = item.path;
    _extractedText = null;
    _pptxSlidesText = null;
    _pdfPreviewImagePath = null;

    final ext = item.extension.toLowerCase();
    final mimeType = lookupMimeType(item.path) ?? '';
    final isText = mimeType.startsWith('text/') ||
        ['dart', 'go', 'py', 'js', 'ts', 'json', 'yaml', 'toml', 'md', 'txt', 'html', 'css', 'sh', 'xml', 'log'].contains(ext);

    if (isText && item.size < 1024 * 1024) {
      _isLoading = true;
      File(item.path).readAsString().then((content) {
        if (mounted && _previewPath == item.path) {
          setState(() {
            _extractedText = content.length > 5000 ? content.substring(0, 5000) : content;
            _isLoading = false;
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    } else if (ext == 'docx') {
      _parseDocxFile(item.path);
    } else if (ext == 'pptx') {
      _parsePptxFile(item.path);
    } else if (ext == 'pdf') {
      _generatePdfPreview(item.path);
    }
  }

  void _generatePdfPreview(String pdfPath) async {
    setState(() => _isLoading = true);
    try {
      if (Platform.isMacOS) {
        final tempDir = Directory.systemTemp.path;
        final res = await Process.run('qlmanage', ['-t', '-s', '600', '-o', tempDir, pdfPath]);
        if (res.exitCode == 0) {
          final pngPath = '$tempDir/${pdfPath.split('/').last}.png';
          if (await File(pngPath).exists()) {
            if (mounted && _previewPath == pdfPath) {
              setState(() {
                _pdfPreviewImagePath = pngPath;
                _isLoading = false;
              });
              return;
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _parseDocxFile(String filePath) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? docXmlFile;
      for (final file in archive) {
        if (file.name == 'word/document.xml') {
          docXmlFile = file;
          break;
        }
      }

      if (docXmlFile != null) {
        final xmlString = utf8.decode(docXmlFile.content as List<int>);
        final document = xml.XmlDocument.parse(xmlString);
        final textElements = document.findAllElements('w:t');
        final fullText = textElements.map((e) => e.innerText).join(' ');

        if (mounted) {
          setState(() {
            _extractedText = fullText.isNotEmpty ? fullText : 'Empty DOCX Document';
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _parsePptxFile(String filePath) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      final slideFiles = archive.files
          .where((f) => f.name.startsWith('ppt/slides/slide') && f.name.endsWith('.xml'))
          .toList();

      slideFiles.sort((a, b) => a.name.compareTo(b.name));

      List<String> slidesText = [];
      for (int i = 0; i < slideFiles.length; i++) {
        final slideFile = slideFiles[i];
        final xmlString = utf8.decode(slideFile.content as List<int>);
        final document = xml.XmlDocument.parse(xmlString);
        final textElements = document.findAllElements('a:t');
        final slideText = textElements.map((e) => e.innerText).join(' ');
        slidesText.add('--- Slide ${i + 1} ---\n${slideText.isNotEmpty ? slideText : "[No Text Content]"}');
      }

      if (mounted) {
        setState(() {
          _pptxSlidesText = slidesText;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SuperfileStateManager>();
    final theme = manager.getEffectiveTheme(context);
    final activePanel = manager.activePanel;
    final item = activePanel?.currentItem;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: theme.filePanelBg,
        border: Border(
          left: BorderSide(color: theme.sidebarBorder, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.sidebarBg,
              border: Border(
                bottom: BorderSide(color: theme.filePanelBorder, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility_rounded, size: 16, color: theme.filePanelTopPath),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'DOCUMENT VIEW',
                    style: TextStyle(
                      color: theme.filePanelTopPath,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item != null && !item.isDirectory)
                  InkWell(
                    onTap: () => SuperfileStateManager.openFileWithDefaultApp(item.path),
                    child: Icon(Icons.open_in_new_rounded, size: 14, color: theme.hint),
                  ),
              ],
            ),
          ),

          Expanded(
            child: item == null || item.isDirectory
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 48, color: theme.filePanelFg.withValues(alpha: 0.2)),
                        const SizedBox(height: 8),
                        Text(
                          'Select a document to view',
                          style: TextStyle(
                            color: theme.filePanelFg.withValues(alpha: 0.4),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildDocumentContent(item, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentContent(FileItem item, SuperfileTheme theme) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: theme.hint),
        ),
      );
    }

    final ext = item.extension.toLowerCase();
    final mimeType = lookupMimeType(item.path) ?? '';

    // 1. PDF Document View
    if (ext == 'pdf') {
      if (_pdfPreviewImagePath != null) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(_pdfPreviewImagePath!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(Icons.picture_as_pdf_rounded, size: 64, color: Colors.redAccent),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name,
                style: TextStyle(
                  color: theme.filePanelFg,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              item.name,
              style: TextStyle(
                color: theme.filePanelFg,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'PDF Document',
              style: TextStyle(
                color: theme.filePanelFg.withValues(alpha: 0.6),
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.modalConfirmBg,
                foregroundColor: theme.modalConfirmFg,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              onPressed: () => SuperfileStateManager.openFileWithDefaultApp(item.path),
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('Open PDF Document', style: TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // 2. Image View
    if (mimeType.startsWith('image/')) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.file(
              File(item.path),
              cacheWidth: 300,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.broken_image_rounded, color: theme.error, size: 48),
            ),
          ),
        ),
      );
    }

    // 3. PPTX Presentation View (Slide by Slide Text Content)
    if (_pptxSlidesText != null && _pptxSlidesText!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: ListView.separated(
          itemCount: _pptxSlidesText!.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.sidebarBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: theme.sidebarBorder),
              ),
              child: Text(
                _pptxSlidesText![index],
                style: TextStyle(
                  color: theme.filePanelFg,
                  fontSize: 10,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
              ),
            );
          },
        ),
      );
    }

    // 4. Text & DOCX Extracted Content
    if (_extractedText != null) {
      return Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.sidebarBg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: SingleChildScrollView(
          child: Text(
            _extractedText!,
            style: TextStyle(
              color: theme.filePanelFg.withValues(alpha: 0.9),
              fontSize: 10,
              fontFamily: 'monospace',
              height: 1.35,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        'No Preview Available',
        style: TextStyle(
          color: theme.filePanelFg.withValues(alpha: 0.3),
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
