import 'package:flutter/material.dart';
import '../models/knowledge_model.dart';
import '../services/firestore_services.dart';
import '../models/rule_model.dart';
import 'package:video_player/video_player.dart';

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
    setState(() {
      _loadingSuggestion = true;
      _suggestion = null;
    });

    final r = await _fs.getRecommendationForMaterial(m.id, subjectId: m.subjectId);

    setState(() {
      _suggestion = r;
      _loadingSuggestion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final KnowledgeModel material =
        ModalRoute.of(context)!.settings.arguments as KnowledgeModel;

    return Scaffold(
      appBar: AppBar(title: Text(material.judul)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              material.judul,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            //  SHOW VIDEO IF EXISTS
            if (material.videoUrl != null &&
                material.videoUrl!.isNotEmpty)
              Container(
                height: 220,
                margin: const EdgeInsets.only(bottom: 16),
                child: VideoPlayerWidget(url: material.videoUrl!),
              ),

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
                      const Text('Rekomendasi:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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

// REUSABLE VIDEO PLAYER WIDGET
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: VideoPlayer(_controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
