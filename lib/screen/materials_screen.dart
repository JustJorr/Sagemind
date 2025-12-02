import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../models/knowledge_model.dart';
import '../services/firestore_services.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final FirestoreServices _fs = FirestoreServices();
  String selectedType = 'konseptual'; // default filter

  @override
  Widget build(BuildContext context) {
    final SubjectModel subject =
        ModalRoute.of(context)!.settings.arguments as SubjectModel;

    return Scaffold(
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: FutureBuilder<List<KnowledgeModel>>(
              future:
                  _fs.getKnowledgeBySubjectAndType(subject.id, selectedType),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Error memuat materi'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snap.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('Belum ada materi'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final m = list[i];
                    return _buildMaterialCard(m);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Konseptual'),
            selected: selectedType == 'konseptual',
            onSelected: (_) => setState(() => selectedType = 'konseptual'),
          ),
          ChoiceChip(
            label: const Text('Prosedural'),
            selected: selectedType == 'prosedural',
            onSelected: (_) => setState(() => selectedType = 'prosedural'),
          ),
          ChoiceChip(
            label: const Text('Metakognitif'),
            selected: selectedType == 'metakognitif',
            onSelected: (_) => setState(() => selectedType = 'metakognitif'),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(KnowledgeModel m) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            Navigator.pushNamed(context, '/material_detail', arguments: m),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                m.judul,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),

              // Type
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  m.jenis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),

              const SizedBox(height: 8),

              // Short Preview
              Text(
                m.konten.length > 80
                    ? '${m.konten.substring(0, 80)}...'
                    : m.konten,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),

              const SizedBox(height: 12),

              // Recommendation Button
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/recommendation',
                    arguments: m,
                  ),
                  child: const Text('Lihat Rekomendasi'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
