import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/project_list_controller.dart';
import '../../../../core/exceptions/validation_exception.dart';

/// プロジェクト作成ダイアログ
class CreateProjectDialog extends ConsumerStatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  ConsumerState<CreateProjectDialog> createState() =>
      _CreateProjectDialogState();
}

class _CreateProjectDialogState extends ConsumerState<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final controller = ref.read(projectListControllerProvider.notifier);
      final project = await controller.createProject(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(project);
      }
    } on ValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プロジェクトの作成に失敗しました: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(projectListControllerProvider);

    return AlertDialog(
      title: const Text('新規プロジェクト'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // プロジェクト名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'プロジェクト名',
                  hintText: '例: Webアプリ開発',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'プロジェクト名を入力してください';
                  }
                  if (value.length > 100) {
                    return 'プロジェクト名は100文字以内で入力してください';
                  }
                  return null;
                },
                autofocus: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // プロジェクト説明
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'プロジェクト説明（任意）',
                  hintText: '例: 顧客管理システムのWebアプリ',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                maxLength: 500,
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'プロジェクト説明は500文字以内で入力してください';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleCreate(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: controllerState.isLoading
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: controllerState.isLoading ? null : _handleCreate,
          child: controllerState.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Text('作成'),
        ),
      ],
    );
  }
}
