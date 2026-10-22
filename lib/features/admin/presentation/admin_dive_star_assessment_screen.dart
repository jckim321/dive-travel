import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:dive_travel_app/core/data/diver_store.dart';
import 'package:dive_travel_app/core/models/dive_star_assessment.dart';
import 'package:dive_travel_app/features/admin/presentation/admin_console_theme.dart';
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

  DiveStarAssessment? _loadedRecord;
  DiveStarScoreResult? _preview;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _scoreControllers.values) {
      c.dispose();
    }
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
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
      _applyForm(form);
      setState(() {
        _form = form;
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

  void _applyForm(DiveStarForm form) {
    for (final gate in form.gates) {
      _gates.putIfAbsent(gate.id, () => false);
    }
    for (final area in form.areas) {
      _scoreControllers.putIfAbsent(
        area.id,
        () => TextEditingController(text: '0'),
      );
      _commentControllers.putIfAbsent(
        area.id,
        () => TextEditingController(),
      );
    }
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

  void _recomputePreview() {
    final form = _form;
    if (form == null) {
      _preview = null;
      return;
    }
    _preview = DiveStarScoring.evaluate(
      form: form,
      gates: {
        for (final gate in form.gates) gate.id: _gates[gate.id] == true,
      },
      scores: _readScores(form),
    );
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

  void _resetBlankForm() {
    final form = _form;
    if (form == null) {
      return;
    }
    setState(() {
      _editingId = null;
      _openedConfirmed = false;
      _loadedRecord = null;
      _type = DiveStarAssessmentType.onsite;
      _reviewedAt = DateTime.now();
      for (final gate in form.gates) {
        _gates[gate.id] = false;
      }
      for (final area in form.areas) {
        _scoreControllers[area.id]?.text = '0';
        _commentControllers[area.id]?.text = '';
      }
      _recomputePreview();
    });
    _scrollToTop();
  }

  void _fillFromAssessment(DiveStarAssessment item, {required bool asCopy}) {
    final form = _form;
    if (form == null) {
      return;
    }
    setState(() {
      if (asCopy) {
        _editingId = null;
        _openedConfirmed = false;
        _loadedRecord = null;
      } else {
        _editingId = item.id;
        _openedConfirmed = item.confirmed;
        _loadedRecord = item;
      }
      _type = item.type;
      _reviewedAt = item.reviewedAt;
      for (final gate in form.gates) {
        _gates[gate.id] = item.gates[gate.id] == true;
      }
      for (final area in form.areas) {
        _scoreControllers[area.id]?.text = '${item.scores[area.id] ?? 0}';
        _commentControllers[area.id]?.text = item.comments[area.id] ?? '';
      }
      _recomputePreview();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
  }

  Future<void> _save() async {
    final form = _form;
    if (form == null || _saving || _readOnly) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    final editingId = _editingId;
    setState(() => _saving = true);
    try {
      final saved = await store.saveDiveStarAssessment(
        shopId: widget.shopId,
        assessmentId: editingId,
        type: _type,
        reviewedAt: _reviewedAt,
        gates: {
          for (final gate in form.gates) gate.id: _gates[gate.id] == true,
        },
        scores: _readScores(form),
        comments: _readComments(form),
      );
      final history = await store.listDiveStarAssessments(widget.shopId);
      if (!mounted) {
        return;
      }
      setState(() {
        _editingId = saved.id;
        _openedConfirmed = false;
        _loadedRecord = saved;
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
      _resetBlankForm();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat.yMMMd();
    final form = _form;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDiveStarAssessmentTitle),
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
                        Text('$_loadError'),
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
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: _resetBlankForm,
                          child: Text(l10n.adminDiveStarStartNew),
                        ),
                        if (_mode == _EditorMode.confirmedReadonly &&
                            _loadedRecord != null)
                          FilledButton.tonal(
                            onPressed: () => _fillFromAssessment(
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
                      ],
                      onChanged: _readOnly
                          ? null
                          : (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() => _type = value);
                            },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.adminDiveStarReviewedAt),
                      subtitle: Text(dateFmt.format(_reviewedAt.toLocal())),
                      trailing: _readOnly
                          ? null
                          : const Icon(Icons.calendar_today_outlined),
                      onTap: _readOnly
                          ? null
                          : () async {
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
                            },
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
                        onChanged: _readOnly
                            ? null
                            : (value) {
                                setState(() {
                                  _gates[gate.id] = value;
                                  _recomputePreview();
                                });
                              },
                      ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.adminDiveStarAreasSection,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final area in form.areas) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _scoreControllers[area.id],
                        enabled: !_readOnly,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: '${area.title} (0–${area.maxPoints})',
                        ),
                        onChanged: _readOnly
                            ? null
                            : (_) => setState(_recomputePreview),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _commentControllers[area.id],
                        enabled: !_readOnly,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: l10n.adminDiveStarAreaComment,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_preview != null)
                      Card(
                        child: ListTile(
                          title: Text(
                            l10n.adminDiveStarPreview(
                              _preview!.totalScore,
                              _preview!.candidateGrade,
                            ),
                          ),
                          subtitle: Text(
                            _preview!.gatesPassed
                                ? l10n.adminDiveStarGatesOk
                                : l10n.adminDiveStarGatesBlocked,
                          ),
                        ),
                      ),
                    if (!_readOnly) ...[
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
                                item.type == DiveStarAssessmentType.mystery
                                    ? l10n.adminDiveStarTypeMystery
                                    : l10n.adminDiveStarTypeOnsite,
                                item.confirmed
                                    ? l10n.adminDiveStarStatusConfirmed
                                    : l10n.adminDiveStarStatusDraft,
                                'v${item.formVersion}',
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
                            onTap: () =>
                                _fillFromAssessment(item, asCopy: false),
                          ),
                        ),
                  ],
                ),
    );
  }
}
