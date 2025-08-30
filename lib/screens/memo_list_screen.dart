// lib/screens/memo_list_screen.dart
import 'package:flutter/material.dart';
import '../data/memo_dao.dart';
import '../data/memo.dart';
import '../data/folder_dao.dart';
import '../data/db_provider.dart';
import '../screens/photo_detail_screen.dart';
import '../widgets/fading_image.dart';
import '../widgets/shimmer_skeleton.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class MemoListScreen extends StatefulWidget {
  @override
  _MemoListScreenState createState() => _MemoListScreenState();
}

class _MemoListScreenState extends State<MemoListScreen> {
  final MemoDao _memoDao = MemoDao();
  List<Memo> _memoList = [];
  String _searchQuery = "";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    setState(() => _loading = true);
    final memos = await _memoDao.searchMemos(_searchQuery);
    if (!mounted) return;
    setState(() {
      _memoList = memos;
      _loading = false;
    });
  }
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _loadMemos();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: _loadMemos,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('メモ一覧'),
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  tooltip: 'ギャラリーから追加',
                  icon: const Icon(Icons.photo_library_outlined),
                  onPressed: _importFromGallery,
                ),
                IconButton(
                  tooltip: '写真を撮影',
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: _importFromCamera,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search text',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ShimmerListTile(),
                  childCount: 6,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final memo = _memoList[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: memo.imagePath != null
                              ? GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PhotoDetailScreen(
                                          imagePath: memo.imagePath!,
                                          memo: memo,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FadingImageFile(
                                      file: File(memo.imagePath!),
                                      width: 64,
                                      height: 64,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.image_not_supported, size: 48),
                          title: Text(
                            memo.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(
                            memo.textContent ?? '（メモなし）',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      ),
                    );
                  },
                  childCount: _memoList.length,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCameraPressed,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Future<void> _importFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final folderId = await _selectFolder();
    if (folderId == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
    final newMemo = Memo(
      title: "Gallery Memo",
      imagePath: savedImage.path,
      createdAt: DateTime.now().toString(),
      folderId: folderId,
    );
    await _memoDao.insertMemo(newMemo);
    await _loadMemos();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ギャラリーから追加しました')),
    );
  }

  Future<void> _importFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    final folderId = await _selectFolder();
    if (folderId == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
    final newMemo = Memo(
      title: "Camera Memo",
      imagePath: savedImage.path,
      createdAt: DateTime.now().toString(),
      folderId: folderId,
    );
    await _memoDao.insertMemo(newMemo);
    await _loadMemos();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('写真を追加しました')),
    );
  }

  Future<int?> _selectFolder() async {
    final folderDao = FolderDao();
    final allFolders = await folderDao.getAllFolders();
    if (allFolders.isEmpty) {
      if (!mounted) return null;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('フォルダがありません'),
          content: const Text('先にフォルダを作成してください。'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
          ],
        ),
      );
      return null;
    }
    int? selectedFolderId;
    if (!mounted) return null;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('フォルダを選択'),
          content: SingleChildScrollView(
            child: Column(
              children: allFolders.map((folder) {
                return ListTile(
                  title: Text(folder.folderName),
                  onTap: () {
                    selectedFolderId = folder.folderId;
                    Navigator.of(ctx).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                selectedFolderId = null;
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );
    return selectedFolderId;
  }

  Future<void> _onCameraPressed() async {
    // カメラ or ギャラリーから画像を取得して保存
    // 保存後にDBにinsertし、_loadMemosで再読み込み
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    // アプリ専用ディレクトリへの保存
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path)
        .copy('${appDir.path}/$fileName');

    // フォルダ一覧を取得してユーザーに選ばせる
    final folderDao = FolderDao();
    final allFolders = await folderDao.getAllFolders();

    // ダイアログでフォルダを選択
    int? selectedFolderId;
    await showDialog(
      context: context,
      builder: (ctx) {
      return AlertDialog(
        title: Text('Choose Folder'),
        content: SingleChildScrollView(
          child: Column(
            children: allFolders.map((folder) {
              return ListTile(
                title: Text(folder.folderName),
                onTap: () {
                  selectedFolderId = folder.folderId;
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ),
        ),
      );
    },
  );
    // フォルダが選ばれていないなら中断
    if (selectedFolderId == null) return;
    // DBへ登録
    final newMemo = Memo(
      title: "Sample Memo",
      imagePath: savedImage.path,
      createdAt: DateTime.now().toString(),
      folderId: selectedFolderId, // ★ フォルダIDをセット
    );
    await _memoDao.insertMemo(newMemo);
    _loadMemos();
  }
}
