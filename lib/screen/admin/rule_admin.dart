import 'package:flutter/material.dart';
import '../../models/rule_model.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_services.dart';

/// -----------------------------------------------------------
///  RULE LIST SCREEN
/// -----------------------------------------------------------
class AdminRuleScreen extends StatefulWidget {
  const AdminRuleScreen({super.key});

  @override
  State<AdminRuleScreen> createState() => _AdminRuleScreenState();
}

class _AdminRuleScreenState extends State<AdminRuleScreen> {
  final FirestoreServices _fs = FirestoreServices();
  List<RuleModel> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _rules = await _fs.getAllRules();
    setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    await _fs.deleteRule(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Rules')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditRuleScreen()),
          );
          await _load();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? const Center(child: Text('No rules yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rules.length,
                  itemBuilder: (context, i) {
                    final r = _rules[i];
                    return Card(
                      child: ListTile(
                        title: Text(r.kondisi),
                        subtitle: Text(r.rekomendasi),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddEditRuleScreen(initial: r),
                                  ),
                                );
                                await _load();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Hapus Rule?'),
                                    content: const Text(
                                        'Yakin ingin menghapus rule ini?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Batal')),
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Hapus')),
                                    ],
                                  ),
                                );
                                if (ok == true) await _delete(r.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// -----------------------------------------------------------
///  ADD / EDIT RULE SCREEN
/// -----------------------------------------------------------
class AddEditRuleScreen extends StatefulWidget {
  final RuleModel? initial;
  const AddEditRuleScreen({super.key, this.initial});

  @override
  State<AddEditRuleScreen> createState() => _AddEditRuleScreenState();
}

class _AddEditRuleScreenState extends State<AddEditRuleScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreServices _fs = FirestoreServices();

  final TextEditingController _kondisiCtrl = TextEditingController();
  final TextEditingController _rekomCtrl = TextEditingController();
  final TextEditingController _materialIdCtrl = TextEditingController();

  List<SubjectModel> _subjects = [];
  String _selectedSubjectId = 'matematika';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _kondisiCtrl.text = widget.initial!.kondisi;
      _rekomCtrl.text = widget.initial!.rekomendasi;
      _materialIdCtrl.text = widget.initial!.materialId;
      _selectedSubjectId = widget.initial!.subjectId;
    }
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    _subjects = await _fs.getSubjectsOnce();
    if (_subjects.isNotEmpty &&
        !_subjects.any((s) => s.id == _selectedSubjectId)) {
      _selectedSubjectId = _subjects.first.id;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.initial?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final r = RuleModel(
      id: id,
      subjectId: _selectedSubjectId,
      kondisi: _kondisiCtrl.text.trim(),
      rekomendasi: _rekomCtrl.text.trim(),
      materialId: _materialIdCtrl.text.trim(),
    );

    if (widget.initial == null) {
      await _fs.createRule(r);
    } else {
      await _fs.updateRule(r);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Rule" : "Tambah Rule")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedSubjectId,
                      items: _subjects
                          .map((s) =>
                              DropdownMenuItem(value: s.id, child: Text(s.nama)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedSubjectId = v ?? _selectedSubjectId),
                      decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _materialIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Material ID (opsional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _kondisiCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kondisi (trigger)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Harap isi kondisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _rekomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Rekomendasi',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Harap isi rekomendasi' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Rule'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
