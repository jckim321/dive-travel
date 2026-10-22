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

class _AdminDiveStarAssessmentScreenState
    extends State<AdminDiveStarAssessmentScreen> {
  DiveStarForm? _form;
  List<DiveStarAssessment> _history = const [];
  Object? _loadError;
  bool _loading = true;
  bool _saving = false;
  bool _confirming = false;

  DiveStarAssessmentType _type = DiveStarAssessmentType.onsite;
  DateTime _reviewedAt = DateTime.now();
  final Map<String, bool> _gates = {};
  final Map<String, TextEditingController> _scoreControllers = {};
  final Map<String, TextEditingController> _commentControllers = {};

  DiveStarAssessment? _lastSaved;
  DiveStarScoreResult? _preview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
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

  Future<void> _save() async {
    final form = _form;
    if (form == null || _saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final store = DiverStoreScope.of(context);
    setState(() => _saving = true);
    try {
      final saved = await store.saveDiveStarAssessment(
        shopId: widget.shopId,
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
        _lastSaved = saved;
        _history = history;
        _saving = false;
        _recomputePreview();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminDiveStarAssessmentSaved)),
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
    if (_confirming) {
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
      await store.confirmDiveStarAssessment(
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
        _lastSaved = history.where((item) => item.id == assessment.id).firstOrNull ??
            _lastSaved?.copyWith(confirmed: true);
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

  void _fillFromAssessment(DiveStarAssessment item) {
    final form = _form;
    if (form == null) {
      return;
    }
    setState(() {
      _type = item.type;
      _reviewedAt = item.reviewedAt;
      for (final gate in form.gates) {
        _gates[gate.id] = item.gates[gate.id] == true;
      }
      for (final area in form.areas) {
        _scoreControllers[area.id]?.text = '${item.scores[area.id] ?? 0}';
        _commentControllers[area.id]?.text = item.comments[area.id] ?? '';
      }
      _lastSaved = item;
      _recomputePreview();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFmt = DateFormat.yMMMd();

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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Text(
                      widget.shopName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.adminDiveStarAssessmentHint,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AdminConsoleTheme.muted,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.adminDiveStarAssessmentFormSection,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<DiveStarAssessmentType>(
                      key: ValueKey(_type),
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
                      onChanged: (value) {
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
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _reviewedAt.toLocal(),
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
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
                    for (final gate in _form!.gates)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(gate.title),
                        subtitle: Text(
                          _gates[gate.id] == true
                              ? l10n.adminDiveStarGatePass
                              : l10n.adminDiveStarGateFail,
                        ),
                        value: _gates[gate.id] == true,
                        onChanged: (value) {
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
                    for (final area in _form!.areas) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _scoreControllers[area.id],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText:
                              '${area.title} (0–${area.maxPoints})',
                        ),
                        onChanged: (_) => setState(_recomputePreview),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _commentControllers[area.id],
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
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.adminDiveStarAssessmentSave),
                    ),
                    if (_lastSaved != null) ...[
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _confirming || _lastSaved!.confirmed
                            ? null
                            : () => _confirm(_lastSaved!),
                        child: Text(
                          _lastSaved!.confirmed
                              ? l10n.adminDiveStarAlreadyConfirmed
                              : l10n.adminDiveStarConfirmAction,
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
                                ? const Icon(Icons.check_circle_outline)
                                : IconButton(
                                    tooltip: l10n.adminDiveStarConfirmAction,
                                    icon: const Icon(Icons.verified_outlined),
                                    onPressed: _confirming
                                        ? null
                                        : () => _confirm(item),
                                  ),
                            onTap: () => _fillFromAssessment(item),
                          ),
                        ),
                  ],
                ),
    );
  }
}
