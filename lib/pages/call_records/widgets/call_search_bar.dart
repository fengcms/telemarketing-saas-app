/// 通话记录手机号搜索栏
///
/// 仅按手机号片段搜索（接口 `q` 参数），参考线索列表页搜索交互：
/// 回车或点「搜索」才触发，清空按钮即时复位。
library;

import 'package:flutter/material.dart';

/// 手机号搜索栏
class CallSearchBar extends StatefulWidget {
  /// 外部持有的输入框控制器
  final TextEditingController searchCtrl;

  /// 触发搜索（[text] 为当前输入；空串表示清除搜索）
  final ValueChanged<String> onSearch;

  const CallSearchBar({
    super.key,
    required this.searchCtrl,
    required this.onSearch,
  });

  @override
  State<CallSearchBar> createState() => _CallSearchBarState();
}

class _CallSearchBarState extends State<CallSearchBar> {
  @override
  void initState() {
    super.initState();
    // 监听输入变化，实时切换清除按钮显隐
    widget.searchCtrl.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.searchCtrl.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.searchCtrl.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 10),
              child: Icon(Icons.search, size: 20, color: Color(0xFFA6A6A6)),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: TextField(
                controller: widget.searchCtrl,
                onSubmitted: widget.onSearch,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 14, color: Color(0xFF181818)),
                decoration: const InputDecoration(
                  hintText: '搜索手机号',
                  hintStyle: TextStyle(fontSize: 14, color: Color(0xFFC5C5C5)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            if (hasText)
              GestureDetector(
                onTap: () {
                  widget.searchCtrl.clear();
                  widget.onSearch('');
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 20, color: Color(0xFFA6A6A6)),
                ),
              ),
            GestureDetector(
              onTap: () => widget.onSearch(widget.searchCtrl.text),
              child: Container(
                height: 34,
                margin: const EdgeInsets.only(top: 3, right: 3, bottom: 3),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0052D9),
                  borderRadius: BorderRadius.circular(17),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '搜索',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
