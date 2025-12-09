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
      setState(() => _resultText = 'Please describe your difficulty first.');
      return;
    }
    setState(() => _loading = true);
    final candidates = _rules;
    final scored = ExpertEngine.scoreRulesByCondition(text, candidates);
    setState(() {
      _loading = false;
      if (scored.isEmpty) {
        _resultText = 'No matching recommendation found.';
      } else {
        final top = scored.first;
        _resultText = 'Best Recommendation:\n\n${top.rule.rekomendasi}\n\n(Score: ${top.score.toStringAsFixed(2)})';
      }
    });
  }

  Future<void> _onSearchByMaterial() async {
    if (_selectedMaterial == null) {
      setState(() => _resultText = 'Please select a material first.');
      return;
    }
    setState(() => _loading = true);
    final r = await _fs.getRecommendationForMaterial(
      _selectedMaterial!.id,
      subjectId: _selectedSubject?.id,
    );
    setState(() {
      _loading = false;
      if (r == null) {
        _resultText = 'No recommendation available for this material.';
      } else {
        _resultText = 'Recommendation:\n\n${r.rekomendasi}\n\n(Condition: ${r.kondisi})';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expert Recommendation'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListView(
                children: [
                  // --- SUBJECT SELECTION ---
                  const Text(
                    'Select Subject',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<SubjectModel>(
                    value: _selectedSubject,
                    items: _subjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.nama)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedSubject = v;
                          _selectedMaterial = null;
                          _resultText = null;
                        });
                        _loadMaterials(v.id);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- MATERIAL SELECTION ---
                  const Text(
                    'Select Material (Optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<KnowledgeModel>(
                    value: _selectedMaterial,
                    items: _materials
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.judul)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedMaterial = v),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- INPUT DIFFICULTY ---
                  const Text(
                    'Describe Your Difficulty',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: 'E.g., I don\'t understand how to find function derivatives...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- ACTION BUTTONS ---
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onSearchByCondition,
                          icon: const Icon(Icons.lightbulb_outline, size: 18),
                          label: const Text('From Input'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onSearchByMaterial,
                          icon: const Icon(Icons.book_outlined, size: 18),
                          label: const Text('From Material'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- RESULT SECTION ---
                  if (_resultText != null) ...[
                    const Text(
                      'Result:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        _resultText!,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]
                ],
              ),
            ),
    );
  }
}