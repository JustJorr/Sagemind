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
      appBar: AppBar(
        title: const Text("Kelola Materi"),
        centerTitle: true,
        elevation: 0,
      ),
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
              padding: const EdgeInsets.all(16),
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
                    decoration: InputDecoration(
                      labelText: 'Filter berdasarkan Mata Pelajaran',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _materials.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada materi.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _materials.length,
                            itemBuilder: (_, i) {
                              final m = _materials[i];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 1,
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.description_outlined,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  title: Text(
                                    m.judul,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(m.jenis),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(m.kesulitan),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text("Sunting"),
                                        onTap: () async {
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
                                      PopupMenuItem(
                                        child: const Text(
                                          "Hapus",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onTap: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Hapus Materi?'),
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
  final SupabaseService _supabase = SupabaseService();

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

    final Map<String, SubjectModel> map = {};
    for (var s in subjects) map[s.id] = s;
    final unique = map.values.toList();

    String? initialId = widget.initial?.subjectId;
    String? correctId;
    if (unique.isEmpty) {
      correctId = null;
    } else if (initialId != null && unique.any((s) => s.id == initialId)) {
      correctId = initialId;
    } else {
      correctId = unique.first.id;
    }

    setState(() {
      _subjects = unique;
      _selectedSubjectId = correctId;

      _judulCtrl.text = widget.initial?.judul ?? "";
      _kontenCtrl.text = widget.initial?.konten ?? "";
      _jenis = widget.initial?.jenis ?? 'konseptual';
      final initialLevel = widget.initial?.kesulitan;
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
      _showError("Izin penyimpanan diperlukan untuk memilih video.");
      return;
    }

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4'],
        lockParentWindow: true,
      );

      if (picked != null && picked.files.isNotEmpty) {
        setState(() => _selectedVideo = File(picked.files.first.path!));
      }
    } catch (e) {
      _showError("Kesalahan memilih video: $e");
    }
  }

  Future<void> _pickDocument() async {
    final permService = PermissionService();
    final allowed = await permService.requestFilePermission();

    if (!allowed) {
      _showError("Izin penyimpanan diperlukan untuk memilih dokumen.");
      return;
    }

    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (picked != null && picked.files.isNotEmpty) {
        setState(() => _selectedDocument = File(picked.files.first.path!));
      }
    } catch (e) {
      _showError("Kesalahan memilih dokumen: $e");
    }
  }

  Future<void> _uploadSelectedDocument() async {
    if (_selectedDocument == null) return;

    final permService = PermissionService();
    final allowed = await permService.requestFilePermission();

    if (!allowed) {
      _showError("Izin penyimpanan diperlukan untuk mengunggah dokumen.");
      return;
    }

    setState(() => _uploadingDocument = true);

    try {
      final fileName = _selectedDocument!.path.split('/').last;
      final materialId = widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      print('[MATERIAL] Starting document upload...');
      final url = await _supabase.uploadDocument(_selectedDocument!, materialId);

      if (url != null && url.isNotEmpty) {
        print('[MATERIAL] Document URL received: $url');
        setState(() {
          _uploadedDocuments.add({'name': fileName, 'url': url});
          _selectedDocument = null;
        });
        _showSuccess("Dokumen berhasil diunggah");
      } else {
        print('[MATERIAL] Upload returned null or empty URL');
        _showError("Gagal mengunggah dokumen - URL kosong");
      }
    } catch (e) {
      print('[MATERIAL] Error uploading document: $e');
      _showError("Error: $e");
    } finally {
      setState(() => _uploadingDocument = false);
    }
  }

  Future<void> _removeDocument(int index) async {
    final doc = _uploadedDocuments[index];

    final success = await _supabase.deleteDocument(doc['url']!);

    if (success) {
      setState(() => _uploadedDocuments.removeAt(index));
      _showSuccess("Dokumen berhasil dihapus");
    } else {
      _showError("Gagal menghapus dokumen");
    }
  }

  Future<void> _removeVideo() async {
    if (_videoUrl == null) return;

    final success = await _supabase.deleteVideo(_videoUrl!);

    if (success) {
      setState(() => _videoUrl = null);
      _showSuccess("Video berhasil dihapus");
    } else {
      _showError("Gagal menghapus video");
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSubjectId == null) {
      _showError("Harap pilih mata pelajaran.");
      return;
    }

    setState(() => _loading = true);

    final id = widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // Upload video if selected
      if (_selectedVideo != null) {
        setState(() => _uploadingVideo = true);
        print('[MATERIAL] Starting video upload...');
        
        final url = await _supabase.uploadVideo(_selectedVideo!, id);
        
        if (url != null && url.isNotEmpty) {
          print('[MATERIAL] Video URL received: $url');
          setState(() => _videoUrl = url);
        } else {
          print('[MATERIAL] Video upload returned null or empty URL');
          _showError("Gagal mengunggah video - URL kosong");
          setState(() => _uploadingVideo = false);
          setState(() => _loading = false);
          return;
        }
        
        setState(() => _uploadingVideo = false);
      }

      // Upload document if selected
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

      if (widget.initial == null) {
        await _fs.createKnowledge(k);
      } else {
        await _fs.updateKnowledge(k);
      }

      if (mounted) {
        _showSuccess(widget.initial == null ? "Materi berhasil dibuat" : "Materi berhasil diperbarui");
        Navigator.pop(context);
      }
    } catch (e) {
      print('[MATERIAL] Error saving material: $e');
      _showError("Error: $e");
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Materi" : "Tambah Materi Baru"),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Title
                    TextFormField(
                      controller: _judulCtrl,
                      decoration: InputDecoration(
                        labelText: "Judul Materi",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Harap isi judul." : null,
                    ),
                    const SizedBox(height: 16),

                    // Subject
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
                      decoration: InputDecoration(
                        labelText: "Mata Pelajaran",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Pilih mata pelajaran" : null,
                      hint: const Text("Pilih mata pelajaran"),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 16),

                    // Type
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
                      decoration: InputDecoration(
                        labelText: "Jenis Materi",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Difficulty
                    DropdownButtonFormField<String>(
                      value: allowedLevels.contains(_kesulitan) ? _kesulitan : 'kelas10',
                      items: const [
                        DropdownMenuItem(value: 'kelas10', child: Text('Kelas 10')),
                        DropdownMenuItem(value: 'kelas11', child: Text('Kelas 11')),
                        DropdownMenuItem(value: 'kelas12', child: Text('Kelas 12')),
                      ],
                      onChanged: (v) => setState(() => _kesulitan = v!),
                      decoration: InputDecoration(
                        labelText: "Tingkat Kelas",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Content
                    TextFormField(
                      controller: _kontenCtrl,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: "Konten Materi",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Harap isi konten." : null,
                    ),
                    const SizedBox(height: 20),

                    // Video section
                    const Text(
                      'Video Materi (Opsional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_library),
                      label: const Text("Pilih Video (MP4)"),
                    ),
                    if (_selectedVideo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedVideo!.path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_videoUrl != null && _selectedVideo == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.cloud_done, color: Colors.green),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Video sudah diunggah",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _removeVideo,
                              tooltip: 'Hapus Video',
                            ),
                          ],
                        ),
                      ),
                    if (_uploadingVideo)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: LinearProgressIndicator(),
                      ),

                    const SizedBox(height: 24),

                    // Documents section
                    const Text(
                      'Dokumen Materi (Opsional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _pickDocument,
                      icon: const Icon(Icons.description),
                      label: const Text("Pilih Dokumen"),
                    ),
                    if (_selectedDocument != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDocument!.path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _uploadingDocument ? null : _uploadSelectedDocument,
                              child: Text(
                                _uploadingDocument ? "Mengunggah..." : "Unggah",
                              ),
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
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._uploadedDocuments.asMap().entries.map((e) {
                              final index = e.key;
                              final doc = e.value;

                              return Card(
                                child: ListTile(
                                  leading: const Icon(Icons.description),
                                  title: Text(
                                    doc['name']!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _removeDocument(index),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton(
                      onPressed: _uploadingVideo || _uploadingDocument
                          ? null
                          : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        isEdit ? "Simpan Perubahan" : "Buat Materi",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
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