import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learn_n/core/provider/user_color_provider.dart';
import 'package:learn_n/core/provider/user_provider.dart';
import 'package:learn_n/core/widgets/learnn_icon.dart';
import 'package:learn_n/core/widgets/loading.dart';
import 'package:learn_n/features/home/folder/provider/folder_provider.dart';
import 'package:learn_n/features/home/folder/widget/folder_model_ken.dart';
import 'package:learn_n/features/home/learnn%20AI/ai.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FolderPage extends ConsumerStatefulWidget {
  const FolderPage({super.key});

  @override
  _FolderPageState createState() => _FolderPageState();
}

class _FolderPageState extends ConsumerState<FolderPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _folders = [];
  String searchQuery = '';
  Map<String, int> _folderPositions = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_updateSearchQuery);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = ref.watch(userIdProvider);
    if (userId != null) {
      _loadFolderOrder(userId);
    }
  }

  void _updateSearchQuery() {
    setState(() {
      searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadFolderOrder(userId) async {
    final prefs = await SharedPreferences.getInstance();
    final folderOrder = prefs.getStringList('folderOrder_$userId');
    if (folderOrder != null) {
      setState(() {
        _folderPositions = {
          for (var item in folderOrder)
            item.split(':')[0]: int.parse(item.split(':')[1])
        };
      });
    }
  }

  Future<void> _saveFolderOrder(userId) async {
    final prefs = await SharedPreferences.getInstance();
    final folderOrder = _folderPositions.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
    await prefs.setStringList('folderOrder_$userId', folderOrder);
  }

  void _onReorder(int oldIndex, int newIndex) {
    final userId = ref.watch(userIdProvider);
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _folders.removeAt(oldIndex);
      _folders.insert(newIndex, item);

      for (int i = 0; i < _folders.length; i++) {
        _folderPositions[_folders[i].id] = i;
      }
    });
    _saveFolderOrder(userId);
  }

  List<DocumentSnapshot> _filterFolders(List<DocumentSnapshot> docs) {
    return docs.where((folderDoc) {
      final folderData = folderDoc.data() as Map<String, dynamic>;
      final folderName = folderData['folderName'] as String;
      return folderName.toLowerCase().contains(searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userColor = ref.watch(userColorProvider);
    final userId = ref.watch(userIdProvider);
    final folderSnapshot = ref.watch(folderStreamProvider);
    final textIconColor = ref.watch(textIconColorProvider);

    return Scaffold(
      backgroundColor: getShade(userColor, 600),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: userColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 5, 13, 5),
                    child: TextFormField(
                      controller: _searchController,
                      style: TextStyle(
                        fontFamily: 'Arial',
                        color: textIconColor,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        focusColor: textIconColor,
                        hintText: 'Search Folder',
                        hintStyle: TextStyle(
                          fontFamily: 'PressStart2P',
                          color: textIconColor,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: textIconColor,
                        ),
                        filled: true,
                        fillColor: getShade(userColor, 600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: textIconColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: folderSnapshot.when(
                  data: (snapshot) {
                    final docs = snapshot.docs;
                    _folders = _filterFolders(docs.where((folderDoc) {
                      final folderData = folderDoc.data();
                      final accessUsers =
                          List<String>.from(folderData['accessUsers']);
                      return folderData['creator'] == userId ||
                          accessUsers.contains(userId);
                    }).toList());

                    _folders.sort((a, b) {
                      final aPos = _folderPositions[a.id] ?? 0;
                      final bPos = _folderPositions[b.id] ?? 0;
                      return aPos.compareTo(bPos);
                    });

                    if (_folders.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: SingleChildScrollView(
                          child: Center(
                            child: Column(
                              children: [
                                Lottie.asset('assets/lottie/folders.json'),
                                Text(
                                  'No Libraries here\nCreate one by clicking the\nAdd Button.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'PressStart2P',
                                    color: textIconColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ReorderableListView.builder(
                      itemCount: _folders.length + 1,
                      onReorder: _onReorder,
                      itemBuilder: (context, index) {
                        if (index == _folders.length) {
                          return const ListTile(
                            key: ValueKey('dummy_space'),
                            title: SizedBox(height: 50),
                          );
                        }

                        final folderDoc = _folders[index];
                        final folderData =
                            folderDoc.data() as Map<String, dynamic>;
                        final isImported =
                            List<String>.from(folderData['accessUsers'])
                                .contains(userId);

                        return ListTile(
                          key: ValueKey(folderDoc.id),
                          title: FolderModelKen(
                            folderId: folderDoc.id,
                            folderColor: hexToColor(folderData['color']),
                            folderName: folderData['folderName'],
                            description: folderData['description'],
                            isImported: isImported,
                            userId: userId!,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Loading(),
                  error: (error, stackTrace) =>
                      Center(child: Text('Error: $error')),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 65,
            left: 0,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
              icon: LearnNIcon(
                color: textIconColor,
                size: 80,
                icon: Icons.smart_toy,
                shadowColor: getShade(userColor, 500),
                offset: const Offset(1, 1),
                blur: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
