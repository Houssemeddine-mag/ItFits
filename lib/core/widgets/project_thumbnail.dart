import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Renders a project image without janking the list.
///
/// Old code called `base64Decode` synchronously in `build()` for 1-2MB
/// inline data URLs — every card scrolled decoded megabytes on the UI
/// thread. This decodes once off-thread and memoizes per URL.
class ProjectThumbnail extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double placeholderIconSize;

  const ProjectThumbnail({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.placeholderIconSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final cs = Theme.of(context).colorScheme;
    if (url == null || url.isEmpty) {
      return _Placeholder(iconSize: placeholderIconSize);
    }
    if (url.startsWith('data:image')) {
      return _DataUrlImage(url: url, fit: fit);
    }
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: cs.surfaceContainerHighest,
          child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => _Placeholder(iconSize: placeholderIconSize),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double iconSize;
  const _Placeholder({required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer,
      child: Icon(Icons.home_rounded, color: cs.primary, size: iconSize),
    );
  }
}

class _DataUrlImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  const _DataUrlImage({required this.url, required this.fit});

  @override
  State<_DataUrlImage> createState() => _DataUrlImageState();
}

class _DataUrlImageState extends State<_DataUrlImage> {
  Future<Uint8List?>? _future;
  String? _resolvedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _DataUrlImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _resolve();
  }

  void _resolve() {
    if (_resolvedFor == widget.url && _future != null) return;
    _resolvedFor = widget.url;
    _future = _decodeOffThread(widget.url);
  }

  static Future<Uint8List?> _decodeOffThread(String url) async {
    try {
      final comma = url.indexOf(',');
      if (comma < 0) return null;
      final b64 = url.substring(comma + 1);
      return await Isolate.run(() {
        try {
          return base64Decode(b64);
        } catch (_) {
          return null;
        }
      });
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            color: cs.surfaceContainerHighest,
            child: const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) {
          return Container(
            color: cs.surfaceContainerHighest,
            child: const Center(
                child: Icon(Icons.image_not_supported_rounded, size: 40)),
          );
        }
        return Image.memory(bytes, fit: widget.fit, gaplessPlayback: true);
      },
    );
  }
}
