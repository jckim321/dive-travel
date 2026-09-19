import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/config/r2_config.dart';
import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_log.dart';
import 'package:dive_travel_app/core/storage/dive_photo_picker.dart';
import 'package:dive_travel_app/core/storage/r2_photo_storage.dart';
import 'package:dive_travel_app/core/theme/app_theme.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

class AddLogScreen extends StatefulWidget {
  const AddLogScreen({super.key, this.existing});

  final DiveLog? existing;

  @override
  State<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends State<AddLogScreen> {
  final _siteController = TextEditingController();
  final _memoController = TextEditingController();
  final _maxDepthController = TextEditingController();
  final _avgDepthController = TextEditingController();
  final _minutesController = TextEditingController();
  final _startBarController = TextEditingController();
  final _endBarController = TextEditingController();
  final _tankController = TextEditingController();
  final _tempController = TextEditingController();
  final _photoPicker = const DivePhotoPicker();
  DateTime _divedAt = DateTime.now();
  bool _saving = false;
  PickedPhoto? _photo;
  DiveMix _mix = DiveMix.air;
  String? _existingPhotoUrl;
  bool _removePhoto = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final log = widget.existing;
    if (log == null) {
      return;
    }
    final profile = log.profile;
    _siteController.text = log.siteName;
    _memoController.text = log.memo;
    _divedAt = log.divedAt;
    _existingPhotoUrl = log.photoUrl;
    _mix = profile?.mix ?? DiveMix.air;
    _maxDepthController.text = _numText(profile?.maxDepthM);
    _avgDepthController.text = _numText(profile?.avgDepthM);
    _minutesController.text = profile?.minutes?.toString() ?? '';
    _startBarController.text = profile?.startBar?.toString() ?? '';
    _endBarController.text = profile?.endBar?.toString() ?? '';
    _tankController.text = _numText(profile?.tankLiters);
    _tempController.text = _numText(profile?.tempC);
  }

