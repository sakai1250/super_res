// lib/data/memo.dart
class Memo {
  final int? id;
  final String title;
  final String? imagePath;
  final String createdAt;
  final int? folderId;
  final String? textContent; // nullの場合は未入力扱い

  Memo({
    this.id,
    required this.title,
    this.imagePath,
    required this.createdAt,
    this.folderId,
    this.textContent, // null可
  });

  factory Memo.fromMap(Map<String, dynamic> json) => Memo(
        id: json['id'],
        title: json['title'],
        imagePath: json['imagePath'],
        createdAt: json['createdAt'],
        folderId: json['folderId'],
        textContent: json['textContent'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imagePath': imagePath,
      'createdAt': createdAt,
      'folderId': folderId,
      'textContent': textContent,
    };
  }

  // textContentがnullなら"未入力"を返すプロパティを作る方法もある
  String get displayText => textContent ?? '未入力';
}
