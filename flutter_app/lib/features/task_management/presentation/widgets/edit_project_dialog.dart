import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/project.dart';
import '../controllers/project_detail_controller.dart';
import '../../../../core/exceptions/validation_exception.dart';
import '../../../../core/exceptions/not_found_exception.dart';

/// プロジェクト編集ダイアログ
class EditProjectDialog extends ConsumerStatefulWidget {
  const EditProjectDialog({
    super.key,
    required this.project,
  });

  final Project project;

  /// ダイアログを表示
  ///
  /// [context] BuildContext
  /// [project] 編集対象のプロジェクト
  ///
  /// 戻り値: 編集された場合は更新後のProject、キャンセルされた場合はnull
  static Future<Project?> show({
    required BuildContext context,
    required Project project,
  }) async {
    return showDialog<Project>(
      context: context,
      builder: (context) => EditProjectDialog(project: project),
    );
  }

  @override
  ConsumerState<EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends ConsumerState<EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descriptionController = TextEditingController(
      text: widget.project.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('プロジェクト編集'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // プロジェクト名入力
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'プロジェクト名',
                  hintText: 'プロジェクト名を入力してください',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.folder),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'プロジェクト名を入力してください';
                  }
                  if (value.trim().length > 100) {
                    return 'プロジェクト名は100文字以内で入力してください';
                  }
                  return null;
                },
                enabled: !_isLoading,
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // プロジェクト説明入力
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'プロジェクト説明（任意）',
                  hintText: 'プロジェクトの説明を入力してください',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLength: 500,
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().length > 500) {
                    return 'プロジェクト説明は500文字以内で入力してください';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        // キャンセルボタン
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),

        // 保存ボタン
        FilledButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  /// フォーム送信処理
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final controller = ref.read(projectDetailControllerProvider.notifier);
      final updatedProject = await controller.updateProject(
        projectId: widget.project.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(updatedProject);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プロジェクト情報を更新しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on NotFoundException catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
