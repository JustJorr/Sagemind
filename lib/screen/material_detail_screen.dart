import 'package:flutter/material.dart';
import '../models/knowledge_model.dart';
import '../services/firestore_services.dart';
import '../models/rule_model.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _downloadDocument(String url, String fileName) async {
  try {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak dapat membuka dokumen")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
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

            const SizedBox(height: 16),

            // Display documents if they exist
            if (material.documents != null && material.documents!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dokumen Materi:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...material.documents!.map((doc) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.description, color: Colors.blue),
                        title: Text(doc['name'] ?? 'Dokumen'),
                        trailing: const Icon(Icons.download),
                        onTap: () => _downloadDocument(
                          doc['url'] ?? '',
                          doc['name'] ?? 'dokumen',
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await _controller.initialize();
      
      if (mounted) {
        setState(() {});
        _controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat video: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          // Play/Pause overlay button
          GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: _controller.value.isPlaying
                ? Container()
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
          ),
          // Progress indicator
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
