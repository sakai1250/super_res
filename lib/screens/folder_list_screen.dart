import 'package:flutter/material.dart';
import '../data/folder.dart';

class FolderListScreen extends StatelessWidget {
  final List<Folder> folderList;

  const FolderListScreen({required this.folderList});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: ValueKey(folderList.length),
      itemCount: folderList.length,
      itemBuilder: (context, index) {
        final folder = folderList[index];
        return ListTile(
          key: ValueKey(folder.folderId),
          title: Text(folder.folderName),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/photoList',
              arguments: folder.folderId,
            );
          },
        );
      },
    );
  }
}