  String _numText(double? value) {
    if (value == null) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return '${value.round()}';
    }
    return '$value';
  }

  @override
  void dispose() {
    _siteController.dispose();
    _memoController.dispose();
    _maxDepthController.dispose();
    _avgDepthController.dispose();
    _minutesController.dispose();
    _startBarController.dispose();
    _endBarController.dispose();
    _tankController.dispose();
    _tempController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _divedAt,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_divedAt),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _divedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickPhoto() async {
    final photo = await _photoPicker.pick();
    if (photo == null || !mounted) {
      return;
    }
    setState(() {
      _photo = photo;
      _removePhoto = false;
    });
  }

  Future<void> _useTestPhoto() async {
    final data = await rootBundle.load('assets/images/test_dive_photo.png');
    if (!mounted) {
      return;
    }
    setState(() {
      _photo = PickedPhoto(
        bytes: data.buffer.asUint8List(),
        fileName: 'test_dive_photo.png',
        contentType: 'image/png',
      );
      _removePhoto = false;
    });
  }

  Future<void> _save() async {
    final site = _siteController.text.trim();
    final l10n = AppLocalizations.of(context);
    if (site.isEmpty || _saving) {
      return;
    }
    if (_photo != null && !R2Config.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.logbookPhotoMissingConfig)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final store = DiverStoreScope.of(context);
      final existing = widget.existing;
      if (existing == null) {
        await store.addLog(
          siteName: site,
          divedAt: _divedAt,
          memo: _memoController.text,
          photoBytes: _photo?.bytes,
          photoFileName: _photo?.fileName,
          photoContentType: _photo?.contentType,
          profile: _readProfile(),
        );
      } else {
        await store.updateLog(
          logId: existing.id,
          siteName: site,
          divedAt: _divedAt,
          memo: _memoController.text,
          photoBytes: _photo?.bytes,
          photoFileName: _photo?.fileName,
          photoContentType: _photo?.contentType,
          profile: _readProfile(),
          removePhoto: _removePhoto && _photo == null,
        );
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editing ? l10n.logbookUpdated : l10n.logbookSaved),
        ),
      );
      Navigator.of(context).pop();
    } on R2UploadException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      final message = error.code == 'permission-denied'
          ? 'Firestore 규칙이 로그 쓰기를 막고 있습니다. 콘솔에서 규칙을 게시해 주세요.'
          : '로그 저장 실패: ${error.code}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.logbookSaveFailed} ($error)')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  DiveProfile? _readProfile() {
    double? d(TextEditingController c) => double.tryParse(c.text.trim());
    int? i(TextEditingController c) => int.tryParse(c.text.trim());
    final profile = DiveProfile(
      maxDepthM: d(_maxDepthController),
      avgDepthM: d(_avgDepthController),
      minutes: i(_minutesController),
      startBar: i(_startBarController),
      endBar: i(_endBarController),
      tankLiters: d(_tankController),
      tempC: d(_tempController),
      mix: _mix,
    );
    final empty = profile.maxDepthM == null &&
        profile.avgDepthM == null &&
        profile.minutes == null &&
        profile.startBar == null &&
        profile.endBar == null &&
        profile.tankLiters == null &&
        profile.tempC == null &&
        _mix == DiveMix.air;
    return empty ? null : profile;
  }

  InputDecoration _boxField(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8E1D4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8E1D4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.navy, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateLabel = DateFormat('yyyy.MM.dd HH:mm').format(_divedAt);
    final photo = _photo;
    final preview = _previewLine(l10n);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1F33),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      _editing ? l10n.logbookEdit : l10n.logbookSlipTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('logbook-save-appbar'),
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving ? l10n.logbookUploading : l10n.logbookSave,
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4EE),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0B1F33), Color(0xFF16344A)],
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.goldSoft,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.gold),
                              ),
                              child: Text(
                                _editing ? 'EDIT LOG' : 'NEW LOG',
                                style: TextStyle(
                                  color: AppTheme.navy,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.logbookSelfRegistered,
                                style: const TextStyle(
                                  color: Color(0xFFC5D0D8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        color: AppTheme.goldSoft,
                        child: Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          key: const Key('add-log-scroll'),
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                          children: [
                            Text(
                              l10n.logbookSelfRegisterHint,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.muted,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _siteController,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => setState(() {}),
                              decoration: _boxField(l10n.logbookSiteLabel).copyWith(
                                hintText: '예: 팔라우, 코멜',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: _pickDateTime,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.event,
                                        size: 18,
                                        color: AppTheme.navy,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${l10n.logbookDateLabel}  $dateLabel',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.navy,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              l10n.logbookPhotoSection,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _saving ? null : _pickPhoto,
                                  child: Container(
                                    key: const Key('logbook-photo-card'),
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE8E1D4),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: _photoPreview(photo),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: _saving ? null : _pickPhoto,
                                          child: Text(
                                            l10n.logbookAttachPhoto,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      FilledButton.tonal(
                                        key: const Key('logbook-use-test-photo'),
                                        onPressed:
                                            _saving ? null : _useTestPhoto,
                                        child: Text(l10n.logbookUseTestPhoto),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (photo != null || _hasKeptPhoto)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _saving
                                      ? null
                                      : () => setState(() {
                                            _photo = null;
                                            _removePhoto = true;
                                          }),
                                  child: Text(l10n.logbookPhotoRemove),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _maxDepthController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: _boxField(l10n.logbookMaxDepth),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _avgDepthController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: _boxField(l10n.logbookAvgDepth),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _minutesController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: _boxField(l10n.logbookMinutes),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _tempController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: _boxField(l10n.logbookTemp),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _startBarController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: _boxField(l10n.logbookStartBar),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _endBarController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    decoration: _boxField(l10n.logbookEndBar),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _tankController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                              decoration: _boxField(l10n.logbookTankLiters),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.logbookMix,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.navy,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: [
                                _MixChip(
                                  label: l10n.logbookMixAir,
                                  selected: _mix == DiveMix.air,
                                  onTap: () => setState(() => _mix = DiveMix.air),
                                ),
                                _MixChip(
                                  label: l10n.logbookMixNx32,
                                  selected: _mix == DiveMix.nitrox32,
                                  onTap: () =>
                                      setState(() => _mix = DiveMix.nitrox32),
                                ),
                                _MixChip(
                                  label: l10n.logbookMixNx36,
                                  selected: _mix == DiveMix.nitrox36,
                                  onTap: () =>
                                      setState(() => _mix = DiveMix.nitrox36),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.logbookSacHint,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.muted,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _memoController,
                              maxLines: 2,
                              onChanged: (_) => setState(() {}),
                              decoration: _boxField(l10n.logbookMemoLabel),
                            ),
                            const SizedBox(height: 14),
                            FilledButton(
                              key: const Key('logbook-save'),
                              onPressed: _saving ? null : _save,
                              child: Text(
                                _saving ? l10n.logbookUploading : l10n.logbookSave,
                              ),
                            ),
                          ],
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
    );
  }

  String _previewLine(AppLocalizations l10n) {
    final site = _siteController.text.trim();
    final bits = <String>[
      if (site.isNotEmpty) site else l10n.logbookSiteLabel,
      DateFormat('MM.dd HH:mm').format(_divedAt),
    ];
    final maxD = _maxDepthController.text.trim();
    final mins = _minutesController.text.trim();
    final start = _startBarController.text.trim();
    final end = _endBarController.text.trim();
    if (maxD.isNotEmpty) {
      bits.add('${maxD}m');
    }
    if (mins.isNotEmpty) {
      bits.add('$mins${l10n.logbookMinUnit}');
    }
    bits.add(switch (_mix) {
      DiveMix.air => l10n.logbookMixAir,
      DiveMix.nitrox32 => l10n.logbookMixNx32,
      DiveMix.nitrox36 => l10n.logbookMixNx36,
    });
    if (start.isNotEmpty) {
      bits.add('$start→${end.isEmpty ? '—' : end}');
    }
    return bits.join(' · ');
  }

  bool get _hasKeptPhoto {
    final url = _existingPhotoUrl;
    return !_removePhoto &&
        url != null &&
        url.isNotEmpty &&
        !url.startsWith('memory://');
  }

  Widget _photoPreview(PickedPhoto? photo) {
    if (photo != null) {
      return Image.memory(photo.bytes, fit: BoxFit.cover);
    }
    if (_hasKeptPhoto) {
      return Image.network(_existingPhotoUrl!, fit: BoxFit.cover);
    }
    return const Icon(Icons.add_a_photo_outlined, color: AppTheme.navy);
  }
}

class _MixChip extends StatelessWidget {
  const _MixChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppTheme.goldSoft,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.navy,
      ),
      side: BorderSide(color: selected ? AppTheme.gold : const Color(0xFFE8E1D4)),
    );
  }
}
