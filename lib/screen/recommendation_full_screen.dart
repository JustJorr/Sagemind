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
      setState(() => _resultText = 'Silakan jelaskan kesulitan Anda terlebih dahulu.');
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
        _resultText = 'Rekomendasi Terbaik:\n\n${top.rule.rekomendasi}\n\n(Skor: ${top.score.toStringAsFixed(2)})';
      }
    });
  }

  Future<void> _onSearchByMaterial() async {
    if (_selectedMaterial == null) {
      setState(() => _resultText = 'Silakan pilih materi terlebih dahulu.');
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
        _resultText = 'Tidak ada rekomendasi untuk materi ini.';
      } else {
        _resultText = 'Rekomendasi:\n\n${r.rekomendasi}\n\n(Kondisi: ${r.kondisi})';
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
        title: const Text('Rekomendasi Ahli'),
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
                    'Pilih Mata Pelajaran',
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
                    'Pilih Materi (Opsional)',
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
                    'Jelaskan Kesulitan Anda',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: 'Contoh: Saya tidak paham cara mencari turunan fungsi...',
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
                          label: const Text('Dari Input'),
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
                          label: const Text('Dari Materi'),
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
                      'Hasil:',
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

// ==================== RECOMMENDATION SCREEN ====================

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final _controller = TextEditingController();
  final FirestoreServices _fs = FirestoreServices();

  List<SubjectModel> allSubjects = [];
  SubjectModel? selectedSubject;
  bool loadingSubjects = true;

  List<KnowledgeModel> availableMaterials = [];
  List<RuleModel> allRules = [];
  KnowledgeModel? selectedMaterial;
  String? recommendationText;
  bool loadingMaterials = false;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    setState(() => loadingSubjects = true);

    try {
      final subjects = await _fs.getAllSubjects();
      final rules = await _fs.getAllRules();

      setState(() {
        allSubjects = subjects;
        allRules = rules;
        loadingSubjects = false;
      });
    } catch (e) {
      print("Error loading initial data: $e");
      setState(() => loadingSubjects = false);
    }
  }

  Future<void> onSubjectChanged(SubjectModel? subject) async {
    if (subject == null) return;

    setState(() {
      selectedSubject = subject;
      selectedMaterial = null;
      availableMaterials = [];
      loadingMaterials = true;
    });

    try {
      final materials = await _fs.getKnowledgeBySubject(subject.id);

      setState(() {
        availableMaterials = materials;
        loadingMaterials = false;
      });
    } catch (e) {
      print("Error loading materials: $e");
      setState(() => loadingMaterials = false);
    }
  }

  void findRecommendationByCondition() {
    if (_controller.text.isEmpty) {
      setState(() => recommendationText = "Masukkan kesulitan Anda terlebih dahulu.");
      return;
    }

    final r = ExpertEngine.inferFromCondition(_controller.text, allRules);

    setState(() {
      recommendationText = r?.rekomendasi ?? "Tidak ada rekomendasi yang cocok.";
    });
  }

  void findRecommendationByMaterial() {
    if (selectedMaterial == null) {
      setState(() => recommendationText = "Pilih materi terlebih dahulu.");
      return;
    }

    final r = ExpertEngine.inferFromMaterial(selectedMaterial!.id, allRules);

    setState(() {
      recommendationText = r?.rekomendasi ?? "Tidak ada rekomendasi untuk materi ini.";
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loadingSubjects) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dapatkan Rekomendasi'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListView(
          children: [
            // --- SECTION 1: MANUAL INPUT ---
            const Text(
              "Jelaskan Kesulitan Anda",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Contoh: Saya tidak paham pecahan...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: findRecommendationByCondition,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text("Dapatkan Rekomendasi dari Input"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // --- SECTION 2: SUBJECT SELECTION ---
            const Text(
              "Atau Pilih Berdasarkan Mata Pelajaran",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SubjectModel>(
              value: selectedSubject,
              hint: const Text("Pilih mata pelajaran..."),
              isExpanded: true,
              items: allSubjects.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s.nama),
                );
              }).toList(),
              onChanged: onSubjectChanged,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),

            const SizedBox(height: 16),

            // --- SECTION 3: MATERIAL SELECTION ---
            const Text(
              "Pilih Materi",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (loadingMaterials)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              DropdownButtonFormField<KnowledgeModel>(
                value: selectedMaterial,
                onChanged: (selectedSubject == null || availableMaterials.isEmpty)
                    ? null
                    : (v) => setState(() => selectedMaterial = v),
                hint: Text(selectedSubject == null
                    ? "Pilih mata pelajaran terlebih dahulu"
                    : (availableMaterials.isEmpty ? "Tidak ada materi di mata pelajaran ini" : "Pilih materi...")),
                isExpanded: true,
                items: availableMaterials.map((m) {
                  return DropdownMenuItem(
                    value: m,
                    child: Text(m.judul),
                  );
                }).toList(),
                decoration: InputDecoration(
                  filled: selectedSubject == null || availableMaterials.isEmpty,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),

            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: findRecommendationByMaterial,
              icon: const Icon(Icons.book_outlined),
              label: const Text("Dapatkan Rekomendasi dari Materi"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            // --- RESULT SECTION ---
            if (recommendationText != null) ...[
              const SizedBox(height: 24),
              const Text(
                "Rekomendasi:",
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
                  recommendationText!,
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