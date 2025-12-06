// lib/screen/recommendation_screen.dart

import 'package:flutter/material.dart';
import '../models/knowledge_model.dart';
import '../models/rule_model.dart';
import '../models/subject_model.dart'; // Make sure this import is here
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

  // --- 1. NEW VARIABLES FOR SUBJECTS ---
  List<SubjectModel> allSubjects = [];
  SubjectModel? selectedSubject;
  bool loadingSubjects = true;

  // --- EXISTING VARIABLES ---
  List<KnowledgeModel> availableMaterials = []; // Materials for the selected subject
  List<RuleModel> allRules = [];
  KnowledgeModel? selectedMaterial;
  String? recommendationText;
  bool loadingMaterials = false;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  // --- 2. LOAD SUBJECTS AND RULES FIRST ---
  Future<void> loadInitialData() async {
    setState(() => loadingSubjects = true);

    try {
      // Fetch all subjects created by Admin
      final subjects = await _fs.getAllSubjects(); // Uses the alias we added
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

  // --- 3. LOAD MATERIALS WHEN SUBJECT CHOSEN ---
  Future<void> onSubjectChanged(SubjectModel? subject) async {
    if (subject == null) return;

    setState(() {
      selectedSubject = subject;
      selectedMaterial = null;
      availableMaterials = [];
      loadingMaterials = true; 
    });

    try {
      // Fetch materials that match this Subject ID
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

    // We pass the Material ID to the expert engine
    final r = ExpertEngine.inferFromMaterial(selectedMaterial!.id, allRules);

    setState(() {
      recommendationText = r?.rekomendasi ?? "Tidak ada rekomendasi untuk materi ini.";
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loadingSubjects) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // --- SECTION 1: MANUAL INPUT ---
            const Text(
              "Input Kesulitan (Manual)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Contoh: Saya belum paham pecahan.",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: findRecommendationByCondition,
              child: const Text("Dapatkan rekomendasi dari input"),
            ),

            const Divider(height: 30),

            // --- SECTION 2: SUBJECT SELECTION ---
            const Text(
              "Pilih Mata Pelajaran",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            // SUBJECT DROPDOWN
            DropdownButtonFormField<SubjectModel>(
              value: selectedSubject,
              hint: const Text("Pilih Subject..."),
              isExpanded: true,
              items: allSubjects.map((s) {
                return DropdownMenuItem(
                  value: s, // It's okay to use Object here if list doesn't change
                  child: Text(s.nama),
                );
              }).toList(),
              onChanged: onSubjectChanged, // Calls the function to load materials
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const SizedBox(height: 16),

            // --- SECTION 3: MATERIAL SELECTION ---
            const Text(
              "Pilih Materi",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (loadingMaterials)
               const Center(child: Padding(
                 padding: EdgeInsets.all(8.0),
                 child: CircularProgressIndicator(),
               ))
            else 
              DropdownButtonFormField<KnowledgeModel>(
                value: selectedMaterial,
                // Disable dropdown if no subject is selected or no materials found
                onChanged: (selectedSubject == null || availableMaterials.isEmpty) 
                    ? null 
                    : (v) => setState(() => selectedMaterial = v),
                
                hint: Text(selectedSubject == null 
                    ? "Pilih Subject Terlebih Dahulu" 
                    : (availableMaterials.isEmpty ? "Tidak ada materi di subject ini" : "Pilih Materi...")),
                
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
                ),
              ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: findRecommendationByMaterial,
              child: const Text("Dapatkan rekomendasi dari materi"),
            ),

            // --- RESULT SECTION ---
            if (recommendationText != null) ...[
              const Divider(height: 30),
              const Text(
                "Hasil Rekomendasi:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  recommendationText!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}