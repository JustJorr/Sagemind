class KnowledgeModel {
  final String id;
  final String subjectId; 
  final String judul;
  final String konten;
  final String jenis; 
  final String kesulitan; 

  KnowledgeModel({
    required this.id,
    required this.subjectId,
    required this.judul,
    required this.konten,
    required this.jenis,
    required this.kesulitan,
  });

  factory KnowledgeModel.fromMap(String id, Map<String, dynamic> map) {
    return KnowledgeModel(
      id: id,
      subjectId: map['subject_id'] ?? '',
      judul: map['judul'] ?? '',
      konten: map['konten'] ?? '',
      jenis: map['jenis'] ?? 'konseptual',
      kesulitan: map['kesulitan'] ?? 'kelas10',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'judul': judul,
      'konten': konten,
      'jenis': jenis,
      'kesulitan': kesulitan,
    };
  }
}