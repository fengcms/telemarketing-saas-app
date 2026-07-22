import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/auth_provider.dart';

/// 登录页
///
/// 提供邮箱+密码登录功能，接入真实 POST /api/auth/login 接口。
/// 自动处理 401、423、429 等错误。
/// 支持「保存登录邮箱」「保存登录密码」本地持久化。
///
/// 设计文档参考：docs/design/page-design/01-登录页.md
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _saveEmail = true;
  bool _savePassword = false;
  String _version = '';
  String _selectedDomain = 'qq.com';
  bool _isFullEmailMode = false;
  bool _isDomainDropdownOpen = false;

  static const List<String> _domainOptions = [
    'qq.com', '163.com', '126.com', 'sina.com',
    'gmail.com', 'outlook.com', 'foxmail.com', 'yeah.net',
  ];

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_onEmailChanged);
    // 延迟一帧加载已保存凭据（确保 Provider 可用）
    Future.microtask(() {
      _loadVersion();
      _loadSavedCredentials();
    });
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_onEmailChanged);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── 已保存凭据加载 ──

  /// 加载已保存的邮箱和密码
  Future<void> _loadSavedCredentials() async {
    if (!mounted) return;
    final storage = ref.read(localStorageServiceProvider);

    // 先恢复复选框状态（在填充数据之前，避免状态覆盖）
    final saveEmailChecked = await storage.loadSaveEmailChecked();
    final savePasswordChecked = await storage.loadSavePasswordChecked();

    if (!mounted) return;
    setState(() {
      _saveEmail = saveEmailChecked;
      _savePassword = savePasswordChecked;
    });

    // 加载已保存邮箱
    final savedEmail = await storage.loadEmail();
    if (savedEmail != null && savedEmail.isNotEmpty) {
      final atIndex = savedEmail.indexOf('@');
      if (atIndex > 0) {
        final prefix = savedEmail.substring(0, atIndex);
        final domain = savedEmail.substring(atIndex + 1);
        if (_domainOptions.contains(domain)) {
          // 后缀在预设列表中 → 前缀模式
          setState(() {
            _emailCtrl.text = prefix;
            _selectedDomain = domain;
            _isFullEmailMode = false;
          });
        } else {
          // 后缀不在预设列表中 → 完整邮箱模式
          setState(() {
            _emailCtrl.text = savedEmail;
            _isFullEmailMode = true;
          });
        }
      } else {
        // 不含 @ → 直接填入前缀
        setState(() {
          _emailCtrl.text = savedEmail;
        });
      }
    }

    // 加载已保存密码（仅在复选框勾选时填充）
    if (_savePassword) {
      final savedPassword = await storage.loadPassword();
      if (savedPassword != null && savedPassword.isNotEmpty) {
        setState(() {
          _passwordCtrl.text = savedPassword;
        });
      }
    }

  }

  /// 登录成功后保存凭据
  Future<void> _saveCredentials() async {
    final storage = ref.read(localStorageServiceProvider);
    final email = _getEmail();
    final password = _passwordCtrl.text;

    // 保存复选框状态
    await storage.saveSaveEmailChecked(_saveEmail);
    await storage.saveSavePasswordChecked(_savePassword);

    // 保存邮箱
    if (_saveEmail && email != null) {
      await storage.saveEmail(email);
    } else {
      await storage.clearEmail();
    }

    // 保存密码
    if (_savePassword && password.isNotEmpty) {
      await storage.savePassword(password);
      if (mounted) {
        TDToast.showText('密码已加密保存', context: context);
      }
    } else {
      await storage.clearPassword();
    }
  }

  /// 邮箱输入变化处理（@ 自动切换完整邮箱模式）
  void _onEmailChanged() {
    final text = _emailCtrl.text;
    final hasAt = text.contains('@');
    if (hasAt && !_isFullEmailMode) {
      setState(() => _isFullEmailMode = true);
    } else if (!hasAt && _isFullEmailMode) {
      setState(() => _isFullEmailMode = false);
    }
  }

  /// 加载 APP 版本号
  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'v${info.version}');
    } catch (_) {
      if (mounted) setState(() => _version = 'v1.0.0');
    }
  }

  /// 拼接完整邮箱
  String? _getEmail() {
    final text = _emailCtrl.text.trim().toLowerCase();
    if (text.isEmpty) return null;
    if (_isFullEmailMode) return text;
    return '$text@$_selectedDomain';
  }

  /// 登录按钮点击处理
  void _onLogin() {
    final authState = ref.read(authProvider);
    if (authState.status == AuthStatus.authenticating) return;

    // 校验表单
    String? emailErr;
    String? pwdErr;

    if (_isFullEmailMode) {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        emailErr = '请输入邮箱地址';
      } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email)) {
        emailErr = '请输入有效的邮箱地址';
      }
    } else {
      final prefix = _emailCtrl.text.trim();
      if (prefix.isEmpty) {
        emailErr = '请输入邮箱地址';
      } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+$').hasMatch(prefix)) {
        emailErr = '请输入有效的邮箱前缀';
      }
    }

    if (_passwordCtrl.text.isEmpty) {
      pwdErr = '请输入密码';
    }

    // 简单的错误提示显示（使用 SnackBar）
    if (emailErr != null) {
      TDToast.showText(emailErr, context: context);
      return;
    }
    if (pwdErr != null) {
      TDToast.showText(pwdErr, context: context);
      return;
    }

    // 拼接邮箱
    FocusScope.of(context).unfocus();
    final email = _isFullEmailMode
        ? _emailCtrl.text.trim().toLowerCase()
        : '${_emailCtrl.text.trim().toLowerCase()}@$_selectedDomain';

    // 调用登录 API
    ref.read(authProvider.notifier).login(
      email: email,
      password: _passwordCtrl.text,
    ).then((success) {
      if (success && mounted) {
        _saveCredentials();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 主内容
            SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height
                    - MediaQuery.of(context).padding.top
                    - MediaQuery.of(context).padding.bottom,
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildLogo(),
                    const SizedBox(height: 12),
                    const Text('电销工作台',
                        style: TextStyle(fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF181818))),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          _buildEmailInput(),
                          const SizedBox(height: 16),
                      _buildPasswordInput(),
                      const SizedBox(height: 16),
                      _buildOptions(),
                      const SizedBox(height: 16),
                      _buildLoginButton(),
                      const SizedBox(height: 16),
                      _buildError(),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                Text(_version,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFA6A6A6))),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        // 域名下拉覆盖层（浮动在最上层，不参与布局流）
        if (_isDomainDropdownOpen)
          Positioned(
            left: 32,
            right: 32,
            top: MediaQuery.of(context).size.height * 0.35,
            child: _buildDomainDropdown(),
          ),
      ],
      ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0052D9).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(TDIcons.call, size: 36, color: Color(0xFF0052D9)),
    );
  }

  Widget _buildEmailInput() {
    final borderColor =
        _emailFocus.hasFocus
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
              const Icon(TDIcons.mail, size: 20, color: Color(0xFFA6A6A6)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  enabled: ref.watch(authProvider).status != AuthStatus.authenticating,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF181818)),
                  decoration: InputDecoration(
                    hintText: _isFullEmailMode ? '请输入完整邮箱地址' : '请输入邮箱前缀',
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFC5C5C5)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
              ),
              if (!_isFullEmailMode) ...[
                SizedBox(
                  height: 24,
                  child: VerticalDivider(width: 1, thickness: 1, color: const Color(0xFFE7E7E7)),
                ),
                _buildDomainSelector(),
              ],
              if (!_isFullEmailMode) const SizedBox(width: 4),
            ],
          ),
        ),
        // 域名下拉已移至 Stack 覆盖层
      ],
    );
  }

  Widget _buildDomainSelector() {
    return GestureDetector(
      onTap: () => setState(() => _isDomainDropdownOpen = !_isDomainDropdownOpen),
      child: Container(
        width: 120,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text('@$_selectedDomain',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF4E5969)),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isDomainDropdownOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(TDIcons.chevron_down, size: 16, color: Color(0xFFA6A6A6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainDropdown() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _domainOptions.length,
          itemBuilder: (context, index) {
            final domain = _domainOptions[index];
            final isSelected = domain == _selectedDomain;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDomain = domain;
                  _isDomainDropdownOpen = false;
                });
              },
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '@$domain',
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? const Color(0xFF0052D9) : const Color(0xFF4E5969),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, size: 18, color: Color(0xFF0052D9)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPasswordInput() {
    final borderColor =
        _passwordFocus.hasFocus
            ? const Color(0xFF0052D9)
            : const Color(0xFFE7E7E7);
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(TDIcons.lock_on,
              size: 20, color: Color(0xFFA6A6A6)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _passwordCtrl,
              focusNode: _passwordFocus,
              enabled: ref.watch(authProvider).status != AuthStatus.authenticating,
              obscureText: _obscurePassword,
              style: const TextStyle(
                  fontSize: 15, color: Color(0xFF181818)),
              decoration: const InputDecoration(
                hintText: '请输入密码',
                hintStyle: TextStyle(
                    fontSize: 14, color: Color(0xFFC5C5C5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 16),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onLogin(),
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                size: 20,
                color: const Color(0xFFA6A6A6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Row(
      children: [
        _buildCheckbox('保存登录邮箱', _saveEmail, (v) {
          setState(() => _saveEmail = v!);
          ref.read(localStorageServiceProvider).saveSaveEmailChecked(_saveEmail);
        }),
        const SizedBox(width: 24),
        _buildCheckbox('保存登录密码', _savePassword, (v) {
          setState(() => _savePassword = v!);
          ref.read(localStorageServiceProvider).saveSavePasswordChecked(_savePassword);
        }),
      ],
    );
  }

  Widget _buildCheckbox(
      String label, bool checked, ValueChanged<bool?> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            checked
                ? Icons.check_box
                : Icons.check_box_outline_blank,
            size: 20,
            color: checked
                ? const Color(0xFF0052D9)
                : const Color(0xFFDCDCDC),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7A90))),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TDButton(
        text: isLoading ? '' : '登 录',
        theme: TDButtonTheme.primary,
        shape: TDButtonShape.round,
        disabled: isLoading,
        onTap: _onLogin,
        iconWidget: isLoading
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

  Widget _buildError() {
    final errorMessage = ref.watch(authProvider).errorMessage;
    if (errorMessage == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(TDIcons.error_circle,
            size: 16, color: Color(0xFFD54941)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            errorMessage,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFFD54941)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
