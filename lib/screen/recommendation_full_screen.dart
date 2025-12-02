// lib/screen/recommendation_full_screen.dart
import 'package:flutter/material.dart';
import '../models/knowledge_model.dart';
import '../models/rule_model.dart';
import '../models/subject_model.dart';
import '../services/firestore_services.dart';
import '../services/expert_engine.dart';

class RecommendationFullScreen extends StatefulWidget {
  const RecommendationFullScreen({super.key});

  @override
  State<RecommendationFullScreen> createState() => _RecommendationFullScreenState();
}

class _RecommendationFullScreenState extends State<RecommendationFullScreen> {
  final FirestoreServices _fs = FirestoreServices();
  final TextEditingController _controller = TextEditingController();

  List<SubjectModel> _subjects = [];
  SubjectModel? _selectedSubject;

  List<KnowledgeModel> _materials = [];
  KnowledgeModel? _selectedMaterial;

  List<RuleModel> _rules = [];
  String? _resultText;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSubjectsAndRules();
  }

  Future<void> _loadSubjectsAndRules() async {
    setState(() => _loading = true);
    _subjects = await _fs.getSubjectsOnce();
    _rules = await _fs.getAllRules();
    setState(() {
      _loading = false;
      if (_subjects.isNotEmpty) _selectedSubject = _subjects.first;
      if (_selectedSubject != null) _loadMaterials(_selectedSubject!.id);
    });
  }

  Future<void> _loadMaterials(String subjectId) async {
    setState(() => _loading = true);
    _materials = await _fs.getKnowledgeBySubject(subjectId);
    setState(() => _loading = false);
  }

  Future<void> _onSearchByCondition() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _resultText = 'Tolong tulis kesulitan Anda terlebih dahulu.');
      return;
    }
    setState(() => _loading = true);
    final candidates = _rules;
    final scored = ExpertEngine.scoreRulesByCondition(text, candidates);
    setState(() {
      _loading = false;
      if (scored.isEmpty) {
        _resultText = 'Tidak ada rekomendasi yang cocok.';
      } else {
        final top = scored.first;
        _resultText = 'Rekomendasi terbaik:\n\n${top.rule.rekomendasi}\n\n(Skor: ${top.score.toStringAsFixed(2)})';
      }
    });
  }

  Future<void> _onSearchByMaterial() async {
    if (_selectedMaterial == null) {
      setState(() => _resultText = 'Silakan pilih materi terlebih dahulu.');
      return;
    }
    setState(() => _loading = true);
    // langsung cari rule exact / fuzzy via expert engine
    final r = await _fs.getRecommendationForMaterial(_selectedMaterial!.id, subjectId: _selectedSubject?.id);
    setState(() {
      _loading = false;
      if (r == null) {
        _resultText = 'Belum ada rekomendasi untuk materi ini.';
      } else {
        _resultText = 'Rekomendasi:\n\n${r.rekomendasi}\n\n(Kondisi: ${r.kondisi})';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: ListView(
                children: [
                  const Text('Pilih Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SubjectModel>(
                    value: _selectedSubject,
                    items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.nama))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedSubject = v;
                        _selectedMaterial = null;
                        if (v != null) _loadMaterials(v.id);
                      });
                    },
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('Pilih Materi (opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<KnowledgeModel>(
                    value: _selectedMaterial,
                    items: _materials.map((m) => DropdownMenuItem(value: m, child: Text(m.judul))).toList(),
                    onChanged: (v) => setState(() => _selectedMaterial = v),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tulis kesulitan atau pertanyaan kamu', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Contoh: Saya tidak paham cara mencari turunan fungsi...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onSearchByCondition,
                          child: const Text('Rekomendasi dari Kondisi'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onSearchByMaterial,
                          child: const Text('Rekomendasi dari Materi'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_resultText != null) ...[
                    const Text('Hasil', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_resultText!),
                      ),
                    ),
                  ]
                ],
              ),
            ),
    );
  }
}
