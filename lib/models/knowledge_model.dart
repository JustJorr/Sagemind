class KnowledgeModel {
  final String id;
  final String subjectId;
  final String jenis;
  final String judul;
  final String konten;

  KnowledgeModel({
    required this.id,
    required this.subjectId,
    required this.jenis,
    required this.judul,
    required this.konten,
  });

  factory KnowledgeModel.fromMap(String id, Map<String, dynamic> map) {
    return KnowledgeModel(
      id: id,
      subjectId: map['subject_id'] ?? '',
      jenis: map['jenis'] ?? '',
      judul: map['judul'] ?? '',
      konten: map['konten'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'jenis': jenis,
      'judul': judul,
      'konten': konten,
    };
  }
}
