import 'package:flutter/material.dart';
import '../models/knowledge_model.dart';
import '../services/firestore_services.dart';
import '../services/download_service.dart';
import '../services/permission_service.dart';
import '../models/rule_model.dart';
import 'package:video_player/video_player.dart';

class MaterialDetailScreen extends StatefulWidget {
  const MaterialDetailScreen({super.key});

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  final FirestoreServices _fs = FirestoreServices();
  final DownloadService _downloadService = DownloadService();
  final PermissionService _permissionService = PermissionService();
  
  RuleModel? _suggestion;
  bool _loadingSuggestion = false;
  
  // Track download progress for each document
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};

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
    // Check permissions first
    final hasPermission = await _permissionService.requestDownloadPermission();
    
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Izin penyimpanan diperlukan untuk mengunduh dokumen"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Start downloading
    setState(() {
      _isDownloading[url] = true;
      _downloadProgress[url] = 0.0;
    });

    try {
      final filePath = await _downloadService.downloadDocument(
        url,
        fileName,
        onProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress[url] = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading[url] = false;
        _downloadProgress.remove(url);
      });

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Dokumen berhasil diunduh ke: Downloads/$fileName"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mengunduh dokumen"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading[url] = false;
        _downloadProgress.remove(url);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    final url = doc['url'] ?? '';
                    final name = doc['name'] ?? 'Dokumen';
                    final isDownloading = _isDownloading[url] ?? false;
                    final progress = _downloadProgress[url];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.description, color: Colors.blue),
                            title: Text(name),
                            subtitle: isDownloading
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Mengunduh...',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          Colors.blue,
                                        ),
                                      ),
                                      if (progress != null)
                                        Text(
                                          '${(progress * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                    ],
                                  )
                                : null,
                            trailing: isDownloading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download),
                            onTap: isDownloading
                                ? null
                                : () => _downloadDocument(url, name),
                          ),
                        ],
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