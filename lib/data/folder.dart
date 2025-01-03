// lib/data/folder.dart
class Folder {
  final int? folderId;
  final String folderName;

  Folder({this.folderId, required this.folderName});

  factory Folder.fromMap(Map<String, dynamic> json) => Folder(
    folderId: json['folderId'],
    folderName: json['folderName'],
  );

  Map<String, dynamic> toMap() {
    return {
      'folderId': folderId,
      'folderName': folderName,
    };
  }
}
