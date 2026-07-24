import 'package:flutter/material.dart';
import '../models/options.dart';
import '../theme.dart';

/// 섹션 카드
class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const FormSection({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 18,
                    decoration: BoxDecoration(
                        color: kYellow, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: kInk, fontSize: 15.5)),
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

Widget fieldLabel(String text) => text.isEmpty
    ? const SizedBox.shrink()
    : Padding(
        padding: const EdgeInsets.only(bottom: 5, top: 2),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: kMuted)),
      );

/// 한 줄/여러 줄 텍스트
class TextField2 extends StatelessWidget {
  final Map<String, dynamic> data;
  final String field;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;
  final VoidCallback onChanged;
  const TextField2(this.data, this.field, this.label,
      {super.key, this.maxLines = 1, this.keyboardType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldLabel(label),
          TextFormField(
            initialValue: (data[field] ?? '').toString(),
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: const InputDecoration(isDense: true),
            onChanged: (v) {
              data[field] = v;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

/// 드롭다운 (단일 선택 + 직접 입력 불가)
class DropdownField extends StatelessWidget {
  final Map<String, dynamic> data;
  final String field;
  final String label;
  final List<String> options;
  final VoidCallback onChanged;
  const DropdownField(this.data, this.field, this.label, this.options,
      {super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cur = data[field]?.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldLabel(label),
          DropdownButtonFormField<String>(
            // 값이 외부(자동입력)로 바뀌어도 화면에 반영되도록 값 기반 key 사용
            key: ValueKey('$field:$cur'),
            initialValue: options.contains(cur) ? cur : null,
            isExpanded: true,
            decoration: const InputDecoration(isDense: true),
            hint: const Text('선택'),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              data[field] = v;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}

/// 칩 선택 — multi=true 이면 다중(List), false 이면 단일(String)
class ChipsField extends StatelessWidget {
  final Map<String, dynamic> data;
  final String field;
  final String label;
  final List<String> options;
  final bool multi;
  final VoidCallback onChanged;
  const ChipsField(this.data, this.field, this.label, this.options,
      {super.key, this.multi = true, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final selected = <String>{};
    if (multi) {
      final v = data[field];
      if (v is List) selected.addAll(v.map((e) => e.toString()));
    } else if (data[field] != null) {
      selected.add(data[field].toString());
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldLabel(label),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((o) {
              final on = selected.contains(o);
              return FilterChip(
                label: Text(o,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: on ? FontWeight.w800 : FontWeight.w500)),
                selected: on,
                showCheckmark: false,
                backgroundColor: Colors.white,
                selectedColor: kBlack,
                side: BorderSide(color: on ? kBlack : kBorder),
                labelStyle: TextStyle(color: on ? kYellow : kInk),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onSelected: (sel) {
                  if (multi) {
                    final list = (data[field] is List)
                        ? List<String>.from(data[field])
                        : <String>[];
                    if (sel) {
                      list.add(o);
                    } else {
                      list.remove(o);
                    }
                    data[field] = list;
                  } else {
                    data[field] = sel ? o : null;
                  }
                  onChanged();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 날짜 선택 (달력)
class DateField extends StatelessWidget {
  final Map<String, dynamic> data;
  final String field;
  final String label;
  final VoidCallback onChanged;
  const DateField(this.data, this.field, this.label,
      {super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cur = (data[field] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldLabel(label),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(cur) ?? now,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 3),
              );
              if (picked != null) {
                data[field] =
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                onChanged();
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(isDense: true),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(cur.isEmpty ? '날짜 선택' : cur,
                      style: TextStyle(
                          color: cur.isEmpty ? Colors.black38 : Colors.black87)),
                  const Icon(Icons.calendar_today, size: 18, color: Colors.black45),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 거주지역: 시/도 + 시군구 드롭다운 + 동 입력
class RegionField extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onChanged;
  const RegionField(this.data, {super.key, required this.onChanged});

  void _compose() {
    final parts = [data['area_sido'], data['area_sigungu'], data['area_dong']]
        .where((e) => e != null && e.toString().isNotEmpty)
        .join(' ');
    data['area'] = parts;
  }

  @override
  Widget build(BuildContext context) {
    final sido = data['area_sido']?.toString();
    final sgg = data['area_sigungu']?.toString();
    // 시/도, 시/군/구 모두 가나다 오름차순 정렬
    final sidoKeys = regions.keys.toList()..sort();
    final sggList = sido != null
        ? ([...(regions[sido] ?? const <String>[])]..sort())
        : const <String>[];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fieldLabel('거주지역 (시·군·구 선택 + 동 입력)'),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: regions.containsKey(sido) ? sido : null,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('시/도'),
                items: sidoKeys
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  data['area_sido'] = v;
                  data['area_sigungu'] = null;
                  _compose();
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: sggList.contains(sgg) ? sgg : null,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('시/군/구'),
                items: sggList
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  data['area_sigungu'] = v;
                  _compose();
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                initialValue: (data['area_dong'] ?? '').toString(),
                decoration: const InputDecoration(isDense: true, hintText: '동/읍/면'),
                onChanged: (v) {
                  data['area_dong'] = v;
                  _compose();
                  onChanged();
                },
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
