// lib/screen/admin/add_edit_material_screen.dart

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
  String _kesulitan = 'mudah'; // Added missing field
  
  List<SubjectModel> _subjects = [];
  String? _selectedSubjectId; // Changed to String ID for better stability
  
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _judulCtrl.text = widget.initial!.judul;
      _kontenCtrl.text = widget.initial!.konten;
      _jenis = widget.initial!.jenis;
      _kesulitan = widget.initial!.kesulitan;
      _selectedSubjectId = widget.initial!.subjectId;
    }
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    // Use the alias we added or getSubjectsOnce
    final subjects = await _fs.getSubjectsOnce(); 
    
    setState(() {
      _subjects = subjects;
      
      // If creating new (no initial data) and subjects exist, default to the first one
      if (widget.initial == null && subjects.isNotEmpty) {
        _selectedSubjectId = subjects.first.id;
      }
      
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    // VALIDATION: Ensure a subject is selected
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih Subject terlebih dahulu')),
      );
      return;
    }

    setState(() => _loading = true);

    final id = widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    final k = KnowledgeModel(
      id: id,
      subjectId: _selectedSubjectId!, // Use the ID variable
      jenis: _jenis,
      kesulitan: _kesulitan, // Added missing field
      judul: _judulCtrl.text.trim(),
      konten: _kontenCtrl.text.trim(),
    );

    try {
      if (widget.initial == null) {
        await _fs.createKnowledge(k);
      } else {
        await _fs.updateKnowledge(k);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _loading = false);
      }
    }
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
                    
                    // SUBJECT DROPDOWN (Using IDs is safer than Objects)
                    DropdownButtonFormField<String>(
                      value: _selectedSubjectId,
                      items: _subjects.map((s) => DropdownMenuItem(
                        value: s.id, 
                        child: Text(s.nama)
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedSubjectId = v),
                      decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                      validator: (v) => v == null ? 'Pilih subject' : null,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // TYPE DROPDOWN
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

                    // DIFFICULTY DROPDOWN (New)
                    DropdownButtonFormField<String>(
                      value: _kesulitan,
                      items: const [
                        DropdownMenuItem(value: 'mudah', child: Text('Mudah')),
                        DropdownMenuItem(value: 'sedang', child: Text('Sedang')),
                        DropdownMenuItem(value: 'sukar', child: Text('Sukar')),
                      ],
                      onChanged: (v) => setState(() => _kesulitan = v ?? _kesulitan),
                      decoration: const InputDecoration(labelText: 'Tingkat Kesulitan', border: OutlineInputBorder()),
                    ),

                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _kontenCtrl,
                      decoration: const InputDecoration(labelText: 'Konten', border: OutlineInputBorder()),
                      maxLines: 8,
                      validator: (v) => v == null || v.isEmpty ? 'Harap isi konten' : null,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _save, 
                      child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Materi')
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}