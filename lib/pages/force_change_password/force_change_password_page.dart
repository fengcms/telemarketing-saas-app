/// 强制改密页
///
/// 管理员重置用户密码后，系统检测到 [User.mustResetPassword] 为 true 时跳转至此页。
/// 用户需设置符合强度的新密码，确认后调用 POST /api/auth/change-password。
/// 成功后清空 Token 并跳转回登录页。
///
/// 设计文档参考：docs/design/page-design/02-强制改密页.md
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'password_rules_hint.dart';
import 'password_nav_bar.dart';

/// 强制改密页
///
/// 管理员重置用户密码后，系统检测到 [User.mustResetPassword] 为 true 时跳转至此页。
/// 用户需设置符合强度的新密码，确认后调用 POST /api/auth/change-password。
/// 成功后清空 Token 并跳转回登录页。
///
/// 设计文档参考：docs/design/page-design/02-强制改密页.md
class ForceChangePasswordPage extends ConsumerStatefulWidget {
  const ForceChangePasswordPage({super.key});

  @override
  ConsumerState<ForceChangePasswordPage> createState() =>
      _ForceChangePasswordPageState();
}

class _ForceChangePasswordPageState
    extends ConsumerState<ForceChangePasswordPage> {
  final TextEditingController _newPwdCtrl = TextEditingController();
  final TextEditingController _confirmPwdCtrl = TextEditingController();
  final FocusNode _newPwdFocus = FocusNode();
  final FocusNode _confirmPwdFocus = FocusNode();

  bool _obscureNewPwd = true;
  bool _obscureConfirmPwd = true;
  bool _isLoading = false;
  bool _passwordsMatch = true;
  String? _newPwdError;
  String? _confirmPwdError;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _newPwdCtrl.addListener(_onNewPasswordChanged);
    _confirmPwdCtrl.addListener(_onConfirmPasswordChanged);
  }

  @override
  void dispose() {
    _newPwdCtrl.removeListener(_onNewPasswordChanged);
    _confirmPwdCtrl.removeListener(_onConfirmPasswordChanged);
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _newPwdFocus.dispose();
    _confirmPwdFocus.dispose();
    super.dispose();
  }

  /// 新密码输入变化：更新强度指示器 + 实时校验一致性
  void _onNewPasswordChanged() {
    if (_confirmPwdCtrl.text.isNotEmpty) {
      _checkPasswordsMatch();
    }
    setState(() {});
  }

  /// 确认密码输入变化：实时校验一致性
  void _onConfirmPasswordChanged() {
    _checkPasswordsMatch();
    setState(() {});
  }

  /// 校验两次密码是否一致
  void _checkPasswordsMatch() {
    final confirm = _confirmPwdCtrl.text;
    if (confirm.isEmpty) {
      _passwordsMatch = true;
      _confirmPwdError = null;
    } else {
      _passwordsMatch = _newPwdCtrl.text == confirm;
      _confirmPwdError = _passwordsMatch ? null : '两次密码输入不一致';
    }
  }

  // ── 密码强度计算 ──

  /// 字符类型检查
  static bool _hasLowercase(String s) => s.contains(RegExp(r'[a-z]'));
  static bool _hasUppercase(String s) => s.contains(RegExp(r'[A-Z]'));
  static bool _hasDigit(String s) => s.contains(RegExp(r'[0-9]'));
  static bool _hasSpecial(String s) {
    const specials = '!@#\$%^&*()-_=+[]{}|;:\'",.<>?/`~';
    return s.split('').any((c) => specials.contains(c));
  }

  /// 计算密码强度等级
  /// 返回 (点亮段数, 等级文字, 颜色)
  (_PassStrengthLevel, String, Color) _calculateStrength(String pwd) {
    if (pwd.isEmpty) {
      return (_PassStrengthLevel.none, '', Colors.transparent);
    }

    int typeCount = 0;
    if (_hasLowercase(pwd)) typeCount++;
    if (_hasUppercase(pwd)) typeCount++;
    if (_hasDigit(pwd)) typeCount++;
    if (_hasSpecial(pwd)) typeCount++;

    final hasAllFour = typeCount == 4;
    final isLong = pwd.length >= 10;

    if (hasAllFour && isLong) {
      return (_PassStrengthLevel.strong, '强', const Color(0xFF2BA471));
    } else if (typeCount >= 3) {
      return (_PassStrengthLevel.medium, '中等', const Color(0xFFE37318));
    } else if (typeCount >= 1) {
      return (_PassStrengthLevel.weak, '弱', const Color(0xFFD54941));
    }
    return (_PassStrengthLevel.none, '', Colors.transparent);
  }

  /// 最低强度校验：长度 ≥ 8 且至少同时含字母和数字
  String? _validateNewPassword(String pwd) {
    if (pwd.isEmpty) return '请输入新密码';
    if (pwd.length < 8) return '密码至少 8 位';
    if (!(_hasLowercase(pwd) || _hasUppercase(pwd))) return '密码需包含字母';
    if (!_hasDigit(pwd)) return '密码需包含数字';
    return null;
  }

  // ── 提交 ──

  Future<void> _onSubmit() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    final newPwd = _newPwdCtrl.text;
    final confirmPwd = _confirmPwdCtrl.text;

    // 前端校验
    final newError = _validateNewPassword(newPwd);
    if (newError != null) {
      setState(() => _newPwdError = newError);
      return;
    }

    if (confirmPwd.isEmpty) {
      setState(() => _confirmPwdError = '请再次输入新密码');
      return;
    }

    if (!_passwordsMatch) {
      setState(() => _confirmPwdError = '两次密码输入不一致');
      return;
    }

    setState(() {
      _isLoading = true;
      _newPwdError = null;
      _confirmPwdError = null;
      _apiError = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .forceChangePassword(newPassword: newPwd);

    if (!mounted) return;

    if (success) {
      // 成功：显示 Toast 后跳转
      TDToast.showText('密码修改成功，请重新登录',
          context: context);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        // AuthNotifier 已将状态设为 unauthenticated，AuthGate 自动跳转登录页
      }
    } else {
      setState(() {
        _isLoading = false;
        _apiError = ref.read(authProvider).errorMessage;
      });
    }
  }

  /// 返回按钮确认弹窗
  Future<void> _onBack() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('退出确认',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        content: const Text('修改密码前无法使用系统功能，确定要退出吗？',
            style: TextStyle(fontSize: 15, color: Color(0xFF4E5969))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消',
                style: TextStyle(color: Color(0xFF4E5969))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('确定退出',
                style: TextStyle(color: Color(0xFF0052D9))),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      ref.read(authProvider.notifier).cancelForceChangePassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              // ── 主内容 ──
              SingleChildScrollView(
                child: Column(
                  children: [
                    PasswordNavBar(onBack: _onBack),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SecurityHint(),
                          const SizedBox(height: 24),
                          _buildNewPasswordInput(),
                          const SizedBox(height: 8),
                          _buildStrengthIndicator(),
                          const SizedBox(height: 16),
                          _buildConfirmPasswordInput(),
                          const SizedBox(height: 8),
                          const PasswordRuleHint(),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                          const SizedBox(height: 16),
                          _buildApiError(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 组件 ──



  Widget _buildNewPasswordInput() {
    final hasError = _newPwdError != null;
    final borderColor = hasError
        ? const Color(0xFFD54941)
        : _newPwdFocus.hasFocus
            ? const Color(0xFF0052D9)
            : const Color(0xFFE7E7E7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(TDIcons.key, size: 20, color: Color(0xFFA6A6A6)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _newPwdCtrl,
                  focusNode: _newPwdFocus,
                  enabled: !_isLoading,
                  obscureText: _obscureNewPwd,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF181818)),
                  decoration: const InputDecoration(
                    hintText: '请输入新密码',
                    hintStyle:
                        TextStyle(fontSize: 14, color: Color(0xFFC5C5C5)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _confirmPwdFocus.requestFocus(),
                ),
              ),
              GestureDetector(
                onTap: () =>
                    setState(() => _obscureNewPwd = !_obscureNewPwd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    _obscureNewPwd
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                    color: const Color(0xFFA6A6A6),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_newPwdError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(TDIcons.info_circle,
                    size: 14, color: Color(0xFFD54941)),
                const SizedBox(width: 4),
                Text(
                  _newPwdError!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFD54941)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStrengthIndicator() {
    final pwd = _newPwdCtrl.text;
    if (pwd.isEmpty) return const SizedBox.shrink();

    final (level, label, color) = _calculateStrength(pwd);
    final segments = switch (level) {
      _PassStrengthLevel.weak => 2,
      _PassStrengthLevel.medium => 5,
      _PassStrengthLevel.strong => 8,
      _PassStrengthLevel.none => 0,
    };

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(8, (i) {
              final isLit = i < segments;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isLit
                          ? color
                          : const Color(0x4DE7E7E7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmPasswordInput() {
    final hasError = _confirmPwdError != null;
    final borderColor = hasError
        ? const Color(0xFFD54941)
        : _confirmPwdFocus.hasFocus
            ? const Color(0xFF0052D9)
            : const Color(0xFFE7E7E7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(TDIcons.key, size: 20, color: Color(0xFFA6A6A6)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _confirmPwdCtrl,
                  focusNode: _confirmPwdFocus,
                  enabled: !_isLoading,
                  obscureText: _obscureConfirmPwd,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF181818)),
                  decoration: const InputDecoration(
                    hintText: '请再次输入新密码',
                    hintStyle:
                        TextStyle(fontSize: 14, color: Color(0xFFC5C5C5)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onSubmit(),
                ),
              ),
              GestureDetector(
                onTap: () => setState(
                    () => _obscureConfirmPwd = !_obscureConfirmPwd),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    _obscureConfirmPwd
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 20,
                    color: const Color(0xFFA6A6A6),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_confirmPwdError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(TDIcons.info_circle,
                    size: 14, color: Color(0xFFD54941)),
                const SizedBox(width: 4),
                Text(
                  _confirmPwdError!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFD54941)),
                ),
              ],
            ),
          ),
      ],
    );
  }


  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TDButton(
        text: _isLoading ? '' : '确 认',
        theme: TDButtonTheme.primary,
        shape: TDButtonShape.round,
        disabled: _isLoading,
        onTap: _onSubmit,
        iconWidget: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildApiError() {
    if (_apiError == null) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 200),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(TDIcons.error_circle,
              size: 16, color: Color(0xFFD54941)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _apiError!,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFFD54941)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// 密码强度等级枚举
enum _PassStrengthLevel { none, weak, medium, strong }
