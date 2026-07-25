/// 设置页
///
/// 提供密码修改入口、退出登录/全设备退出、关于信息查看等功能。
/// 页面进入时后台静默请求 /health 获取后端版本号。
/// 设计文档：docs/design/page-design/19-设置页.md
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:telemarketing_app/pages/coming_soon_page.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/health_service_provider.dart';
import 'package:telemarketing_app/widgets/app_dialog.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';

// ── 样式常量 ──
const Color _brandColor = Color(0xFF0052D9);
const Color _textSecondary = Color(0xFFA6A6A6);
const Color _errorColor = Color(0xFFD54941);
const Color _pageBg = Color(0xFFF3F3F3);

/// 设置页
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  /// 后端版本号（null 表示加载中/获取失败）
  String? _backendVersion;
  /// APP 版本号（来自 package_info_plus）
  String _appVersion = '';
  /// 是否正在加载后端版本
  bool _loadingVersion = true;
  /// 退出登录中
  bool _logouting = false;
  /// 全设备登出中
  bool _logoutingAll = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadBackendVersion();
  }

  /// 获取 APP 本地版本号
  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = info.version);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _appVersion = '1.0.0');
      }
    }
  }

  /// 后台静默获取后端版本号
  Future<void> _loadBackendVersion() async {
    setState(() => _loadingVersion = true);
    final version = await ref.read(healthServiceProvider).fetchVersion();
    if (mounted) {
      setState(() {
        _backendVersion = version;
        _loadingVersion = false;
      });
    }
  }

  // ── 交互方法 ──

  /// 退出登录
  Future<void> _onLogout() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: '退出登录',
      content: '确定退出登录？',
      confirmText: '确定',
      confirmColor: _errorColor,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;

    setState(() => _logouting = true);
    await ref.read(authProvider.notifier).logout();
    // logout 本身会跳转登录页（通过 AuthState.unauthenticated 触发 AuthGate）
    // 此处无需额外跳转
  }

  /// 全设备退出登录
  Future<void> _onLogoutAll() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: '全设备退出登录',
      content: '确定在所有设备上退出登录？此操作将使您的账号在所有设备上退出。',
      cancelText: '取消',
      confirmText: '全部退出',
      confirmColor: _errorColor,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;

    setState(() => _logoutingAll = true);
    final ok = await ref.read(authProvider.notifier).logoutAll();
    if (!mounted) return;
    setState(() => _logoutingAll = false);
    if (ok) {
      AppToast.show(context, '已在所有设备上退出登录');
      // logoutAll 成功 AuthNotifier 已设 unauthenticated，AuthGate 自动跳转登录页
    } else {
      AppToast.show(context, '操作失败，请重试');
    }
  }

  /// 关于弹窗
  Future<void> _onAbout() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('关于'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // APP 图标
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _brandColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.phone_in_talk,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '电销工作台',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181818),
              ),
            ),
            const SizedBox(height: 16),
            _aboutInfoRow('APP 版本', _appVersion.isNotEmpty ? 'v$_appVersion' : '获取中...'),
            const SizedBox(height: 12),
            _aboutInfoRow(
              '后端版本',
              _loadingVersion
                  ? '加载中...'
                  : (_backendVersion != null ? 'v$_backendVersion' : '获取失败'),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 关于弹窗信息行
  Widget _aboutInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF181818),
            ),
          ),
        ),
      ],
    );
  }

  // ── 构建方法 ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 账户安全 ──
            _sectionTitle('账户安全'),
            _buildCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, size: 20),
                  title: const Text('修改密码'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ComingSoonPage(featureName: '修改密码'),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 账户操作 ──
            _sectionTitle('账户操作'),
            _buildCard(
              children: [
                ListTile(
                  leading: Icon(Icons.logout, size: 20, color: _errorColor),
                  title: Text(
                    '退出登录',
                    style: TextStyle(color: _errorColor),
                  ),
                  enabled: !_logouting,
                  onTap: _logouting ? null : _onLogout,
                ),
                const Divider(height: 0, indent: 52),
                ListTile(
                  leading: const Icon(Icons.devices, size: 20),
                  title: const Text('全设备退出登录'),
                  enabled: !_logoutingAll,
                  onTap: _logoutingAll ? null : _onLogoutAll,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 关于 ──
            _sectionTitle('关于'),
            _buildCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, size: 20),
                  title: const Text('关于'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: _onAbout,
                ),
              ],
            ),

            // ── 底部版本信息 ──
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Text(
                    '电销工作台 v$_appVersion',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0x99A6A6A6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loadingVersion
                        ? '后端版本: 加载中...'
                        : (_backendVersion != null
                            ? '后端版本: v$_backendVersion'
                            : '后端版本: 获取失败'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0x99A6A6A6),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 区域标题
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _brandColor,
        ),
      ),
    );
  }

  /// 列表容器（白底圆角 Card）
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE7E7E7), width: 0.5),
      ),
      child: Column(children: children),
    );
  }
}
