import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../generated/l10n.dart';
import 'common.dart';

/// Loads a remote PDF with the same authentication policy as the dispatcher.
class PdfPreviewView extends StatefulWidget {
  const PdfPreviewView({super.key, required this.url, required this.headers});

  final String url;
  final Map<String, String> headers;

  @override
  State<PdfPreviewView> createState() => _PdfPreviewViewState();
}

class _PdfPreviewViewState extends State<PdfPreviewView> {
  PdfControllerPinch? _controller;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await Dio().get<List<int>>(
        widget.url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: widget.headers,
        ),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Empty PDF response');
      }
      final controller = PdfControllerPinch(
        document: PdfDocument.openData(Uint8List.fromList(bytes)),
      );
      final previous = _controller;
      _controller = controller;
      previous?.dispose();
    } catch (error) {
      _error = error;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final error = _error;
    if (error != null) {
      return StateMessage(
        icon: Icons.picture_as_pdf_outlined,
        text: errorText(error),
        action: S.of(context).retry,
        onAction: _load,
      );
    }
    final controller = _controller;
    if (controller == null) {
      return StateMessage(
        icon: Icons.picture_as_pdf_outlined,
        text: S.of(context).previewNotSupported,
        action: S.of(context).retry,
        onAction: _load,
      );
    }
    return PdfViewPinch(controller: controller);
  }
}
