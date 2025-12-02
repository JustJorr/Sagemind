import 'package:flutter/material.dart';
import '../models/knowledge_model.dart';
import '../services/firestore_services.dart';
import '../models/rule_model.dart';

class MaterialDetailScreen extends StatefulWidget {
  const MaterialDetailScreen({super.key});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  final FirestoreServices _fs = FirestoreServices();
  RuleModel? _suggestion;
  bool _loadingSuggestion = false;

  Future<void> _fetchSuggestion(KnowledgeModel m) async {
    setState(() { _loadingSuggestion = true; _suggestion = null; });
    final r = await _fs.getRecommendationForMaterial(m.id, subjectId: m.subjectId);
    setState(() { _suggestion = r; _loadingSuggestion = false; });
  }

  @override
  Widget build(BuildContext context) {
    final KnowledgeModel material = ModalRoute.of(context)!.settings.arguments as KnowledgeModel;

    return Scaffold(
      appBar: AppBar(title: Text(material.judul)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(material.judul, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(material.konten),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchSuggestion(material),
              child: const Text('Minta Rekomendasi Ahli'),
            ),
            const SizedBox(height: 12),
            if (_loadingSuggestion) const CircularProgressIndicator(),
            if (!_loadingSuggestion && _suggestion != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rekomendasi:', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_suggestion!.rekomendasi),
                    ],
                  ),
                ),
              ),
            if (!_loadingSuggestion && _suggestion == null)
              const Text('Belum ada rekomendasi khusus untuk materi ini.'),
          ],
        ),
      ),
    );
  }
}
