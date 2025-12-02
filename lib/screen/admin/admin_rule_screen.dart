import 'package:flutter/material.dart';
import '../../models/rule_model.dart';
import '../../services/firestore_services.dart';
import 'add_edit_rule_screen.dart';

class AdminRuleScreen extends StatefulWidget {
  const AdminRuleScreen({super.key});

  @override
  State<AdminRuleScreen> createState() => _AdminRuleScreenState();
}

class _AdminRuleScreenState extends State<AdminRuleScreen> {
  final FirestoreServices _fs = FirestoreServices();
  List<RuleModel> _rules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _rules = await _fs.getAllRules();
    setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    await _fs.deleteRule(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Rules')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditRuleScreen()));
          await _load();
        },
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? const Center(child: Text('No rules yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rules.length,
                  itemBuilder: (context, i) {
                    final r = _rules[i];
                    return Card(
                      child: ListTile(
                        title: Text(r.kondisi),
                        subtitle: Text(r.rekomendasi),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditRuleScreen(initial: r)));
                                await _load();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Hapus Rule?'),
                                    content: const Text('Yakin ingin menghapus rule ini?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
                                    ],
                                  ),
                                );
                                if (ok == true) await _delete(r.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
