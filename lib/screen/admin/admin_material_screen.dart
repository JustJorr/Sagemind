import 'package:flutter/material.dart';
import '../../models/knowledge_model.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_services.dart';
import 'admin_edit_material_screen.dart';

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
    if (_selectedSubject != null) await _loadMaterials(_selectedSubject!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Materials")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditMaterialScreen()),
          );
          if (_selectedSubject != null) await _loadMaterials(_selectedSubject!.id);
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Subject selector
                  DropdownButtonFormField<SubjectModel>(
                    value: _selectedSubject,
                    items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.nama))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedSubject = v;
                        _materials = [];
                      });
                      if (v != null) _loadMaterials(v.id);
                    },
                    decoration: const InputDecoration(labelText: 'Filter by Subject', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _materials.isEmpty
                        ? const Center(child: Text('No materials found.'))
                        : ListView.builder(
                            itemCount: _materials.length,
                            itemBuilder: (context, i) {
                              final m = _materials[i];
                              return Card(
                                child: ListTile(
                                  title: Text(m.judul),
                                  subtitle: Text('${m.jenis} • ${m.subjectId}'),
                                  onTap: () => Navigator.pushNamed(context, '/material/detail', arguments: m),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => AddEditMaterialScreen(initial: m)),
                                          );
                                          if (_selectedSubject != null) await _loadMaterials(_selectedSubject!.id);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Hapus Materi?'),
                                              content: const Text('Yakin ingin menghapus materi ini?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                                              ],
                                            ),
                                          );
                                          if (ok == true) await _deleteMaterial(m.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
