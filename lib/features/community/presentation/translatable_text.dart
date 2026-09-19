import 'package:flutter/material.dart';

import 'package:dive_travel_app/core/i18n/translation_engine.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class TranslatableText extends StatefulWidget {
  const TranslatableText({
    super.key,
    required this.text,
    this.language,
    this.style,
    this.maxLines,
  });

  final String text;
  final String? language;
  final TextStyle? style;
  final int? maxLines;

  @override
  State<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends State<TranslatableText> {
  static final _engine = GoogleStyleTranslationEngine();
  String? _translated;
  var _loading = false;
  var _showingTranslation = false;

  String get _target {
    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (device.isNotEmpty) {
      return device;
    }
    return Localizations.localeOf(context).languageCode;
  }

  bool get _needsButton => LanguageDetector.needsTranslation(
        text: widget.text,
        targetLanguage: _target,
        storedLanguage: widget.language,
      );

  Future<void> _toggle() async {
    if (_showingTranslation) {
      setState(() => _showingTranslation = false);
      return;
    }
    if (_translated != null) {
      setState(() => _showingTranslation = true);
      return;
    }
    setState(() => _loading = true);
    final source = (widget.language ?? '').trim().isEmpty
        ? LanguageDetector.detect(widget.text)
        : widget.language!;
    final result = await _engine.translate(
      text: widget.text,
      sourceLanguage: source,
      targetLanguage: _target,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _translated = result;
      _showingTranslation = true;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final body = _showingTranslation ? (_translated ?? widget.text) : widget.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(body, style: widget.style, maxLines: widget.maxLines),
        if (_needsButton) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            key: const Key('translate-toggle'),
            onPressed: _loading ? null : _toggle,
            icon: Icon(
              _showingTranslation ? Icons.translate_outlined : Icons.language_outlined,
              size: 18,
            ),
            label: Text(
              _loading
                  ? l10n.translateLoading
                  : _showingTranslation
                      ? l10n.translateShowOriginal
                      : l10n.translateAction,
            ),
          ),
        ],
      ],
    );
  }
}
