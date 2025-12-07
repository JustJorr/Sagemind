class KnowledgeModel {
  final String id;
  final String subjectId;
  final String judul;
  final String konten;
  final String jenis;
  final String kesulitan;
  final String? videoUrl; // NEW

  KnowledgeModel({
    required this.id,
    required this.subjectId,
    required this.judul,
    required this.konten,
    required this.jenis,
    required this.kesulitan,
    this.videoUrl, // NEW
  });

  factory KnowledgeModel.fromMap(String id, Map<String, dynamic> map) {
    return KnowledgeModel(
      id: id,
      subjectId: map['subject_id'] ?? '',
      judul: map['judul'] ?? '',
      konten: map['konten'] ?? '',
      jenis: map['jenis'] ?? 'konseptual',
      kesulitan: map['kesulitan'] ?? 'kelas10',
      videoUrl: map['video_url'], // NEW
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'judul': judul,
      'konten': konten,
      'jenis': jenis,
      'kesulitan': kesulitan,
      'video_url': videoUrl, // NEW
    };
  }
}
