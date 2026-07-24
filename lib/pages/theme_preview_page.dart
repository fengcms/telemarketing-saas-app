/// Material 3 组件预览页
///
/// 自上而下铺开所有项目用到的 M3 组件族，
/// 每个区块用白色卡片区隔，区块间有间距。
/// 用于在调整主题时一次性查看全局效果。
library;

import 'package:flutter/material.dart';
import '../theme/color_scheme.dart';
import '../widgets/tag_chip.dart';

/// 组件预览页
class ThemePreviewPage extends StatefulWidget {
  const ThemePreviewPage({super.key});

  @override
  State<ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<ThemePreviewPage> {
  bool _checkboxValue = false;
  int _stepperValue = 0;
  bool _isLoading = false;
  int _tagChipIndex = 0;
  final TextEditingController _textCtrl = TextEditingController();
  final TextEditingController _multiCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _multiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M3 主题预览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '热重载后点此刷新',
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PreviewCard(
            title: '按钮变体',
            child: _ButtonShowcase(
              isLoading: _isLoading,
              onToggleLoading: () => setState(() => _isLoading = !_isLoading),
            ),
          ),
          const SizedBox(height: 16),
          _PreviewCard(
            title: '输入组件',
            child: _InputShowcase(ctrl: _textCtrl, multiCtrl: _multiCtrl),
          ),
          const SizedBox(height: 16),
          _PreviewCard(
            title: '选择组件',
            child: _SelectionShowcase(
              checkboxValue: _checkboxValue,
              onCheckboxChanged: (v) => setState(() => _checkboxValue = v ?? false),
              stepperValue: _stepperValue,
              onStepperChanged: (v) => setState(() => _stepperValue = v),
              tagChipIndex: _tagChipIndex,
              onTagChipChanged: (v) => setState(() => _tagChipIndex = v),
            ),
          ),
          const SizedBox(height: 16),
          _PreviewCard(
            title: '导航组件',
            child: _buildNavShowcase(),
          ),
          const SizedBox(height: 16),
          _PreviewCard(
            title: '反馈组件',
            child: _buildFeedbackShowcase(),
          ),
          const SizedBox(height: 16),
          _PreviewCard(
            title: '容器组件',
            child: _buildContainerShowcase(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNavShowcase() {
    return Column(
      children: [
        // Mock AppBar
        Container(
          decoration: const BoxDecoration(
            color: BrandColors.primary,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: null,
                  ),
                  const Expanded(
                    child: Text(
                      '页面标题',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Mock BottomNav
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: BrandColors.border, width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: BrandColors.primary,
            unselectedItemColor: BrandColors.textSecondary,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home, size: 24), label: '首页'),
              BottomNavigationBarItem(icon: Icon(Icons.view_list, size: 24), label: '线索'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today, size: 24), label: '日程'),
              BottomNavigationBarItem(icon: Icon(Icons.person, size: 24), label: '我的'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackShowcase() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        FilledButton(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('这是一个 SnackBar 消息')),
          ),
          child: const Text('SnackBar'),
        ),
        FilledButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('确认操作'),
              content: const Text('这是一个对话框消息。'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('确认'),
                ),
              ],
            ),
          ),
          child: const Text('Dialog'),
        ),
        FilledButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            builder: (_) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: BrandColors.textSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('底部抽屉内容（全宽）'),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          ),
          child: const Text('BottomSheet'),
        ),
      ],
    );
  }

  Widget _buildContainerShowcase() {
    return Column(
      children: [
        // Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '卡片标题',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '这是卡片正文内容，展示 M3 Card 组件的默认样式。',
                  style: TextStyle(
                    fontSize: 14,
                    color: BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('操作'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // ListTile 组
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: BrandColors.border),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone, size: 20),
                title: const Text('电话'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.calendar_today, size: 20),
                title: const Text('日程'),
                subtitle: const Text('副标题说明文字'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.edit, size: 20),
                title: const Text('编辑'),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── 白色卡片区块容器 ──

class _PreviewCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _PreviewCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: BrandColors.primary,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ── 按钮展示 ──

class _ButtonShowcase extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onToggleLoading;

  const _ButtonShowcase({
    required this.isLoading,
    required this.onToggleLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton(onPressed: () {}, child: const Text('Filled')),
            FilledButton(onPressed: null, child: const Text('禁用')),
            FilledButton(
              onPressed: isLoading ? null : () {},
              child: isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Loading'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.tonal(onPressed: () {}, child: const Text('Light')),
            FilledButton.tonal(onPressed: null, child: const Text('禁用')),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            TextButton(onPressed: () {}, child: const Text('Text 按钮')),
            TextButton(onPressed: null, child: const Text('禁用')),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onToggleLoading,
          icon: Icon(isLoading ? Icons.stop : Icons.play_arrow),
          label: Text(isLoading ? '停止 Loading' : '演示 Loading'),
        ),
      ],
    );
  }
}

// ── 输入组件展示 ──

class _InputShowcase extends StatelessWidget {
  final TextEditingController ctrl;
  final TextEditingController multiCtrl;

  const _InputShowcase({required this.ctrl, required this.multiCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('单行文本', style: TextStyle(fontSize: 14, color: BrandColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '请输入...',
            prefixIcon: Icon(Icons.search, size: 20),
          ),
        ),
        const SizedBox(height: 16),
        const Text('多行文本', style: TextStyle(fontSize: 14, color: BrandColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: multiCtrl,
          maxLines: 5,
          minLines: 2,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '补充说明...',
            alignLabelWithHint: true,
          ),
          buildCounter: (ctx, {required int currentLength, required bool isFocused, int? maxLength}) =>
            Text('$currentLength/$maxLength',
                style: const TextStyle(fontSize: 12, color: BrandColors.textSecondary)),
        ),
        const SizedBox(height: 16),
        const Text('日期选择器', style: TextStyle(fontSize: 14, color: BrandColors.textPrimary)),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已选: ${date.year}-${date.month}-${date.day}')),
              );
            }
          },
          icon: const Icon(Icons.calendar_today, size: 18),
          label: const Text('选择日期'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已选: ${time.format(context)}')),
              );
            }
          },
          icon: const Icon(Icons.access_time, size: 18),
          label: const Text('选择时间'),
        ),
      ],
    );
  }
}

