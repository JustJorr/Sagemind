import 'package:flutter/material.dart';
import 'package:sagemind/core/theme/colors.dart';
import '../services/firestore_services.dart';
import '../models/subject_model.dart';
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final FirestoreServices _fs = FirestoreServices();

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
          child: StreamBuilder<List<SubjectModel>>(
            stream: _fs.streamSubjects(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Error'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final subjects = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: subjects.length,
                itemBuilder: (context, i) {
                  final s = subjects[i];
                  return Card(
                    child: ListTile(
                      title: Text(s.nama),
                      subtitle: Text(s.deskripsi),
                      onTap: () =>
                          Navigator.pushNamed(context, '/materials', arguments: s),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
