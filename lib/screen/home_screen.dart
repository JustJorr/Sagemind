import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../services/firestore_services.dart';
import '../models/subject_model.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreServices _fs = FirestoreServices();

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Sagemind',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: SMColors.blue,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: SMColors.blue,
            child: StreamBuilder<List<SubjectModel>>(
              stream: _fs.streamSubjects(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final subjects = snapshot.data!;

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: subjects.length,
                  itemBuilder: (context, i) {
                    final s = subjects[i];
                    return Card(
                      child: ListTile(
                        title: Text(s.nama),
                        subtitle: Text(s.deskripsi),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/materials',
                          arguments: s,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
