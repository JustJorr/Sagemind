import 'package:flutter/material.dart';
import '../services/firestore_services.dart';
import '../models/knowledge_model.dart';
import '../core/theme/colors.dart';

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

  // Filter states
  String? _jenis;
  String? _kesulitan;

  @override
  void initState() {
    super.initState();
  }

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

  void _clearFilters() {
    setState(() {
      _jenis = null;
      _kesulitan = null;
    });
    if (_controller.text.isNotEmpty) {
      _search();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Cari Materi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: SMColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Header with Gradient
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [SMColors.blue, SMColors.blue.withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Search Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Cari materi...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: SMColors.blue),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _controller.clear();
                                  _results = [];
                                  _showSuggestions = false;
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: _loadMatches,
                    onSubmitted: (_) => _search(),
                  ),
                ),

                // Suggestions Dropdown
                if (_showSuggestions && _suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.history,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                          title: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            _controller.text = suggestion;
                            _showSuggestions = false;
                            _search();
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_jenis != null || _kesulitan != null)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear, size: 16),
                        label: const Text('Clear'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Material Type Filter
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _jenis,
                        hint: 'Jenis',
                        icon: Icons.category_outlined,
                        items: const [
                          DropdownMenuItem(
                            value: 'konseptual',
                            child: Text('Konseptual'),
                          ),
                          DropdownMenuItem(
                            value: 'prosedural',
                            child: Text('Prosedural'),
                          ),
                          DropdownMenuItem(
                            value: 'metakognitif',
                            child: Text('Metakognitif'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _jenis = v);
                          if (_controller.text.isNotEmpty) _search();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Difficulty Filter
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _kesulitan,
                        hint: 'Level',
                        icon: Icons.trending_up_outlined,
                        items: const [
                          DropdownMenuItem(
                            value: 'kelas10',
                            child: Text('Kelas 10'),
                          ),
                          DropdownMenuItem(
                            value: 'kelas11',
                            child: Text('Kelas 11'),
                          ),
                          DropdownMenuItem(
                            value: 'kelas12',
                            child: Text('Kelas 12'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _kesulitan = v);
                          if (_controller.text.isNotEmpty) _search();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _controller.text.isEmpty
                                  ? 'Mulai cari materi'
                                  : 'Hasil tidak ditemukan',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final k = _results[i];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/material_detail',
                                arguments: k,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: SMColors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.article_outlined,
                                            color: SMColors.blue,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            k.judul,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        _buildBadge(
                                          k.jenis,
                                          Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildBadge(
                                          k.kesulitan.toUpperCase(),
                                          Colors.orange,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(hint, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}