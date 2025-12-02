class RuleModel {
  final String id;
  final String subjectId;
  final String kondisi;
  final String rekomendasi;
  final String materialId;

  RuleModel({
    required this.id,
    required this.subjectId,
    required this.kondisi,
    required this.rekomendasi,
    required this.materialId,
  });

  factory RuleModel.fromMap(String id, Map<String, dynamic> map) {
    return RuleModel(
      id: id,
      subjectId: map['subject_id'] ?? '',
      kondisi: map['kondisi'] ?? '',
      rekomendasi: map['rekomendasi'] ?? '',
      materialId: map['material_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_id': subjectId,
      'kondisi': kondisi,
      'rekomendasi': rekomendasi,
      'material_id': materialId,
    };
  }
}
