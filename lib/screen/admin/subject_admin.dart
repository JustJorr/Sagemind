import 'package:flutter/material.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_services.dart';

class AdminSubjectScreen extends StatefulWidget {
  const AdminSubjectScreen({super.key});

  @override
  State<AdminSubjectScreen> createState() => _AdminSubjectScreenState();
}

class _AdminSubjectScreenState extends State<AdminSubjectScreen> {
  final FirestoreServices _fs = FirestoreServices();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Mata Pelajaran")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditSubjectScreen()),
          );
          setState(() {}); // reload setelah kembali
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<SubjectModel>>(
        future: _fs.getSubjectsOnce(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data!;
          if (subjects.isEmpty) {
            return const Center(child: Text("Belum ada mata pelajaran."));
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (_, i) {
              final s = subjects[i];
              return Card(
                child: ListTile(
                  title: Text(s.nama),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditSubjectScreen(subject: s),
                            ),
                          );
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _fs.deleteSubject(s.id);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AddEditSubjectScreen extends StatefulWidget {
  final SubjectModel? subject;

  const AddEditSubjectScreen({super.key, this.subject});

  @override
  State<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends State<AddEditSubjectScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final FirestoreServices _fs = FirestoreServices();

  @override
  void initState() {
    super.initState();
    if (widget.subject != null) {
      _nameCtrl.text = widget.subject!.nama;
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    if (widget.subject == null) {
      await _fs.createSubject(name);
    } else {
      await _fs.updateSubject(widget.subject!.id, name);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subject != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Mata Pelajaran" : "Tambah Mata Pelajaran")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Nama Mata Pelajaran",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEdit ? "Simpan Perubahan" : "Tambah"),
            )
          ],
        ),
      ),
    );
  }
}
