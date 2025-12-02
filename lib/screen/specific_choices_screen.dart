import 'package:flutter/material.dart';
import '../models/subject_model.dart';

class SpecificChoicesScreen extends StatefulWidget {
  const SpecificChoicesScreen({super.key});

  @override
  State<SpecificChoicesScreen> createState() => _SpecificChoicesScreenState();
}

class _SpecificChoicesScreenState extends State<SpecificChoicesScreen> {
  String? _condition;
  String? _goal;

  final _conditions = ['Pemula', 'Menengah', 'Lanjutan'];
  final _goals = ['Belajar Konsep', 'Latihan Soal', 'Proyek'];

  @override
  Widget build(BuildContext context) {
    // optional: pass subject as argument if coming from subject list
    final SubjectModel? subject = ModalRoute.of(context)!.settings.arguments as SubjectModel?;

    return Scaffold(
      appBar: AppBar(title: const Text('Pilihan Spesifik')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: _condition,
              hint: const Text('Pilih kondisi'),
              items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _condition = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _goal,
              hint: const Text('Pilih tujuan'),
              items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => setState(() => _goal = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // move to materials (optionally pass subject & filters)
                Navigator.pushNamed(context, '/materials', arguments: subject);
              },
              child: const Text('Lihat Materi Rekomendasi'),
            )
          ],
        ),
      ),
    );
  }
}
