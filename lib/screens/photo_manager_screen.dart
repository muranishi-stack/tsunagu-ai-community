// PhotoManagerScreen — Add / remove / reorder profile photos
// =====================================================
// Up to 6 photos. Slot 0 is the main photo shown on Discover.
// Phase 1.6 - TSUNAGU

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class PhotoManagerScreen extends StatefulWidget {
  const PhotoManagerScreen({super.key});

  @override
  State<PhotoManagerScreen> createState() => _PhotoManagerScreenState();
}

class _PhotoManagerScreenState extends State<PhotoManagerScreen> {
  static const int maxPhotos = 6;
  final _svc = UserService();

  UserProfile? _profile;
  List<String> _photos = []; // Working copy
  bool _loading = true;
  bool _saving = false;
  String? _error;
  int? _uploadingSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final p = await _svc.getCurrentUserProfile();
      if (!mounted) return;
      if (p == null) {
        setState(() {
          _error = 'プロフィールが見つかりません';
          _loading = false;
        });
        return;
      }
      setState(() {
        _profile = p;
        _photos = List.from(p.photos);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '読込エラー: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pickAndUpload(int targetSlot) async {
    if (_uploadingSlot != null || _saving) return;
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      if (xfile == null) return;
      setState(() => _uploadingSlot = targetSlot);
      final bytes = await xfile.readAsBytes();
      final uid = _svc.currentUid;
      if (uid == null) throw Exception('未ログイン');

      final url = await _svc.uploadProfilePhotoBytes(
        uid: uid,
        bytes: bytes,
        slot: targetSlot,
      );

      setState(() {
        if (targetSlot < _photos.length) {
          _photos[targetSlot] = url;
        } else {
          _photos.add(url);
        }
      });

      // Firestoreにも反映
      await _persistPhotos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真を追加しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アップロードに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingSlot = null);
    }
  }

  Future<void> _deletePhoto(int index) async {
    if (_photos.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('プロフィール写真は最低1枚必要です')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('この写真を削除しますか？'),
        content: const Text('この操作は取り消せません'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final removed = _photos[index];
    setState(() => _photos.removeAt(index));
    try {
      await _persistPhotos();
      // Storage側の物理削除はベストエフォート (失敗してもFirestoreは更新済み)
      final uid = _svc.currentUid;
      if (uid != null) {
        try {
          await _svc.deleteProfilePhoto(uid, index);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真を削除しました')),
        );
      }
      if (kDebugMode) debugPrint('Removed photo URL: $removed');
    } catch (e) {
      // 失敗したら戻す
      setState(() => _photos.insert(index, removed));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _persistPhotos() async {
    if (_profile == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = _profile!.copyWith(
        photos: List.from(_photos),
        updatedAt: DateTime.now(),
      );
      await _svc.updateProfile(updated);
      _profile = updated;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setAsMain(int index) async {
    if (index == 0) return;
    final newOrder = List<String>.from(_photos);
    final selected = newOrder.removeAt(index);
    newOrder.insert(0, selected);
    setState(() => _photos = newOrder);
    try {
      await _persistPhotos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メイン写真に設定しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('変更に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写真を管理',
            style: TextStyle(fontSize: 16, letterSpacing: 2)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '写真は最大$maxPhotos枚まで登録できます。\n1枚目がメイン写真として表示されます。',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: maxPhotos,
            itemBuilder: (context, index) {
              if (index < _photos.length) {
                return _buildPhotoTile(index, _photos[index]);
              }
              return _buildAddTile(index);
            },
          ),
          const SizedBox(height: 24),
          if (_saving)
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('保存中...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoTile(int index, String url) {
    final isMain = index == 0;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 0.75,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, p) {
                if (p == null) return child;
                return Container(
                  color: AppTheme.paleGrey,
                  child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.paleGrey,
                child: const Icon(Icons.broken_image, color: AppTheme.grey),
              ),
            ),
          ),
        ),
        if (isMain)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.vermillion,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'メイン',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        Positioned(
          top: 0,
          right: 0,
          child: PopupMenuButton<String>(
            icon: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.more_vert,
                  color: Colors.white, size: 16),
            ),
            onSelected: (value) {
              if (value == 'main') _setAsMain(index);
              if (value == 'delete') _deletePhoto(index);
            },
            itemBuilder: (_) => [
              if (!isMain)
                const PopupMenuItem(
                    value: 'main',
                    child: Row(children: [
                      Icon(Icons.star_outline, size: 18),
                      SizedBox(width: 8),
                      Text('メインに設定')
                    ])),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('削除', style: TextStyle(color: Colors.red))
                  ])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddTile(int slot) {
    final loading = _uploadingSlot == slot;
    return InkWell(
      onTap: loading ? null : () => _pickAndUpload(slot),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: Theme.of(context).dividerColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 28,
                        color: Theme.of(context).iconTheme.color?.withValues(
                              alpha: 0.5,
                            )),
                    const SizedBox(height: 6),
                    Text('写真を追加',
                        style: TextStyle(
                            fontSize: 10,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color)),
                  ],
                ),
        ),
      ),
    );
  }
}
