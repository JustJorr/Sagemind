import 'package:flutter/material.dart';
import '../../models/knowledge_model.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_services.dart';

class AdminMaterialScreen extends StatefulWidget {
  const AdminMaterialScreen({super.key});

  @override
  State<AdminMaterialScreen> createState() => _AdminMaterialScreenState();
}

class _AdminMaterialScreenState extends State<AdminMaterialScreen> {
  final FirestoreServices _fs = FirestoreServices();

  List<SubjectModel> _subjects = [];
  SubjectModel? _selectedSubject;

  List<KnowledgeModel> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _loading = true);

    _subjects = await _fs.getSubjectsOnce();

    if (_subjects.isNotEmpty) {
      _selectedSubject = _subjects.first;
      await _loadMaterials(_selectedSubject!.id);
    } else {
      _materials = [];
    }

    setState(() => _loading = false);
  }

  Future<void> _loadMaterials(String subjectId) async {
    setState(() => _loading = true);
    _materials = await _fs.getKnowledgeBySubject(subjectId);
    setState(() => _loading = false);
  }

  Future<void> _deleteMaterial(String id) async {
    await _fs.deleteKnowledge(id);
    if (_selectedSubject != null) {
      await _loadMaterials(_selectedSubject!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Materi")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditMaterialScreen()),
          );
          if (_selectedSubject != null) {
            await _loadMaterials(_selectedSubject!.id);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField<SubjectModel>(
                    value: _selectedSubject,
                    items: _subjects
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.nama)))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedSubject = v;
                        _materials = [];
                      });
                      if (v != null) _loadMaterials(v.id);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Filter berdasarkan Mata Pelajaran',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: _materials.isEmpty
                        ? const Center(child: Text('Belum ada materi.'))
                        : ListView.builder(
                            itemCount: _materials.length,
                            itemBuilder: (_, i) {
                              final m = _materials[i];

                              return Card(
                                child: ListTile(
                                  title: Text(m.judul),
                                  subtitle: Text(
                                      '${m.jenis} • Kesulitan: ${m.kesulitan}'),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/material/detail',
                                    arguments: m,
                                  ),
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
                                                  AddEditMaterialScreen(
                                                      initial: m),
                                            ),
                                          );
                                          if (_selectedSubject != null) {
                                            await _loadMaterials(
                                                _selectedSubject!.id);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title:
                                                  const Text('Hapus Materi?'),
                                              content: const Text(
                                                  'Yakin ingin menghapus materi ini?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Batal'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Hapus'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (ok == true) {
                                            await _deleteMaterial(m.id);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                  )
                ],
              ),
            ),
    );
  }
}

// -------------------------------------------------------------
//                ADD / EDIT MATERIAL SCREEN
// -------------------------------------------------------------

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
  String _kesulitan = 'kelas10';

  List<SubjectModel> _subjects = [];
  String? _selectedSubjectId;

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
    final subjects = await _fs.getSubjectsOnce();
    setState(() {
      _subjects = subjects;
      if (widget.initial == null && subjects.isNotEmpty) {
        _selectedSubjectId = subjects.first.id;
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap pilih mata pelajaran.")),
      );
      return;
    }

    setState(() => _loading = true);

    final id = widget.initial?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final k = KnowledgeModel(
      id: id,
      subjectId: _selectedSubjectId!,
      jenis: _jenis,
      kesulitan: _kesulitan,
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Scaffold(
      appBar:
          AppBar(title: Text(isEdit ? "Edit Materi" : "Tambah Materi Baru")),
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
                      decoration: const InputDecoration(
                        labelText: "Judul Materi",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Harap isi judul." : null,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedSubjectId,
                      items: _subjects
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.nama),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSubjectId = v),
                      decoration: const InputDecoration(
                        labelText: "Mata Pelajaran",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _jenis,
                      items: const [
                        DropdownMenuItem(
                            value: 'konseptual', child: Text('Konseptual')),
                        DropdownMenuItem(
                            value: 'prosedural', child: Text('Prosedural')),
                        DropdownMenuItem(
                            value: 'metakognitif', child: Text('Metakognitif')),
                      ],
                      onChanged: (v) => setState(() => _jenis = v!),
                      decoration: const InputDecoration(
                        labelText: "Jenis Materi",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _kesulitan,
                      items: const [
                        DropdownMenuItem(value: 'kelas10', child: Text('Kelas 10')),
                        DropdownMenuItem(value: 'kelas11', child: Text('Kelas 11')),
                        DropdownMenuItem(value: 'kelas12', child: Text('Kelas 12')),
                      ],
                      onChanged: (v) => setState(() => _kesulitan = v!),
                      decoration: const InputDecoration(
                        labelText: "Tingkat Kelas",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _kontenCtrl,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: "Konten Materi",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Harap isi konten." : null,
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEdit ? "Simpan Perubahan" : "Buat Materi"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
