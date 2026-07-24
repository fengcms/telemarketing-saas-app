// extension 方法内直接调用 State 的 setState 会触发 protected-member 警告，
// 但 extension 运行期等同实例方法调用，属 lint 误报，全文件忽略。
// ignore_for_file: invalid_use_of_protected_member

/// 日程表单字段区块（线索 / 日期 / 时间 / 备注 / 归属人 / 提交 / 选择器）。
///
/// 作为 [_ScheduleFormContentState] 的扩展方法，可直接访问其私有状态
/// （[_selectedDate]、[_selectedTime]、[_dateError]、[_dirty]、[_contentCtrl] 等）
/// 与 State 能力（[setState]、[context]、[mounted]），从而把主文件体量压到 560 行红线内，
/// 且不引入任何参数传递样板。
part of 'schedule_form_sheet.dart';

extension _ScheduleFormFields on _ScheduleFormContentState {
  /// 区块标题（灰色小字）
  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFFA6A6A6)),
    );
  }

  // ── 关联线索（只读） ──

  Widget _buildLeadSection() {
    final name = _isEdit
        ? widget.initial?.lead?.name ?? ''
        : widget.leadName ?? '';
    final phone = _isEdit
        ? widget.initial?.lead?.phone ?? ''
        : widget.leadPhone ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('关联线索'),
          const SizedBox(height: 8),
          Text(
            name.isEmpty && phone.isEmpty ? '—' : '$name - $phone',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF181818),
            ),
          ),
        ],
      ),
    );
  }

  // ── 计划时间（日期） ──

  Widget _buildDateSection() {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('日期'),
              const Text(
                ' *',
                style: TextStyle(fontSize: 12, color: Color(0xFFD54941)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 日期输入框（白底 + 灰边框 + 圆角）
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE7E7E7), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF181818),
                      ),
                    ),
                  ),
                  const Icon(Icons.calendar_today,
                      size: 18, color: Color(0xFFA6A6A6)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 快捷日期（TagChipRow，scrollable 横向滚动更紧凑）
          TagChipRow(
            scrollable: true,
            chips: [
              TagChipData(
                label: '明天',
                selected:
                    _isSameDay(_selectedDate, today.add(const Duration(days: 1))),
                onTap: () {
                  setState(() {
                    _selectedDate = today.add(const Duration(days: 1));
                    _dateError = null;
                    _dirty = true;
                  });
                },
              ),
              TagChipData(
                label: '后天',
                selected:
                    _isSameDay(_selectedDate, today.add(const Duration(days: 2))),
                onTap: () {
                  setState(() {
                    _selectedDate = today.add(const Duration(days: 2));
                    _dateError = null;
                    _dirty = true;
                  });
                },
              ),
              TagChipData(
                label: '大后天',
                selected:
                    _isSameDay(_selectedDate, today.add(const Duration(days: 3))),
                onTap: () {
                  setState(() {
                    _selectedDate = today.add(const Duration(days: 3));
                    _dateError = null;
                    _dirty = true;
                  });
                },
              ),
              TagChipData(
                label: '五天后',
                selected:
                    _isSameDay(_selectedDate, today.add(const Duration(days: 5))),
                onTap: () {
                  setState(() {
                    _selectedDate = today.add(const Duration(days: 5));
                    _dateError = null;
                    _dirty = true;
                  });
                },
              ),
              TagChipData(
                label: '七天后',
                selected:
                    _isSameDay(_selectedDate, today.add(const Duration(days: 7))),
                onTap: () {
                  setState(() {
                    _selectedDate = today.add(const Duration(days: 7));
                    _dateError = null;
                    _dirty = true;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 计划时间（时分） ──

  Widget _buildTimeSection() {
    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE7E7E7), width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF181818),
                      ),
                    ),
                  ),
                  const Icon(Icons.access_time,
                      size: 18, color: Color(0xFFA6A6A6)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 快捷时间（TagChipRow，scrollable 横向滚动）
          TagChipRow(
            scrollable: true,
            chips: [
              TagChipData(
                label: '上午10点',
                selected: _selectedTime.hour == 10 && _selectedTime.minute == 0,
                onTap: () {
                  setState(() {
                    _selectedTime = const TimeOfDay(hour: 10, minute: 0);
                    _dirty = true;
                  });
                },
              ),
              TagChipData(
                label: '下午2点',
                selected: _selectedTime.hour == 14 && _selectedTime.minute == 0,
                onTap: () {
                  setState(() {
                    _selectedTime = const TimeOfDay(hour: 14, minute: 0);
                    _dirty = true;
                  });
                },
              ),
              TagChipData(
                label: '下午5点',
                selected: _selectedTime.hour == 17 && _selectedTime.minute == 0,
                onTap: () {
                  setState(() {
                    _selectedTime = const TimeOfDay(hour: 17, minute: 0);
                    _dirty = true;
                  });
                },
              ),
              TagChipData(
                label: '晚上7点',
                selected: _selectedTime.hour == 19 && _selectedTime.minute == 0,
                onTap: () {
                  setState(() {
                    _selectedTime = const TimeOfDay(hour: 19, minute: 0);
                    _dirty = true;
                  });
                },
              ),
              TagChipData(
                label: '晚上9点',
                selected: _selectedTime.hour == 21 && _selectedTime.minute == 0,
                onTap: () {
                  setState(() {
                    _selectedTime = const TimeOfDay(hour: 21, minute: 0);
                    _dirty = true;
                  });
                },
              ),
            ],
          ),
          if (_dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _dateError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD54941),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 备注 ──

  Widget _buildNoteSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('备注'),
          const SizedBox(height: 8),
          TDTextarea(
            controller: _contentCtrl,
            hintText: '补充说明...',
            minLines: 2,
            maxLength: 200,
            showBottomDivider: false,
            indicator: true,
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            inputDecoration: const InputDecoration(
              contentPadding: EdgeInsets.fromLTRB(12, 10, 12, 10),
              border: InputBorder.none,
            ),
            textareaDecoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE7E7E7), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            onChanged: (_) => setState(() => _dirty = true),
          ),
        ],
      ),
    );
  }

  // ── 归属人（仅 TM/TA，编辑模式隐藏） ──

  Widget _buildOwnerSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('归属人'),
          const SizedBox(height: 8),
          DropdownButton<OptionItem>(
            isExpanded: true,
            value: _owner,
            hint: const Text('选择归属人'),
            items: _owners
                .map((u) => DropdownMenuItem(
                      value: u,
                      child: Text(u.name),
                    ))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _owner = v;
                _dirty = true;
              });
            },
          ),
        ],
      ),
    );
  }

  // ── 全宽提交按钮 ──

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TDButton(
        text: _isSubmitting ? '' : (_isEdit ? '保存' : '创建日程'),
        theme: TDButtonTheme.primary,
        shape: TDButtonShape.round,
        iconWidget: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : null,
        disabled: _isSubmitting,
        onTap: _isSubmitting ? null : _submit,
      ),
    );
  }

  // ── 选择器（复用已验证的 TDPicker 调用） ──

  /// 日期选择（TDPicker.showDatePicker，onConfirm 回调参数为 `Map<String, int>`）
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    TDPicker.showDatePicker(
      context,
      title: '选择日期',
      dateStart: [today.year, today.month, today.day],
      dateEnd: [today.year + 1, today.month, today.day],
      initialDate: [
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      ],
      onConfirm: (selected) {
        final map = selected;
        setState(() {
          _selectedDate = DateTime(
            map['year'] ?? _selectedDate.year,
            map['month'] ?? _selectedDate.month,
            map['day'] ?? _selectedDate.day,
          );
          _dirty = true;
        });
        Navigator.of(context).pop();
      },
    );
  }

  /// 时间选择（TDPicker.showDatePicker，仅启用 hour/minute）
  Future<void> _pickTime() async {
    TDPicker.showDatePicker(
      context,
      title: '选择时间',
      useYear: false,
      useMonth: false,
      useDay: false,
      useHour: true,
      useMinute: true,
      useSecond: false,
      initialDate: [
        DateTime.now().year,
        DateTime.now().month,
        _selectedTime.hour,
        _selectedTime.minute,
      ],
      onConfirm: (selected) {
        final map = selected;
        setState(() {
          _selectedTime = TimeOfDay(
            hour: map['hour'] ?? _selectedTime.hour,
            minute: map['minute'] ?? _selectedTime.minute,
          );
          _dirty = true;
        });
        Navigator.of(context).pop();
      },
    );
  }

  /// 判断两个日期是否同一天
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
