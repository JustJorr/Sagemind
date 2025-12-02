// lib/screen/recommendation_screen.dart

import 'package:flutter/material.dart';
import '../models/knowledge_model.dart';
import '../models/rule_model.dart';
import '../services/firestore_services.dart';
import '../services/expert_engine.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final _controller = TextEditingController();
  final FirestoreServices _fs = FirestoreServices();

  List<KnowledgeModel> allMaterials = [];
  List<RuleModel> allRules = [];

  KnowledgeModel? selectedMaterial;

  String? recommendationText;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final materialsSnap = await _fs
    .getKnowledgeBySubjectAndType("math", "konseptual")
    .catchError((_) => <KnowledgeModel>[]);

    if (materialsSnap.isEmpty) {
      print("No materials found");
    } else {
      print("Loaded ${materialsSnap.length} materials");
    }

    final all = await _fs.getKnowledgeBySubject("math")
        .catchError((_) => <KnowledgeModel>[]);

    final rules = await _fs.getAllRules()
        .catchError((_) => <RuleModel>[]);

    setState(() {
      allMaterials = all;
      allRules = rules;
      loading = false;
    });
  }

  void findRecommendationByCondition() {
    if (_controller.text.isEmpty) {
      setState(() => recommendationText = "Masukkan kondisi terlebih dahulu.");
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
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Input Kesulitan",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Contoh: Saya belum paham pecahan.",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: findRecommendationByCondition,
              child: const Text("Dapatkan rekomendasi dari input"),
            ),

            const Divider(height: 30),

            const Text(
              "Pilih Materi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<KnowledgeModel>(
              value: selectedMaterial,
              items: allMaterials.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(m.judul),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedMaterial = v),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: findRecommendationByMaterial,
              child: const Text("Dapatkan rekomendasi dari materi"),
            ),

            if (recommendationText != null) ...[
              const Divider(height: 30),
              const Text(
                "Hasil Rekomendasi:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                recommendationText!,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
