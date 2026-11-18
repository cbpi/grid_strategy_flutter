import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SigningExpiryIndicator extends StatefulWidget {
  const SigningExpiryIndicator({super.key});

  @override
  State<SigningExpiryIndicator> createState() => _SigningExpiryIndicatorState();
}

class _SigningExpiryIndicatorState extends State<SigningExpiryIndicator>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('grid_strategy/signing');
  Timer? _clock;
  DateTime? _expiry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      WidgetsBinding.instance.addObserver(this);
      _loadExpiry();
      _clock = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _loadExpiry() async {
    try {
      final millis = await _channel.invokeMethod<int>('getProvisioningExpiry');
      if (!mounted) return;
      setState(() {
        _expiry = millis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(millis);
        _loading = false;
      });
    } on PlatformException {
      if (mounted) setState(() => _loading = false);
    } on MissingPluginException {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadExpiry();
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String get _label {
    if (_loading) return '签名';
    final expiry = _expiry;
    if (expiry == null) return '未知';
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative) return '过期';
    if (remaining.inDays >= 1) return '${remaining.inDays}天';
    if (remaining.inHours >= 1) return '${remaining.inHours}小时';
    return '${remaining.inMinutes.clamp(1, 59)}分';
  }

  Color _color(BuildContext context) {
    final expiry = _expiry;
    if (expiry == null) return Theme.of(context).colorScheme.onSurfaceVariant;
    final remaining = expiry.difference(DateTime.now());
    if (remaining.isNegative || remaining.inHours < 24) {
      return Theme.of(context).colorScheme.error;
    }
    if (remaining.inDays < 3) return const Color(0xFFC17A12);
    return Theme.of(context).colorScheme.primary;
  }

  Future<void> _showDetails() async {
    final expiry = _expiry;
    final details = expiry == null
        ? '当前安装包中没有可读取的 iOS 描述文件到期时间。真机开发签名包通常会在这里显示准确期限。'
        : '当前签名描述文件到期时间：\n${_formatDateTime(expiry)}\n\n剩余时间：${_formatRemaining(expiry.difference(DateTime.now()))}\n\n重新签名并安装后，期限会按新安装包的签名信息更新。';
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('iOS 签名期限'),
        content: Text(details),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    final color = _color(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        visualDensity: VisualDensity.compact,
        avatar: Icon(Icons.hourglass_bottom_rounded, size: 16, color: color),
        label: Text(_label, style: TextStyle(color: color, fontSize: 12)),
        onPressed: _showDetails,
        side: BorderSide(color: color.withValues(alpha: .25)),
        backgroundColor: color.withValues(alpha: .08),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  String _formatRemaining(Duration remaining) {
    if (remaining.isNegative) return '已过期';
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    if (days > 0) return '$days 天 $hours 小时';
    if (remaining.inHours > 0) return '${remaining.inHours} 小时 $minutes 分钟';
    return '${remaining.inMinutes.clamp(0, 59)} 分钟';
  }
}
