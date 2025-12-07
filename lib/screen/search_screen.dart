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
  final TextEditingController _controller = TextEditingController();

  List<KnowledgeModel> _results = [];
  List<String> _suggestions = [];

  bool _loading = false;
  bool _showSuggestions = false;

  // ==========================
  // FILTER STATES
  // ==========================
  String? _jenis;       // konseptual, prosedural, metakognitif
  String? _kesulitan;   // kelas10, kelas11, kelas12

  Future<void> _search() async {
    setState(() {
      _loading = true;
      _results = [];
      _showSuggestions = false;
    });

    final res = await _fs.searchKnowledge(_controller.text.trim());

    // Apply filters locally
    List<KnowledgeModel> filtered = res;

    if (_jenis != null) {
      filtered = filtered.where((k) => k.jenis == _jenis).toList();
    }
    if (_kesulitan != null) {
      filtered = filtered.where((k) => k.kesulitan == _kesulitan).toList();
    }

    setState(() {
      _results = filtered;
      _loading = false;
    });
  }

  /// Auto-matching suggestions
  Future<void> _loadMatches(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final res = await _fs.searchKnowledge(query);
    final titles = res.map((e) => e.judul).toList();

    setState(() {
      _suggestions = titles.take(5).toList();
      _showSuggestions = _suggestions.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // SEARCH FIELD + SUGGESTIONS
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Cari materi...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _loadMatches,
                    onSubmitted: (_) => _search(),
                  ),
                ),

                // Suggestion dropdown
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Positioned(
                    top: 55,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: _suggestions.map((text) {
                          return ListTile(
                            title: Text(text),
                            onTap: () {
                              _controller.text = text;
                              _showSuggestions = false;
                              _search();
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),

            // FILTER: JENIS + KESULITAN
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _jenis,
                    decoration: const InputDecoration(
                      labelText: "Jenis Materi",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'konseptual', child: Text('Konseptual')),
                      DropdownMenuItem(
                          value: 'prosedural', child: Text('Prosedural')),
                      DropdownMenuItem(
                          value: 'metakognitif', child: Text('Metakognitif')),
                    ],
                    onChanged: (v) {
                      setState(() => _jenis = v);
                      _search();
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _kesulitan,
                    decoration: const InputDecoration(
                      labelText: "Kesulitan",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'kelas10', child: Text('Kelas 10')),
                      DropdownMenuItem(
                          value: 'kelas11', child: Text('Kelas 11')),
                      DropdownMenuItem(
                          value: 'kelas12', child: Text('Kelas 12')),
                    ],
                    onChanged: (v) {
                      setState(() => _kesulitan = v);
                      _search();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // LOADING / RESULTS
            if (_loading) const CircularProgressIndicator(),

            if (!_loading)
              Expanded(
                child: _results.isEmpty
                    ? const Center(child: Text("Tidak ada hasil."))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final k = _results[i];
                          return Card(
                            child: ListTile(
                              title: Text(k.judul),
                              subtitle: Text(
                                  "${k.jenis} • ${k.kesulitan.toUpperCase()}"),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/material_detail',
                                arguments: k,
                              ),
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
