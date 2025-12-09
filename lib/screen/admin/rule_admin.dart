import 'package:flutter/material.dart';
import '../../models/rule_model.dart';
import '../../models/subject_model.dart';
import '../../models/knowledge_model.dart';
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
      appBar: AppBar(
        title: const Text('Kelola Aturan'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Tambah Aturan'),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rule, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada aturan.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Buat aturan pertama Anda untuk memulai',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rules.length,
                  itemBuilder: (context, i) {
                    final r = _rules[i];
                    final hasExactMatch = r.materialId.isNotEmpty;
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasExactMatch 
                                        ? Colors.green[100] 
                                        : Colors.blue[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    hasExactMatch ? 'COCOK PERSIS' : 'COCOK INPUT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: hasExactMatch
                                          ? Colors.green[800]
                                          : Colors.blue[800],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
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
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Hapus Aturan?'),
                                        content: const Text(
                                            'Apakah Anda yakin ingin menghapus aturan ini?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok == true) await _delete(r.id);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (hasExactMatch) ...[
                              Row(
                                children: [
                                  Icon(Icons.book, 
                                    size: 16, 
                                    color: Colors.grey[600]
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'ID Materi: ${r.materialId}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              'Kondisi:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r.kondisi,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Rekomendasi:',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              r.rekomendasi,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[800],
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
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

  List<SubjectModel> _subjects = [];
  String _selectedSubjectId = '';
  
  List<KnowledgeModel> _materials = [];
  String? _selectedMaterialId;

  bool _loading = true;
  bool _isExactMatch = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _kondisiCtrl.text = widget.initial!.kondisi;
      _rekomCtrl.text = widget.initial!.rekomendasi;
      _selectedSubjectId = widget.initial!.subjectId;
      _selectedMaterialId = widget.initial!.materialId.isEmpty 
          ? null 
          : widget.initial!.materialId;
      _isExactMatch = widget.initial!.materialId.isNotEmpty;
    }
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    _subjects = await _fs.getSubjectsOnce();
    if (_subjects.isNotEmpty) {
      if (_selectedSubjectId.isEmpty || 
          !_subjects.any((s) => s.id == _selectedSubjectId)) {
        _selectedSubjectId = _subjects.first.id;
      }
      await _loadMaterials(_selectedSubjectId);
    }
    setState(() => _loading = false);
  }

  Future<void> _loadMaterials(String subjectId) async {
    setState(() => _loading = true);
    _materials = await _fs.getKnowledgeBySubject(subjectId);
    
    // Reset material selection if it doesn't exist in new subject
    if (_selectedMaterialId != null && 
        !_materials.any((m) => m.id == _selectedMaterialId)) {
      _selectedMaterialId = null;
    }
    
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate exact match rules
    if (_isExactMatch && _selectedMaterialId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih materi untuk aturan cocok persis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final id = widget.initial?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final r = RuleModel(
      id: id,
      subjectId: _selectedSubjectId,
      kondisi: _kondisiCtrl.text.trim(),
      rekomendasi: _rekomCtrl.text.trim(),
      materialId: _isExactMatch ? (_selectedMaterialId ?? '') : '',
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
      appBar: AppBar(
        title: Text(isEdit ? "Edit Aturan" : "Tambah Aturan Baru"),
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
                    // Rule Type Selection
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jenis Aturan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isExactMatch = false;
                                        _selectedMaterialId = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: !_isExactMatch
                                            ? Colors.blue[50]
                                            : Colors.grey[100],
                                        border: Border.all(
                                          color: !_isExactMatch
                                              ? Colors.blue
                                              : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.text_fields,
                                            size: 32,
                                            color: !_isExactMatch
                                                ? Colors.blue
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Cocok Input',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: !_isExactMatch
                                                  ? Colors.blue[800]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pencocokan teks fuzzy',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      setState(() => _isExactMatch = true);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _isExactMatch
                                            ? Colors.green[50]
                                            : Colors.grey[100],
                                        border: Border.all(
                                          color: _isExactMatch
                                              ? Colors.green
                                              : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.link,
                                            size: 32,
                                            color: _isExactMatch
                                                ? Colors.green
                                                : Colors.grey[600],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Cocok Persis',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _isExactMatch
                                                  ? Colors.green[800]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tautan ke materi',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subject Selection
                    Text(
                      'Mata Pelajaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedSubjectId,
                      items: _subjects
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.nama),
                              ))
                          .toList(),
                      onChanged: (v) async {
                        if (v != null) {
                          setState(() {
                            _selectedSubjectId = v;
                            _selectedMaterialId = null;
                          });
                          await _loadMaterials(v);
                        }
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Material Selection (only for exact match)
                    if (_isExactMatch) ...[
                      Text(
                        'Materi *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedMaterialId,
                        items: _materials
                            .map((m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.judul),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedMaterialId = v),
                        decoration: InputDecoration(
                          hintText: 'Pilih materi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        validator: (v) => _isExactMatch && v == null
                            ? 'Silakan pilih materi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Condition Input
                    Text(
                      'Kondisi ${_isExactMatch ? '(Deskripsi)' : '(Pemicu)'}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _kondisiCtrl,
                      decoration: InputDecoration(
                        hintText: _isExactMatch
                            ? 'Contoh: Kesulitan dengan materi ini'
                            : 'Contoh: Kesulitan dengan turunan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 2,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Harap masukkan kondisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Recommendation Input
                    Text(
                      'Rekomendasi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _rekomCtrl,
                      decoration: InputDecoration(
                        hintText: 'Masukkan rekomendasi Anda di sini...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 5,
                      validator: (v) => v == null || v.isEmpty
                          ? 'Harap masukkan rekomendasi'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Simpan Perubahan' : 'Buat Aturan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _kondisiCtrl.dispose();
    _rekomCtrl.dispose();
    super.dispose();
  }
}