import 'package:flutter/material.dart';
import '../services/firestore_services.dart';
import '../models/knowledge_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirestoreServices _fs = FirestoreServices();
  final _controller = TextEditingController();
  List<KnowledgeModel> _results = [];
  bool _loading = false;

  Future<void> _search() async {
    setState(() { _loading = true; _results = []; });
    final res = await _fs.searchKnowledge(_controller.text);
    setState(() { _results = res; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Cari materi',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _search),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(),
            if (!_loading)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final k = _results[i];
                    return Card(
                      child: ListTile(
                        title: Text(k.judul),
                        subtitle: Text(k.konten, maxLines: 2, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pushNamed(context, '/material_detail', arguments: k),
                      ),
                    );
                  },
                ),
              )
          ],
        ),
      ),
    );
  }
}
