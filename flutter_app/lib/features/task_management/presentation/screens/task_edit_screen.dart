import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/task.dart';
import '../controllers/task_list_controller.dart';
import '../../../../core/exceptions/validation_exception.dart';
import '../../../../shared/widgets/offline_indicator.dart';

/// タスク作成・編集画面
class TaskEditScreen extends ConsumerStatefulWidget {
  const TaskEditScreen({
    super.key,
    required this.projectId,
    this.task,
  });

  final String projectId;
  final Task? task;

  @override
  ConsumerState<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends ConsumerState<TaskEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _nameController.text = widget.task!.name;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedDueDate = widget.task!.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.task != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithOfflineIndicator(
        title: _isEditMode ? 'タスク編集' : '新規タスク',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // タスク名入力
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'タスク名',
                  hintText: 'タスク名を入力してください',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task_alt),
                ),
                maxLength: 200,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'タスク名を入力してください';
                  }
                  if (value.trim().length > 200) {
                    return 'タスク名は200文字以内で入力してください';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // タスク説明入力
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'タスク説明（任意）',
                  hintText: 'タスクの詳細を入力してください',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLength: 1000,
                maxLines: 5,
                validator: (value) {
                  if (value != null && value.trim().length > 1000) {
                    return 'タスク説明は1000文字以内で入力してください';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // 期限選択
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('期限'),
                  subtitle: _selectedDueDate != null
                      ? Text(DateFormat('yyyy年MM月dd日').format(_selectedDueDate!))
                      : const Text('期限を設定（任意）'),
                  trailing: _selectedDueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedDueDate = null;
                                  });
                                },
                        )
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _isLoading ? null : _selectDueDate,
                ),
              ),
              const SizedBox(height: 32),

              // 作成/保存ボタン
              FilledButton(
                onPressed: _isLoading ? null : _handleSubmit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_isEditMode ? '保存' : '作成'),
              ),
              const SizedBox(height: 8),

              // キャンセルボタン
              OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 期限選択ダイアログを表示
  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      locale: const Locale('ja', 'JP'),
    );

    if (selectedDate != null && mounted) {
      setState(() {
        _selectedDueDate = selectedDate;
      });
    }
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
      final controller = ref.read(taskListControllerProvider.notifier);
      
      if (_isEditMode) {
        // タスク更新
        await controller.updateTask(
          taskId: widget.task!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          dueDate: _selectedDueDate,
        );

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('タスク情報を更新しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // タスク作成
        await controller.createTask(
          projectId: widget.projectId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          dueDate: _selectedDueDate,
        );

        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('タスクを作成しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
