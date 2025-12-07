class KnowledgeModel {
  final String id;
  final String subjectId;
  final String judul;
  final String konten;
  final String jenis;
  final String kesulitan;
  final String? videoUrl;
  final List<Map<String, String>>? documents; 

  KnowledgeModel({
    required this.id,
    required this.subjectId,
    required this.judul,
    required this.konten,
    required this.jenis,
    required this.kesulitan,
    this.videoUrl,
    this.documents,
  });

  factory KnowledgeModel.fromMap(String id, Map<String, dynamic> data) {
    return KnowledgeModel(
      id: id,
      subjectId: data['subject_id'] ?? data['subjectId'] ?? '',
      judul: data['judul'] ?? '',
      konten: data['konten'] ?? '',
      jenis: data['jenis'] ?? '',
      kesulitan: data['kesulitan'] ?? '',
      videoUrl: data['videoUrl'] ?? data['video_url'],
      documents: data['documents'] != null
          ? List<Map<String, String>>.from(
              (data['documents'] as List).map(
                (x) => Map<String, String>.from(x as Map),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subjectId': subjectId,
      'judul': judul,
      'konten': konten,
      'jenis': jenis,
      'kesulitan': kesulitan,
      'videoUrl': videoUrl,
      'documents': documents ?? [],
    };
  }
}
