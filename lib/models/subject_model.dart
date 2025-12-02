class SubjectModel {
  final String id;
  final String nama;
  final String deskripsi;

  SubjectModel({
    required this.id,
    required this.nama,
    required this.deskripsi,
  });

  factory SubjectModel.fromMap(String id, Map<String, dynamic> map) {
    return SubjectModel(
      id: id,
      nama: map['nama'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'deskripsi': deskripsi,
    };
  }
}
