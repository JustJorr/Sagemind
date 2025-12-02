// lib/screen/admin/admin_subject_screen.dart
import 'package:flutter/material.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_services.dart';
import 'add_edit_subject_screen.dart';

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
      appBar: AppBar(title: const Text("Manage Subjects")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditSubjectScreen()),
          );
          setState(() {}); // reload after return
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
            return const Center(child: Text("No subjects found."));
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
