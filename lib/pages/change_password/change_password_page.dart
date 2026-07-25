/// 修改密码页
///
/// 提供旧密码验证 + 新密码设置流程，密码强度实时检测。
/// 成功提交后端自增 tokenVersion 使所有旧 token 失效 → 强制重新登录。
/// 设计文档：docs/design/page-design/15-修改密码.md
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/widgets/app_dialog.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';

/// 修改密码页
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final TextEditingController _oldCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  /// 表单错误状态（null 表示该字段无错误）
  String? _oldError;
  String? _newError;
  String? _confirmError;

  /// 是否正在提交
  bool _submitting = false;

  /// 是否有过输入（用于返回脏检查）
  bool _hasInput = false;

  /// 是否已提交成功（防止 2s Toast 窗口内重复提交）
  bool _done = false;

  /// 密码强度等级
  int _strengthLevel = 0; // 0=隐藏, 1=弱, 2=中, 3=强, 4=非常强
  String _strengthText = '';
  Color _strengthColor = BrandColors.error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── 密码强度计算 ──

  /// 计算密码强度等级
  void _updateStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _strengthLevel = 0;
        _strengthText = '';
      });
      return;
    }

    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\/]'));
    final length = password.length;

    int level;
    String text;
    Color color;

    if (length >= 12 && hasLower && hasUpper && hasDigit && hasSpecial) {
      level = 4;
      text = '非常强';
      color = BrandColors.success;
    } else if (length >= 8 && hasLower && hasUpper && hasDigit && hasSpecial) {
      level = 3;
      text = '强';
      color = BrandColors.primary;
    } else if (length >= 8 && ((hasLower || hasUpper) && hasDigit)) {
      level = 2;
      text = '中';
      color = BrandColors.warning;
    } else {
      level = 1;
      text = '弱';
      color = BrandColors.error;
    }

    setState(() {
      _strengthLevel = level;
      _strengthText = text;
      _strengthColor = color;
    });
  }

  // ── 输入变化处理 ──

  void _onOldChanged(String value) {
    _hasInput = true;
    if (_oldError != null) setState(() => _oldError = null);
  }

  void _onNewChanged(String value) {
    _hasInput = true;
    if (_newError != null) setState(() => _newError = null);
    _updateStrength(value);
  }

  void _onConfirmChanged(String value) {
    _hasInput = true;
    if (_confirmError != null) setState(() => _confirmError = null);
  }

  // ── 表单校验 ──

  /// 提交前表单校验，返回是否通过
  bool _validate() {
    final old = _oldCtrl.text.trim();
    final newPwd = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    String? oldErr;
    String? newErr;
    String? confirmErr;

    // 1. 旧密码为空
    if (old.isEmpty) {
      oldErr = '请输入旧密码';
    }

    // 2. 新密码为空
    if (newPwd.isEmpty) {
      newErr = '请输入新密码';
    } else if (newPwd.length < 8) {
      // 3. 新密码不足 8 位
      newErr = '密码至少 8 位';
    } else if (newPwd == old) {
      // 4. 新密码与旧密码相同（前端前置校验）
      newErr = '新密码不能与旧密码相同';
    }

    // 5. 确认新密码为空
    if (confirm.isEmpty) {
      confirmErr = '请再次输入新密码';
    } else if (confirm != newPwd) {
      // 6. 两次密码不一致
      confirmErr = '两次输入的密码不一致';
    }

    setState(() {
      _oldError = oldErr;
      _newError = newErr;
      _confirmError = confirmErr;
    });

    return oldErr == null && newErr == null && confirmErr == null;
  }

  // ── 提交 ──

  Future<void> _onSubmit() async {
    if (_done) return;
    if (!_validate()) return;
    if (_submitting) return;

    setState(() => _submitting = true);

    final error = await ref.read(authProvider.notifier).changePassword(
          oldPassword: _oldCtrl.text.trim(),
          newPassword: _newCtrl.text,
        );

    if (!mounted) return;

    if (error != null) {
      // 后端返回的错误消息，判断字段显示到对应输入框
      setState(() => _submitting = false);
      if (error.contains('旧密码') || error.contains('old')) {
        setState(() => _oldError = error);
      } else if (error.contains('新密码') || error.contains('new') || error.contains('8')) {
        setState(() => _newError = error);
      } else {
        AppToast.show(context, error);
      }
      return;
    }

    // 成功：按钮恢复正常态（设计文档 §4.4），展示 Toast（§5.5 持续 2s），随后跳转登录页
    setState(() {
      _submitting = false;
      _done = true;
    });
    AppToast.show(context, '密码已修改，请重新登录');
    // Toast 展示完毕（2s）后再触发登录页跳转（清除任务栈），
    // 否则 AuthGate 会在状态变为未登录时立即卸载本页，Toast 来不及显示。
    await Future.delayed(const Duration(seconds: 2));
    // 先弹出导航栈（回到 AuthGate 根层），再切换为未登录态使 AuthGate 显示登录页
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    ref.read(authProvider.notifier).notifyPasswordChanged();
  }

  // ── 返回拦截（脏检查） ──

  Future<bool> _onWillPop() async {
    if (!_hasInput) return true;
    final confirmed = await AppDialog.confirm(
      context: context,
      title: '确认返回',
      content: '密码未修改，确定返回？',
      confirmText: '确定',
      cancelText: '取消',
      onConfirm: () {},
    );
    return confirmed == true;
  }

  // ── 构建 ──

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasInput && !_done,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _done) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: BrandColors.surface,
        appBar: AppBar(title: const Text('修改密码')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: BrandColors.border, width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 旧密码 ──
                _buildLabel('旧密码'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _oldCtrl,
                  obscure: _obscureOld,
                  onToggle: () => setState(() => _obscureOld = !_obscureOld),
                  onChanged: _onOldChanged,
                  error: _oldError,
                ),
                const SizedBox(height: 16),

                // ── 新密码 ──
                _buildLabel('新密码'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _newCtrl,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  onChanged: _onNewChanged,
                  error: _newError,
                ),

                // ── 密码强度指示器 ──
                if (_strengthLevel > 0) ...[
                  const SizedBox(height: 8),
                  _buildStrengthIndicator(),
                ],

                const SizedBox(height: 16),

                // ── 确认新密码 ──
                _buildLabel('确认新密码'),
                const SizedBox(height: 8),
                _buildPasswordField(
                  controller: _confirmCtrl,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onChanged: _onConfirmChanged,
                  error: _confirmError,
                ),

                const SizedBox(height: 16),

                // ── 密码规则提示 ──
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: BrandColors.textSecondary),
                    const SizedBox(width: 4),
                    const Text(
                      '密码至少 8 位',
                      style: TextStyle(
                        fontSize: 13,
                        color: BrandColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ── 确认按钮 ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _submitting ? null : _onSubmit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('确认修改'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 子组件 ──

  /// 输入框标签
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: BrandColors.textPrimary,
      ),
    );
  }

  /// 密码输入框（含显示/隐藏切换）
  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required ValueChanged<String> onChanged,
    String? error,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: obscure ? '••••••••' : '',
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: BrandColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
        errorText: error,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: BrandColors.error, width: 1),
        ),
      ),
    );
  }

  /// 密码强度指示器（4 段式）
  Widget _buildStrengthIndicator() {
    return Row(
      children: [
        // 4 段进度条
        ...List.generate(4, (i) {
          final filled = i < _strengthLevel;
          return Container(
            width: 28,
            height: 4,
            margin: const EdgeInsets.only(right: 2),
            decoration: BoxDecoration(
              color: filled ? _strengthColor : BrandColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 8),
        Text(
          _strengthText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _strengthColor,
          ),
        ),
      ],
    );
  }
}
