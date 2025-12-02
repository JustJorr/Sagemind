// lib/screen/admin/add_edit_subject_screen.dart
import 'package:flutter/material.dart';
import '../../models/subject_model.dart';
import '../../services/firestore_services.dart';

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
      appBar: AppBar(title: Text(isEdit ? "Edit Subject" : "Add Subject")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: "Subject Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(isEdit ? "Save Changes" : "Create"),
            )
          ],
        ),
      ),
    );
  }
}
