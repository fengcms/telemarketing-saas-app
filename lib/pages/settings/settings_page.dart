/// 设置页
///
/// 提供密码修改入口、退出登录/全设备退出、关于信息查看等功能。
/// 页面进入时后台静默请求 /health 获取后端版本号。
/// 设计文档：docs/design/page-design/19-设置页.md
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:telemarketing_app/pages/change_password/change_password_page.dart';
import 'package:telemarketing_app/providers/auth_provider.dart';
import 'package:telemarketing_app/providers/health_service_provider.dart';
import 'package:telemarketing_app/theme/color_scheme.dart';
import 'package:telemarketing_app/widgets/app_dialog.dart';
import 'package:telemarketing_app/widgets/app_toast.dart';

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
  /// 清除缓存中
  bool _clearing = false;

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
      confirmColor: BrandColors.error,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;

    setState(() => _logouting = true);
    await ref.read(authProvider.notifier).logout();
    // logout 已将状态设为 unauthenticated 并清除本地 Token
    // 显式关闭 spinner + 弹出导航栈，确保回到登录页
    if (mounted) {
      setState(() => _logouting = false);
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// 全设备退出登录
  Future<void> _onLogoutAll() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: '全设备退出登录',
      content: '确定在所有设备上退出登录？此操作将使您的账号在所有设备上退出。',
      cancelText: '取消',
      confirmText: '全部退出',
      confirmColor: BrandColors.error,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;

    setState(() => _logoutingAll = true);
    final ok = await ref.read(authProvider.notifier).logoutAll();
    if (!mounted) return;
    setState(() => _logoutingAll = false);
    if (ok) {
      AppToast.show(context, '已在所有设备上退出登录');
    } else {
      AppToast.show(context, '操作失败，请重试');
    }
  }

  /// 清除缓存
  ///
  /// 清除本机所有接口缓存（含登录凭据）后跳登录页重新登录。
  /// 纯本地清除：不调后端登出接口、不吊销会话、不影响其他设备、保留账号预填。
  Future<void> _onClearCache() async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: '清除缓存',
      content: '将清除本机所有接口缓存数据（含登录信息），清除后需重新登录。确定继续？',
      confirmText: '清除',
      confirmColor: BrandColors.error,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearing = true);
    await ref.read(authProvider.notifier).clearLocalCache();
    // clearLocalCache 已将状态设为 unauthenticated，AuthGate 自动跳登录页
    if (mounted) {
      setState(() => _clearing = false);
      Navigator.of(context).popUntil((route) => route.isFirst);
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
                color: BrandColors.primary,
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
                color: BrandColors.textPrimary,
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
              color: BrandColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: BrandColors.textPrimary,
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
      backgroundColor: BrandColors.surface,
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 账户安全 ──
            _buildSectionTitle('账户安全'),
            _buildCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock, size: 22),
                  title: const Text('修改密码'),
                  trailing: const Icon(Icons.chevron_right, size: 22),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChangePasswordPage(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 账户操作 ──
            _buildSectionTitle('账户操作'),
            _buildCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.cleaning_services, size: 22),
                  title: const Text('清除缓存'),
                  enabled: !_clearing,
                  onTap: _clearing ? null : _onClearCache,
                  trailing: _clearing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : null,
                ),
                const Divider(height: 0, indent: 52),
                ListTile(
                  leading: Icon(Icons.logout, size: 22, color: BrandColors.error),
                  title: Text(
                    '退出登录',
                    style: TextStyle(color: BrandColors.error),
                  ),
                  enabled: !_logouting,
                  onTap: _logouting ? null : _onLogout,
                  trailing: _logouting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : null,
                ),
                const Divider(height: 0, indent: 52),
                ListTile(
                  leading: const Icon(Icons.devices, size: 22),
                  title: const Text('全设备退出登录'),
                  enabled: !_logoutingAll,
                  onTap: _logoutingAll ? null : _onLogoutAll,
                  trailing: _logoutingAll
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 关于 ──
            _buildSectionTitle('关于'),
            _buildCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, size: 22),
                  title: const Text('关于'),
                  trailing: const Icon(Icons.chevron_right, size: 22),
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
                      color: BrandColors.textDisabled,
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
                      color: BrandColors.textDisabled,
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
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: BrandColors.textSecondary,
        ),
      ),
    );
  }

  /// 列表容器（白底圆角 Card）
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        type: MaterialType.card,
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: BrandColors.border, width: 0.5),
        ),
        child: Column(children: children),
      ),
    );
  }
}
