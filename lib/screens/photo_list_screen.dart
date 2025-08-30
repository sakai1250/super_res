import 'package:flutter/material.dart';
import '../data/memo_dao.dart';
import '../data/memo.dart';
import '../data/folder_dao.dart';
import 'photo_detail_screen.dart';
import 'dart:io';
import '../widgets/fading_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../widgets/shimmer_skeleton.dart';

class PhotoListScreen extends StatefulWidget {
  final int folderId;

  PhotoListScreen({required this.folderId});

  @override
  _PhotoListScreenState createState() => _PhotoListScreenState();
}

class _PhotoListScreenState extends State<PhotoListScreen> {
  final MemoDao _memoDao = MemoDao();
  List<Memo> _memoList = [];
  String? _folderName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMemosByFolder();
    _loadFolderName();
  }

  Future<void> _loadFolderName() async {
    final dao = FolderDao();
    final folder = await dao.getFolderById(widget.folderId);
    if (!mounted) return;
    setState(() {
      _folderName = folder?.folderName;
    });
  }

  Future<void> _loadMemosByFolder() async {
    setState(() => _loading = true);
    final memos = await _memoDao.getMemosByFolder(widget.folderId);
    if (!mounted) return;
    setState(() {
      _memoList = memos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator.adaptive(
        onRefresh: _loadMemosByFolder,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: Text(_folderName != null ? 'フォルダ: ' + _folderName! : 'フォルダ: ${widget.folderId}'),
              floating: false,
              pinned: true,
              actions: [
                IconButton(
                  tooltip: 'ギャラリーから追加',
                  icon: const Icon(Icons.photo_library_outlined),
                  onPressed: _addToCurrentFolderFromGallery,
                ),
                IconButton(
                  tooltip: '写真を撮影',
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: _addToCurrentFolderFromCamera,
                ),
              ],
            ),
            if (_loading)
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const ShimmerGridTile(),
                    childCount: 12,
                  ),
                ),
              )
            else if (_memoList.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No photos available')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final memo = _memoList[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PhotoDetailScreen(
                                memo: memo,
                                imagePath: memo.imagePath!,
                              ),
                            ),
                          );
                        },
                        child: memo.imagePath != null
                            ? Hero(
                                tag: 'photo_${memo.id}', // 各画像に一意のタグを設定
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: FadingImageFile(
                                    file: File(memo.imagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey,
                                child: const Icon(Icons.broken_image),
                              ),
                      );
                    },
                    childCount: _memoList.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCurrentFolderFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
    final newMemo = Memo(
      title: "Gallery Memo",
      imagePath: savedImage.path,
      createdAt: DateTime.now().toString(),
      folderId: widget.folderId,
    );
    await _memoDao.insertMemo(newMemo);
    await _loadMemosByFolder();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ギャラリーから追加しました')),
    );
  }

  Future<void> _addToCurrentFolderFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedFile.path);
    final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
    final newMemo = Memo(
      title: "Camera Memo",
      imagePath: savedImage.path,
      createdAt: DateTime.now().toString(),
      folderId: widget.folderId,
    );
    await _memoDao.insertMemo(newMemo);
    await _loadMemosByFolder();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('写真を追加しました')),
    );
  }
}
