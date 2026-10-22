import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_star_assessment.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_dive_star_form_import_screen.dart';
import 'package:dive_travel_app/l10n/generated/app_localizations.dart';

/// Admin audit form: save draft scores, then confirm to write shop grade.
class AdminDiveStarAssessmentScreen extends StatefulWidget {
  const AdminDiveStarAssessmentScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  final String shopId;
  final String shopName;

  @override
  State<AdminDiveStarAssessmentScreen> createState() =>
      _AdminDiveStarAssessmentScreenState();
}

enum _EditorMode { newDraft, editingDraft, confirmedReadonly }

class _CountryGateInput {
  _CountryGateInput()
      : title = TextEditingController(),
        criteria = TextEditingController();

  final TextEditingController title;
  final TextEditingController criteria;
  bool passed = false;

  void dispose() {
    title.dispose();
    criteria.dispose();
  }

  bool get hasContent =>
      title.text.trim().isNotEmpty || criteria.text.trim().isNotEmpty;
}

class _AdminDiveStarAssessmentScreenState
    extends State<AdminDiveStarAssessmentScreen> {
  final _scrollController = ScrollController();

  DiveStarForm? _form;
  List<DiveStarAssessment> _history = const [];
  Object? _loadError;
  bool _loading = true;
  bool _saving = false;
  bool _confirming = false;
  bool _deleting = false;

  /// null = new audit; otherwise the open history record id.
  String? _editingId;
  bool _openedConfirmed = false;

  DiveStarAssessmentType _type = DiveStarAssessmentType.onsite;
  DateTime _reviewedAt = DateTime.now();
  final Map<String, bool> _gates = {};
  final Map<String, TextEditingController> _scoreControllers = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, TextEditingController> _itemScoreControllers = {};
  final Map<String, TextEditingController> _itemCommentControllers = {};
  final Map<String, bool> _areaNa = {};
  final Set<String> _expandedAreas = {};
  final Set<String> _expandedGuidance = {};
  final List<_CountryGateInput> _countryGates = [];
  final _mysteryVisitsController = TextEditingController(text: '0');
  final _auditor1Controller = TextEditingController();
  final _auditor2Controller = TextEditingController();

  DiveStarAssessment? _loadedRecord;
  DiveStarScoreResult? _preview;

  /// Set when opening via「복사해서 새 심사」; used to warn if save date matches.
  DateTime? _copiedFromReviewedAt;

  bool get _v2Ui {
    final form = _form;
    return form != null && form.items.isNotEmpty;
  }

  _EditorMode get _mode {
    if (_editingId == null) {
      return _EditorMode.newDraft;
    }
    if (_openedConfirmed) {
      return _EditorMode.confirmedReadonly;
    }
    return _EditorMode.editingDraft;
  }

  bool get _readOnly => _mode == _EditorMode.confirmedReadonly;

  bool get _canPersist => !_readOnly;

  bool get _inputsEnabled => !_readOnly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mysteryVisitsController.dispose();
    _auditor1Controller.dispose();
    _auditor2Controller.dispose();
    _disposeFormFieldControllers();
    super.dispose();
  }

  void _disposeFormFieldControllers() {
    _gates.clear();
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    _scoreControllers.clear();
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    _commentControllers.clear();
    for (final c in _itemScoreControllers.values) {
      c.dispose();
    }
    _itemScoreControllers.clear();
    for (final c in _itemCommentControllers.values) {
      c.dispose();
    }
    _itemCommentControllers.clear();
    for (final g in _countryGates) {
      g.dispose();
    }
    _countryGates.clear();
    _areaNa.clear();
    _expandedAreas.clear();
    _expandedGuidance.clear();
  }

  void _buildControllersForForm(DiveStarForm form) {
    for (final gate in form.gates) {
      _gates[gate.id] = false;
    }
    for (final area in form.areas) {
      _scoreControllers[area.id] = TextEditingController(text: '0');
      _commentControllers[area.id] = TextEditingController();
      _areaNa[area.id] = false;
      _expandedAreas.add(area.id);
    }
    for (final item in form.items) {
      _itemScoreControllers[item.id] = TextEditingController();
      _itemCommentControllers[item.id] = TextEditingController();
    }
  }

  void _switchToForm(DiveStarForm form) {
    _disposeFormFieldControllers();
    _buildControllersForForm(form);
    _form = form;
  }

  Future<void> _load() async {
    final store = DiverStoreScope.of(context);
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final form = await store.ensureActiveDiveStarForm();
      final history = await store.listDiveStarAssessments(widget.shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _switchToForm(form);
        _history = history;
        _loading = false;
        _recomputePreview();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  bool _isRequiredArea(DiveStarForm form, DiveStarFormArea area) {
    return area.id == form.rules.requiredAreaId ||
        area.id == form.thresholds.safetyAreaId;
  }

  Map<String, int> _readScores(DiveStarForm form) {
    return {
      for (final area in form.areas)
        area.id: (int.tryParse(_scoreControllers[area.id]?.text.trim() ?? '') ??
                0)
            .clamp(0, area.maxPoints),
    };
  }

  Map<String, String> _readComments(DiveStarForm form) {
    return {
      for (final area in form.areas)
        area.id: _commentControllers[area.id]?.text.trim() ?? '',
    };
  }

  Map<String, int> _readItemScores(DiveStarForm form) {
    return {
      for (final item in form.items)
        if (_itemScoreControllers[item.id]?.text.trim().isNotEmpty == true)
          item.id: (int.tryParse(
                      _itemScoreControllers[item.id]?.text.trim() ?? '') ??
                  0)
              .clamp(0, item.maxPoints),
    };
  }

  Map<String, String> _readItemComments(DiveStarForm form) {
    return {
      for (final item in form.items)
        item.id: _itemCommentControllers[item.id]?.text.trim() ?? '',
    };
  }

  Map<String, bool> _readAreaNa(DiveStarForm form) {
    return {
      for (final area in form.areas)
        if (_areaNa[area.id] == true && !_isRequiredArea(form, area))
          area.id: true,
    };
  }

  List<bool> _readCountryGateResults() {
    return [
      for (final gate in _countryGates)
        if (gate.hasContent) gate.passed,
    ];
  }

  List<DiveStarCountryGateAnswer> _readCountryGates() {
    return [
      for (final gate in _countryGates)
        if (gate.hasContent)
          DiveStarCountryGateAnswer(
            title: gate.title.text.trim(),
            criteria: gate.criteria.text.trim(),
            passed: gate.passed,
          ),
    ];
  }

  int _readMysteryVisits() {
    return (int.tryParse(_mysteryVisitsController.text.trim()) ?? 0)
        .clamp(0, 20);
  }

  List<String> _readAuditors() {
    final a1 = _auditor1Controller.text.trim();
    final a2 = _auditor2Controller.text.trim();
    return [
      if (a1.isNotEmpty) a1,
      if (a2.isNotEmpty) a2,
    ];
  }

  void _recomputePreview() {
    final form = _form;
    if (form == null) {
      _preview = null;
      return;
    }
    if (_v2Ui) {
      _preview = DiveStarScoring.evaluate(
        form: form,
        gates: {
          for (final gate in form.gates) gate.id: _gates[gate.id] == true,
        },
        itemScores: _readItemScores(form),
        areaNotApplicable: _readAreaNa(form),
        countryGatesPassed: _readCountryGateResults(),
        mysteryVisits: _readMysteryVisits(),
      );
    } else {
      _preview = DiveStarScoring.evaluate(
        form: form,
        gates: {
          for (final gate in form.gates) gate.id: _gates[gate.id] == true,
        },
        scores: _readScores(form),
      );
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _showFormFallbackSnack(String formVersion) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.adminDiveStarFormMissingForHistory(
            DiveStarForm.versionLabel(formVersion),
          ),
        ),
      ),
    );
  }

  Future<void> _startNew() async {
    final store = DiverStoreScope.of(context);
    try {
      final form = await store.ensureActiveDiveStarForm();
      if (!mounted) {
        return;
      }
      setState(() {
        _switchToForm(form);
        _editingId = null;
        _openedConfirmed = false;
        _loadedRecord = null;
        _copiedFromReviewedAt = null;
        _type = DiveStarAssessmentType.onsite;
        _reviewedAt = diveStarCopyDefaultReviewedAt();
        _mysteryVisitsController.text = '0';
        _auditor1Controller.clear();
        _auditor2Controller.clear();
        _recomputePreview();
      });
      _scrollToTop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _openHistoryAssessment(
    DiveStarAssessment item, {
    required bool asCopy,
  }) async {
    final store = DiverStoreScope.of(context);
    final requestedVersion = item.formVersion.trim();
    DiveStarForm? form;
    if (requestedVersion.isNotEmpty) {
      form = await store.getDiveStarForm(requestedVersion);
    }
    final usedFallback = form == null;
    form ??= await store.ensureActiveDiveStarForm();
    if (!mounted) {
      return;
    }
    if (usedFallback && requestedVersion.isNotEmpty) {
      _showFormFallbackSnack(requestedVersion);
    }
    setState(() {
      _switchToForm(form!);
      if (asCopy) {
        _editingId = null;
        _openedConfirmed = false;
        _loadedRecord = null;
        _copiedFromReviewedAt = item.reviewedAt;
        _reviewedAt = diveStarCopyDefaultReviewedAt();
      } else {
        _editingId = item.id;
        _openedConfirmed = item.confirmed;
        _loadedRecord = item;
        _copiedFromReviewedAt = null;
        _reviewedAt = item.reviewedAt;
      }
      _type = item.type;
      for (final gate in form.gates) {
        _gates[gate.id] = item.gates[gate.id] == true;
      }
      for (final area in form.areas) {
        _scoreControllers[area.id]?.text = '${item.scores[area.id] ?? 0}';
        _commentControllers[area.id]?.text = item.comments[area.id] ?? '';
        _areaNa[area.id] = item.areaNa[area.id] == true;
      }
      for (final formItem in form.items) {
        final score = item.itemScores[formItem.id];
        _itemScoreControllers[formItem.id]?.text =
            score != null ? '$score' : '';
        _itemCommentControllers[formItem.id]?.text =
            item.itemComments[formItem.id] ?? '';
      }
      for (final g in item.countryGates) {
        final input = _CountryGateInput()
          ..title.text = g.title
          ..criteria.text = g.criteria
          ..passed = g.passed;
        _countryGates.add(input);
      }
      _mysteryVisitsController.text = '${item.mysteryVisits}';
      _auditor1Controller.text =
          item.auditors.isNotEmpty ? item.auditors.first : '';
      _auditor2Controller.text =
          item.auditors.length > 1 ? item.auditors[1] : '';
      _recomputePreview();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
  }

  Future<void> _save() async {
    final form = _form;
    if (form == null || _saving || !_canPersist) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final editingId = _editingId;
    final copiedFrom = _copiedFromReviewedAt;
    if (editingId == null &&
        copiedFrom != null &&
        sameDiveStarReviewDay(_reviewedAt, copiedFrom)) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.adminDiveStarCopySameDateTitle),
          content: Text(l10n.adminDiveStarCopySameDateBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.adminHqClose),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.adminDiveStarAssessmentSave),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) {
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final saved = await store.saveDiveStarAssessment(
        shopId: widget.shopId,
        assessmentId: editingId,
        formVersion: form.version,
        type: _type,
        reviewedAt: _reviewedAt,
        gates: {
          for (final gate in form.gates) gate.id: _gates[gate.id] == true,
        },
        scores: _readScores(form),
        comments: _readComments(form),
        itemScores: _readItemScores(form),
        itemComments: _readItemComments(form),
        areaNa: _readAreaNa(form),
        countryGates: _readCountryGates(),
        mysteryVisits: _readMysteryVisits(),
        auditors: _readAuditors(),
      );
      final history = await store.listDiveStarAssessments(widget.shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _editingId = saved.id;
        _openedConfirmed = false;
        _loadedRecord = saved;
        _copiedFromReviewedAt = null;
        _history = history;
        _saving = false;
        _recomputePreview();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editingId == null
                ? l10n.adminDiveStarAssessmentSaved
                : l10n.adminDiveStarAssessmentUpdated,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _confirm(DiveStarAssessment assessment) async {
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (_confirming || assessment.confirmed) {
      return;
    }
    final expiresDefault =
        assessment.reviewedAt.toUtc().add(const Duration(days: 365));
    var expires = expiresDefault;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        final dateFmt = DateFormat.yMMMd();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.adminDiveStarConfirmTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.adminDiveStarConfirmBody(
                      assessment.candidateGrade,
                      assessment.totalScore,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.adminDiveStarExpiresAt),
                    subtitle: Text(dateFmt.format(expires.toLocal())),
                    trailing: const Icon(Icons.event_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expires.toLocal(),
                        firstDate: DateTime(2020),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setDialogState(() => expires = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.adminHqClose),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.adminDiveStarConfirmAction),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _confirming = true);
    try {
      final confirmed = await store.confirmDiveStarAssessment(
        shopId: widget.shopId,
        assessmentId: assessment.id,
        expiresAt: expires,
      );
      final history = await store.listDiveStarAssessments(widget.shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _history = history;
        _loadedRecord = confirmed;
        _editingId = confirmed.id;
        _openedConfirmed = true;
        _confirming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDiveStarConfirmed)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _confirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  Future<void> _deleteDraft() async {
    final id = _editingId;
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    if (id == null || _readOnly || _deleting) {
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.adminDiveStarDeleteConfirmTitle),
        content: Text(l10n.adminDiveStarDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.adminHqClose),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.adminDiveStarDeleteDraft),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await store.deleteDiveStarAssessment(
        shopId: widget.shopId,
        assessmentId: id,
      );
      final history = await store.listDiveStarAssessments(widget.shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _history = history;
        _deleting = false;
      });
      await _startNew();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDiveStarDeleted)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  String _modeLabel(AppLocalizations l10n) {
    return switch (_mode) {
      _EditorMode.newDraft => l10n.adminDiveStarModeNew,
      _EditorMode.editingDraft => l10n.adminDiveStarModeEditing,
      _EditorMode.confirmedReadonly => l10n.adminDiveStarModeReadonly,
    };
  }

  String _typeLabel(AppLocalizations l10n, DiveStarAssessmentType type) {
    return switch (type) {
      DiveStarAssessmentType.mystery => l10n.adminDiveStarTypeMystery,
      DiveStarAssessmentType.document => l10n.adminDiveStarTypeDocument,
      DiveStarAssessmentType.onsite => l10n.adminDiveStarTypeOnsite,
    };
  }

  String _reasonLabel(AppLocalizations l10n, String reason) {
    if (reason == 'gate_failed') {
      return l10n.adminDiveStarReasonGateFailed;
    }
    if (reason == 'below_star1') {
      return l10n.adminDiveStarReasonBelowStar1;
    }
    if (reason == 'star1') {
      return l10n.adminDiveStarReasonStar1;
    }
    if (reason == 'star2') {
      return l10n.adminDiveStarReasonStar2;
    }
    if (reason == 'star3') {
      return l10n.adminDiveStarReasonStar3;
    }
    if (reason.startsWith('safety_ratio_')) {
      return l10n.adminDiveStarReasonSafety;
    }
    if (reason == 'area_ratio_below_star3') {
      return l10n.adminDiveStarReasonAreaRatio;
    }
    if (reason.startsWith('mystery_')) {
      return l10n.adminDiveStarReasonMystery;
    }
    if (reason.isEmpty) {
      return '';
    }
    return l10n.adminDiveStarReasonOther(reason);
  }

  int _areaFilledCount(DiveStarForm form, String areaId) {
    var n = 0;
    for (final item in form.itemsForArea(areaId)) {
      if (_itemScoreControllers[item.id]?.text.trim().isNotEmpty == true) {
        n++;
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat.yMMMd();
    final form = _form;
    final editable = _inputsEnabled;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDiveStarAssessmentTitle),
        actions: [
          IconButton(
            tooltip: l10n.adminDiveStarFormImportMenu,
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AdminDiveStarFormImportScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_loadError',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: Text(l10n.adminDiveStarAssessmentRetry),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(
                      widget.shopName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: _readOnly
                          ? const Color(0xFFE8F5E9)
                          : _mode == _EditorMode.editingDraft
                              ? const Color(0xFFFFF8E1)
                              : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          _modeLabel(l10n),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.adminDiveStarAssessmentHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminConsoleTheme.muted,
                          ),
                    ),
                    if (form != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DiveStarForm.versionLabel(form.version),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _startNew,
                          child: Text(l10n.adminDiveStarStartNew),
                        ),
                        if (_mode == _EditorMode.confirmedReadonly &&
                            _loadedRecord != null)
                          FilledButton.tonal(
                            onPressed: () => _openHistoryAssessment(
                              _loadedRecord!,
                              asCopy: true,
                            ),
                            child: Text(l10n.adminDiveStarCopyAsNew),
                          ),
                        if (_mode == _EditorMode.editingDraft)
                          OutlinedButton(
                            onPressed: _deleting ? null : _deleteDraft,
                            child: Text(l10n.adminDiveStarDeleteDraft),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.adminDiveStarAssessmentFormSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<DiveStarAssessmentType>(
                      key: ValueKey('type-$_type-$_editingId'),
                      initialValue: _type,
                      decoration: InputDecoration(
                        labelText: l10n.adminDiveStarAssessmentType,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: DiveStarAssessmentType.onsite,
                          child: Text(l10n.adminDiveStarTypeOnsite),
                        ),
                        DropdownMenuItem(
                          value: DiveStarAssessmentType.mystery,
                          child: Text(l10n.adminDiveStarTypeMystery),
                        ),
                        DropdownMenuItem(
                          value: DiveStarAssessmentType.document,
                          child: Text(l10n.adminDiveStarTypeDocument),
                        ),
                      ],
                      onChanged: editable
                          ? (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _type = value);
                            }
                          : null,
                    ),
                    if (_v2Ui) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _mysteryVisitsController,
                        enabled: editable,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: l10n.adminDiveStarMysteryVisits,
                        ),
                        onChanged: (_) => setState(_recomputePreview),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _auditor1Controller,
                        enabled: editable,
                        decoration: InputDecoration(
                          labelText: l10n.adminDiveStarAuditor1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _auditor2Controller,
                        enabled: editable,
                        decoration: InputDecoration(
                          labelText: l10n.adminDiveStarAuditor2,
                        ),
                      ),
                    ],
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.adminDiveStarReviewedAt),
                      subtitle: Text(dateFmt.format(_reviewedAt.toLocal())),
                      trailing: editable
                          ? const Icon(Icons.calendar_today_outlined)
                          : null,
                      onTap: editable
                          ? () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _reviewedAt.toLocal(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setState(() => _reviewedAt = picked);
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.adminDiveStarGatesSection,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final gate in form!.gates)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(gate.title),
                        subtitle: Text(
                          _gates[gate.id] == true
                              ? l10n.adminDiveStarGatePass
                              : l10n.adminDiveStarGateFail,
                        ),
                        value: _gates[gate.id] == true,
                        onChanged: editable
                            ? (value) {
                                setState(() {
                                  _gates[gate.id] = value;
                                  _recomputePreview();
                                });
                              }
                            : null,
                      ),
                    if (_v2Ui) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.adminDiveStarCountryGatesSection(
                          form.rules.countryGatesMax,
                        ),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      for (var i = 0; i < _countryGates.length; i++) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _countryGates[i].title,
                          enabled: editable,
                          decoration: InputDecoration(
                            labelText: l10n.adminDiveStarCountryGateName,
                          ),
                          onChanged: (_) => setState(_recomputePreview),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _countryGates[i].criteria,
                          enabled: editable,
                          decoration: InputDecoration(
                            labelText: l10n.adminDiveStarCountryGateCriteria,
                          ),
                          onChanged: (_) => setState(_recomputePreview),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            _countryGates[i].passed
                                ? l10n.adminDiveStarGatePass
                                : l10n.adminDiveStarGateFail,
                          ),
                          value: _countryGates[i].passed,
                          onChanged: editable
                              ? (value) {
                                  setState(() {
                                    _countryGates[i].passed = value;
                                    _recomputePreview();
                                  });
                                }
                              : null,
                        ),
                        if (editable)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(() {
                                  _countryGates[i].dispose();
                                  _countryGates.removeAt(i);
                                  _recomputePreview();
                                });
                              },
                            ),
                          ),
                      ],
                      if (editable &&
                          _countryGates.length < form.rules.countryGatesMax)
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _countryGates.add(_CountryGateInput());
                            });
                          },
                          child: Text(l10n.adminDiveStarCountryGateAdd),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.adminDiveStarItemsSection,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      for (final area in form.areas) ...[
                        const SizedBox(height: 8),
                        _buildAreaExpansion(context, l10n, form, area),
                      ],
                    ] else ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.adminDiveStarAreasSection,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      for (final area in form.areas) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _scoreControllers[area.id],
                          enabled: editable,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: '${area.title} (0–${area.maxPoints})',
                          ),
                          onChanged: editable
                              ? (_) => setState(_recomputePreview)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _commentControllers[area.id],
                          enabled: editable,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: l10n.adminDiveStarAreaComment,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),
                    if (_preview != null) _buildPreviewCard(context, l10n, form),
                    if (_canPersist) ...[
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.adminDiveStarAssessmentSave),
                      ),
                    ],
                    if (_loadedRecord != null &&
                        !_loadedRecord!.confirmed &&
                        _editingId == _loadedRecord!.id) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed:
                            _confirming ? null : () => _confirm(_loadedRecord!),
                        child: Text(l10n.adminDiveStarConfirmAction),
                      ),
                    ],
                    if (_loadedRecord != null && _loadedRecord!.confirmed) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.adminDiveStarAlreadyConfirmed,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AdminConsoleTheme.muted,
                            ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      l10n.adminDiveStarHistorySection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_history.isEmpty)
                      Text(l10n.adminDiveStarHistoryEmpty)
                    else
                      for (final item in _history)
                        Card(
                          color: item.id == _editingId
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.35)
                              : null,
                          child: ListTile(
                            title: Text(
                              l10n.adminDiveStarHistoryLine(
                                dateFmt.format(item.reviewedAt.toLocal()),
                                item.totalScore,
                                item.candidateGrade,
                              ),
                            ),
                            subtitle: Text(
                              [
                                _typeLabel(l10n, item.type),
                                item.confirmed
                                    ? l10n.adminDiveStarStatusConfirmed
                                    : l10n.adminDiveStarStatusDraft,
                                DiveStarForm.versionLabel(item.formVersion),
                              ].join(' · '),
                            ),
                            trailing: item.confirmed
                                ? const Icon(Icons.lock_outline)
                                : IconButton(
                                    tooltip: l10n.adminDiveStarConfirmAction,
                                    icon: const Icon(Icons.verified_outlined),
                                    onPressed: _confirming
                                        ? null
                                        : () => _confirm(item),
                                  ),
                            onTap: () => _openHistoryAssessment(
                              item,
                              asCopy: false,
                            ),
                          ),
                        ),
                  ],
                ),
    );
  }

  Widget _buildAreaExpansion(
    BuildContext context,
    AppLocalizations l10n,
    DiveStarForm form,
    DiveStarFormArea area,
  ) {
    final items = form.itemsForArea(area.id);
    final filled = _areaFilledCount(form, area.id);
    final required = _isRequiredArea(form, area);
    final na = _areaNa[area.id] == true;
    final expanded = _expandedAreas.contains(area.id);
    final canEdit = _inputsEnabled;

    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(area.title),
            subtitle: Text(
              [
                l10n.adminDiveStarAreaProgress(filled, items.length),
                if (na) l10n.adminDiveStarAreaNotApplicable,
              ].join(' · '),
            ),
            trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              setState(() {
                if (expanded) {
                  _expandedAreas.remove(area.id);
                } else {
                  _expandedAreas.add(area.id);
                }
              });
            },
          ),
          if (expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.adminDiveStarAreaApplicable),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.adminDiveStarAreaNotApplicable),
                        enabled: !required,
                      ),
                    ],
                    selected: {na},
                    onSelectionChanged: canEdit
                        ? (sel) {
                            final next = sel.first;
                            if (next && required) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.adminDiveStarAreaNaBlocked),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _areaNa[area.id] = next;
                              _recomputePreview();
                            });
                          }
                        : null,
                  ),
                  if (!na)
                    for (final item in items) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (_itemScoreControllers[item.id]
                              ?.text
                              .trim()
                              .isEmpty ==
                          true)
                        Text(
                          l10n.adminDiveStarItemUnscored,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AdminConsoleTheme.muted,
                                  ),
                        ),
                      TextField(
                        controller: _itemScoreControllers[item.id],
                        enabled: canEdit,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText:
                              l10n.adminDiveStarItemScore(item.maxPoints),
                        ),
                        onChanged: canEdit
                            ? (value) {
                                final parsed = int.tryParse(value);
                                if (parsed != null &&
                                    parsed > item.maxPoints) {
                                  final capped = '${item.maxPoints}';
                                  _itemScoreControllers[item.id]?.text = capped;
                                  _itemScoreControllers[item.id]?.selection =
                                      TextSelection.collapsed(
                                    offset: capped.length,
                                  );
                                }
                                setState(_recomputePreview);
                              }
                            : null,
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _itemCommentControllers[item.id],
                        enabled: canEdit,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.adminDiveStarAreaComment,
                        ),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        initiallyExpanded:
                            _expandedGuidance.contains(item.id),
                        onExpansionChanged: (open) {
                          setState(() {
                            if (open) {
                              _expandedGuidance.add(item.id);
                            } else {
                              _expandedGuidance.remove(item.id);
                            }
                          });
                        },
                        title: Text(
                          l10n.adminDiveStarItemGuidance,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${l10n.adminDiveStarItemCriteria}: '
                              '${item.criteria.isEmpty ? '—' : item.criteria}',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${l10n.adminDiveStarItemEvidence}: '
                              '${item.evidence.isEmpty ? '—' : item.evidence}',
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${l10n.adminDiveStarItemBasis}: '
                              '${item.basis.isEmpty ? '—' : item.basis}',
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewCard(
    BuildContext context,
    AppLocalizations l10n,
    DiveStarForm form,
  ) {
    final preview = _preview!;
    final areaLines = <String>[];
    for (final area in form.areas) {
      if (_readAreaNa(form)[area.id] == true) {
        continue;
      }
      final earned = preview.areaScores[area.id] ?? 0;
      final max = preview.areaMax[area.id] ?? area.maxPoints;
      final pct = max <= 0 ? 0 : ((earned / max) * 100).round();
      areaLines.add(
        l10n.adminDiveStarAreaRateLine(area.title, earned, max, pct),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.adminDiveStarPreview(
                preview.totalScore,
                preview.candidateGrade,
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(_reasonLabel(l10n, preview.reason)),
            if (!preview.gatesPassed)
              Text(l10n.adminDiveStarGatesBlocked)
            else
              Text(l10n.adminDiveStarGatesOk),
            if (areaLines.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final line in areaLines) Text(line),
            ],
          ],
        ),
      ),
    );
  }
}