// ── 选择组件展示 ──

class _SelectionShowcase extends StatelessWidget {
  final bool checkboxValue;
  final ValueChanged<bool?> onCheckboxChanged;
  final int stepperValue;
  final ValueChanged<int> onStepperChanged;
  final int tagChipIndex;
  final ValueChanged<int> onTagChipChanged;

  const _SelectionShowcase({
    required this.checkboxValue,
    required this.onCheckboxChanged,
    required this.stepperValue,
    required this.onStepperChanged,
    required this.tagChipIndex,
    required this.onTagChipChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chipLabels = ['快捷标签1', '快捷标签2', '快捷标签3', '快捷标签4', '快捷标签5'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox
        Row(
          children: [
            Checkbox(value: checkboxValue, onChanged: onCheckboxChanged),
            GestureDetector(
              onTap: () => onCheckboxChanged(!checkboxValue),
              child: const Text('复选框标签',
                  style: TextStyle(fontSize: 14, color: BrandColors.textPrimary)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // TagChipRow（项目自建胶囊标签组件）
        const Text('胶囊标签（TagChipRow）',
            style: TextStyle(fontSize: 14, color: BrandColors.textPrimary)),
        const SizedBox(height: 8),
        TagChipRow(
          scrollable: true,
          chips: List.generate(chipLabels.length, (i) => TagChipData(
            label: chipLabels[i],
            selected: tagChipIndex == i,
            onTap: () => onTagChipChanged(i),
          )),
        ),
        const SizedBox(height: 12),
        // Stepper
        const Text('步进器', style: TextStyle(fontSize: 14, color: BrandColors.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: stepperValue > 0 ? () => onStepperChanged(stepperValue - 1) : null,
              color: BrandColors.primary,
            ),
            SizedBox(
              width: 32,
              child: Text('$stepperValue', textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: stepperValue < 99 ? () => onStepperChanged(stepperValue + 1) : null,
              color: BrandColors.primary,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('分',
                  style: TextStyle(fontSize: 13, color: BrandColors.textSecondary)),
            ),
          ],
        ),
      ],
    );
  }
}
