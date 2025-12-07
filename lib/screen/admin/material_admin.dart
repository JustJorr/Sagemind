import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/knowledge_model.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_services.dart';
import '../../services/supabase_services.dart';
import '../../services/permission_service.dart'; 

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
      if (_selectedSubject != null &&
          _subjects.any((s) => s.id == _selectedSubject!.id)) {
        _selectedSubject = _subjects.firstWhere((s) => s.id == _selectedSubject!.id);
      } else {
        _selectedSubject = _subjects.first;
      }

      await _loadMaterials(_selectedSubject!.id);
    } else {
      _selectedSubject = null;
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
                    value: (_selectedSubject != null &&
                          _subjects.contains(_selectedSubject))
                        ? _selectedSubject
                        : null,
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

//ADD / EDIT MATERIAL SCREEN

class AddEditMaterialScreen extends StatefulWidget {
  final KnowledgeModel? initial;
  const AddEditMaterialScreen({super.key, this.initial});

  @override
  State<AddEditMaterialScreen> createState() => _AddEditMaterialScreenState();
}

class _AddEditMaterialScreenState extends State<AddEditMaterialScreen> {
  final allowedLevels = ['kelas10', 'kelas11', 'kelas12'];
  final _formKey = GlobalKey<FormState>();
  final FirestoreServices _fs = FirestoreServices();

  final TextEditingController _judulCtrl = TextEditingController();
  final TextEditingController _kontenCtrl = TextEditingController();

  String _jenis = 'konseptual';
  String _kesulitan = 'kelas10';

  List<SubjectModel> _subjects = [];
  String? _selectedSubjectId;
  bool _subjectsLoaded = false;

  // Video & Documents
  File? _selectedVideo;
  String? _videoUrl;
  bool _uploadingVideo = false;
  File? _selectedDocument;
  List<Map<String, String>> _uploadedDocuments = [];
  bool _uploadingDocument = false;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await _fs.getSubjectsOnce();

    // Remove duplicates
    final Map<String, SubjectModel> map = {};
    for (var s in subjects) map[s.id] = s;
    final unique = map.values.toList();
    final initialLevel = widget.initial?.kesulitan;

    String? initialId = widget.initial?.subjectId;
    String? correctId;
    if (unique.isEmpty) {
      correctId = null;
    } else if (initialId != null && unique.any((s) => s.id == initialId)) {
      correctId = initialId;
    } else {
      // FIX: if previous ID does NOT exist → reset to first subject
      correctId = unique.first.id;
    }

    setState(() {
      _subjects = unique;
      _selectedSubjectId = correctId; // always valid now

      _judulCtrl.text = widget.initial?.judul ?? "";
      _kontenCtrl.text = widget.initial?.konten ?? "";
      _jenis = widget.initial?.jenis ?? 'konseptual';
      _kesulitan = (initialLevel != null && allowedLevels.contains(initialLevel))
      ? initialLevel
      : 'kelas10';
      _videoUrl = widget.initial?.videoUrl;
      _uploadedDocuments = widget.initial?.documents ?? [];

      _subjectsLoaded = true;
      _loading = false;
    });
  }

  Future<void> _pickVideo() async {
    final permService = PermissionService();
    final allowed = await permService.requestVideoPermission();

    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Izin penyimpanan diperlukan untuk memilih video."),
          ),
        );
      }
      return;
    }

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4'],
        lockParentWindow: true,
      );

      if (picked != null && picked.files.isNotEmpty) {
        setState(() {
          _selectedVideo = File(picked.files.first.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error memilih video: $e")),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    final permService = PermissionService();
    final allowed = await permService.requestFilePermission();

    if (!allowed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Izin penyimpanan diperlukan untuk memilih dokumen."),
          ),
        );
      }
      return;
    }

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (picked != null && picked.files.isNotEmpty) {
        setState(() {
          _selectedDocument = File(picked.files.first.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error memilih dokumen: $e")),
        );
      }
    }
  }

  Future<void> _uploadSelectedDocument() async {
    if (_selectedDocument == null) return;

  final permService = PermissionService();
  final allowed = await permService.requestFilePermission();

  if (!allowed) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Izin penyimpanan diperlukan untuk mengunggah dokumen."),
        ),
      );
    }
    return;
  }

    setState(() => _uploadingDocument = true);

    try {
      final supabase = SupabaseService();
      final fileName = _selectedDocument!.path.split('/').last;
      final url = await supabase.uploadDocument(_selectedDocument!, widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString());

      if (url != null) {
        setState(() {
          _uploadedDocuments.add({'name': fileName, 'url': url});
          _selectedDocument = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Dokumen berhasil diunggah")),
          );
        }
      } else {
        throw Exception('Gagal mengunggah dokumen');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => _uploadingDocument = false);
    }
  }

  Future<void> _removeDocument(int index) async {
    final doc = _uploadedDocuments[index];
    final supabase = SupabaseService();
    
    final success = await supabase.deleteDocument(doc['url']!);
    
    if (success) {
      setState(() {
        _uploadedDocuments.removeAt(index);
      });
    }
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

    // Upload video if selected
    if (_selectedVideo != null) {
      setState(() => _uploadingVideo = true);

      final supabase = SupabaseService();
      final url = await supabase.uploadVideo(_selectedVideo!, id);

      setState(() {
        _videoUrl = url;
        _uploadingVideo = false;
      });
    }

    if (_selectedDocument != null) {
    await _uploadSelectedDocument();
    }

    final k = KnowledgeModel(
      id: id,
      subjectId: _selectedSubjectId!,
      jenis: _jenis,
      kesulitan: _kesulitan,
      judul: _judulCtrl.text.trim(),
      konten: _kontenCtrl.text.trim(),
      videoUrl: _videoUrl,
      documents: _uploadedDocuments.isNotEmpty ? _uploadedDocuments : null,
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
                      value: (_subjectsLoaded &&
                              _selectedSubjectId != null &&
                              _subjects.any((s) => s.id == _selectedSubjectId))
                          ? _selectedSubjectId
                          : null,
                      items: _subjects.map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.nama),
                        ),
                      ).toList(),
                      onChanged: (v) => setState(() => _selectedSubjectId = v),
                      decoration: const InputDecoration(
                        labelText: "Mata Pelajaran",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Pilih mata pelajaran" : null,
                      hint: const Text("Pilih mata pelajaran"),
                      isExpanded: true,
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
                      value: allowedLevels.contains(_kesulitan) ? _kesulitan : 'kelas10',
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
                      onPressed: _pickVideo,
                      child: const Text("Pilih Video (MP4)"),
                    ),

                    if (_selectedVideo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Video dipilih: ${_selectedVideo!.path.split('/').last}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),

                    if (_videoUrl != null && _selectedVideo == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Video sudah diunggah sebelumnya",
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ),

                    if (_uploadingVideo)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text("Mengunggah video..."),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    const Text(
                      'Dokumen Materi (Opsional)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: _pickDocument,
                      child: const Text("Pilih Dokumen (PDF, DOC, DOCX)"),
                    ),

                    if (_selectedDocument != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Dokumen dipilih: ${_selectedDocument!.path.split('/').last}",
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _uploadingDocument ? null : _uploadSelectedDocument,
                              child: const Text("Unggah"),
                            ),
                          ],
                        ),
                      ),

                    if (_uploadingDocument)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),

                    if (_uploadedDocuments.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dokumen yang Diunggah:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ..._uploadedDocuments.asMap().entries.map((e) {
                              final index = e.key;
                              final doc = e.value;
                              
                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.description),
                                  title: Text(doc['name']!),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeDocument(index),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _uploadingVideo || _uploadingDocument ? null : _save,
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

  @override
  void dispose() {
    _judulCtrl.dispose();
    _kontenCtrl.dispose();
    super.dispose();
  }
}