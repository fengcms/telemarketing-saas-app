import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 登录页 - 逐步引入 TDesign 组件进行兼容性测试
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _saveEmail = true;
  bool _savePassword = false;
  bool _isLoading = false;
  bool _isLocked = false;
  String? _errorMessage;
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
    _loadVersion();
    _emailCtrl.addListener(_onEmailChanged);
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

  void _onEmailChanged() {
    final text = _emailCtrl.text;
    final hasAt = text.contains('@');
    if (hasAt && !_isFullEmailMode) {
      setState(() => _isFullEmailMode = true);
    } else if (!hasAt && _isFullEmailMode) {
      setState(() => _isFullEmailMode = false);
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      setState(() => _version = 'v${info.version}');
    } catch (_) {
      setState(() => _version = 'v1.0.0');
    }
  }

  void _onLogin() {
    if (_isLoading || _isLocked) return;
    FocusScope.of(context).unfocus();
    setState(() { _isLoading = true; _errorMessage = null; });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final pwd = _passwordCtrl.text;
      if (pwd == 'error') {
        setState(() { _isLoading = false; _errorMessage = '邮箱或密码错误'; });
      } else if (pwd == 'locked') {
        setState(() { _isLoading = false; _isLocked = true; _errorMessage = '账号已锁定，请15分钟后再试'; });
        Future.delayed(const Duration(seconds: 15), () {
          if (mounted) setState(() { _isLocked = false; _errorMessage = null; });
        });
      } else {
        setState(() { _isLoading = false; });
        TDToast.showText('登录成功', context: context);
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
                  enabled: !_isLoading,
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
              enabled: !_isLoading && !_isLocked,
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
        _buildCheckbox('保存登录邮箱', _saveEmail,
            (v) => setState(() => _saveEmail = v!)),
        const SizedBox(width: 24),
        _buildCheckbox('保存登录密码', _savePassword,
            (v) => setState(() => _savePassword = v!)),
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
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TDButton(
        text: _isLoading ? '' : '登 录',
        theme: TDButtonTheme.primary,
        shape: TDButtonShape.round,
        disabled: _isLoading || _isLocked,
        onTap: _onLogin,
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

  Widget _buildError() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(TDIcons.error_circle,
            size: 16, color: Color(0xFFD54941)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            _errorMessage!,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFFD54941)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
