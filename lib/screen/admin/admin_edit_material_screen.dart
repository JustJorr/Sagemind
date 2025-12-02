import 'package:flutter/material.dart';
import '../../models/knowledge_model.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_services.dart';

class AddEditMaterialScreen extends StatefulWidget {
  final KnowledgeModel? initial;
  const AddEditMaterialScreen({super.key, this.initial});

  @override
  State<AddEditMaterialScreen> createState() => _AddEditMaterialScreenState();
}

class _AddEditMaterialScreenState extends State<AddEditMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreServices _fs = FirestoreServices();

  final TextEditingController _judulCtrl = TextEditingController();
  final TextEditingController _kontenCtrl = TextEditingController();
  String _jenis = 'konseptual';
  List<SubjectModel> _subjects = [];
  SubjectModel? _selectedSubject;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _judulCtrl.text = widget.initial!.judul;
      _kontenCtrl.text = widget.initial!.konten;
      _jenis = widget.initial!.jenis;
    }
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    _subjects = await _fs.getSubjectsOnce();
    if (widget.initial != null) {
      _selectedSubject = _subjects
      .where((s) => s.id == widget.initial!.subjectId)
      .cast<SubjectModel?>()
      .firstWhere(
        (s) => s != null,
        orElse: () => null,
      );
} else {
  _selectedSubject = _subjects.isNotEmpty ? _subjects.first : null;
}

    setState(() => _loading = false);
  } 

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final subjectId = _selectedSubject?.id ?? '';
    final k = KnowledgeModel(
      id: id,
      subjectId: subjectId,
      jenis: _jenis,
      judul: _judulCtrl.text.trim(),
      konten: _kontenCtrl.text.trim(),
    );
    if (widget.initial == null) {
      await _fs.createKnowledge(k);
    } else {
      await _fs.updateKnowledge(k);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Materi' : 'Tambah Materi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _judulCtrl,
                      decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Harap isi judul' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SubjectModel>(
                      value: _selectedSubject,
                      items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.nama))).toList(),
                      onChanged: (v) => setState(() => _selectedSubject = v),
                      decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _jenis,
                      items: const [
                        DropdownMenuItem(value: 'konseptual', child: Text('Konseptual')),
                        DropdownMenuItem(value: 'prosedural', child: Text('Prosedural')),
                        DropdownMenuItem(value: 'metakognitif', child: Text('Metakognitif')),
                      ],
                      onChanged: (v) => setState(() => _jenis = v ?? _jenis),
                      decoration: const InputDecoration(labelText: 'Jenis Materi', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _kontenCtrl,
                      decoration: const InputDecoration(labelText: 'Konten', border: OutlineInputBorder()),
                      maxLines: 8,
                      validator: (v) => v == null || v.isEmpty ? 'Harap isi konten' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _save, child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Materi')),
                  ],
                ),
              ),
            ),
    );
  }
}
