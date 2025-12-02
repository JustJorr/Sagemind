import 'package:flutter/material.dart';
import '../../models/rule_model.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_services.dart';

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
    if (_subjects.isNotEmpty && !_subjects.any((s) => s.id == _selectedSubjectId)) {
      _selectedSubjectId = _subjects.first.id;
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
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
      appBar: AppBar(title: Text(isEdit ? 'Edit Rule' : 'Tambah Rule')),
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
                      items: _subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.nama))).toList(),
                      onChanged: (v) => setState(() => _selectedSubjectId = v ?? _selectedSubjectId),
                      decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _materialIdCtrl,
                      decoration: const InputDecoration(labelText: 'Material ID (opsional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _kondisiCtrl,
                      decoration: const InputDecoration(labelText: 'Kondisi (trigger)', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Harap isi kondisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _rekomCtrl,
                      decoration: const InputDecoration(labelText: 'Rekomendasi', border: OutlineInputBorder()),
                      maxLines: 4,
                      validator: (v) => v == null || v.isEmpty ? 'Harap isi rekomendasi' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _save, child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Rule')),
                  ],
                ),
              ),
            ),
    );
  }
}
