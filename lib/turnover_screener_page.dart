import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TurnoverScreenerPage extends StatefulWidget {
  const TurnoverScreenerPage({super.key});

  @override
  State<TurnoverScreenerPage> createState() => _TurnoverScreenerPageState();
}

class _TurnoverCandidate {
  const _TurnoverCandidate({
    required this.code,
    required this.name,
    required this.price,
    required this.changePercent,
    required this.turnover,
    required this.marketCap,
    required this.threshold,
    required this.date,
    required this.close,
    required this.ma5,
    required this.ma10,
    required this.volumeMultiple,
    required this.change20,
    required this.position,
    required this.confirmed,
    required this.tomorrowCandidate,
    required this.reason,
  });

  final String code;
  final String name;
  final double price;
  final double changePercent;
  final double turnover;
  final double marketCap;
  final double threshold;
  final String date;
  final double close;
  final double ma5;
  final double ma10;
  final double volumeMultiple;
  final double change20;
  final String position;
  final bool confirmed;
  final bool tomorrowCandidate;
  final String reason;
}

class _WatchItem {
  _WatchItem({
    required this.code,
    required this.name,
    required this.scanDate,
    required this.close,
    required this.ma5,
    required this.ma10,
    this.status = '等待次日复核',
    this.checkedAt = '',
    this.latestPrice,
    this.checks = const [],
    this.error = '',
  });

  final String code;
  final String name;
  final String scanDate;
  final double close;
  final double ma5;
  final double ma10;
  String status;
  String checkedAt;
  double? latestPrice;
  List<Map<String, dynamic>> checks;
  String error;

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'scanDate': scanDate,
    'close': close,
    'ma5': ma5,
    'ma10': ma10,
    'status': status,
    'checkedAt': checkedAt,
    'latestPrice': latestPrice,
    'checks': checks,
    'error': error,
  };

  factory _WatchItem.fromJson(Map<String, dynamic> json) => _WatchItem(
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? '',
    scanDate: json['scanDate'] as String? ?? '',
    close: _num(json['close']),
    ma5: _num(json['ma5']),
    ma10: _num(json['ma10']),
    status: json['status'] as String? ?? '等待次日复核',
    checkedAt: json['checkedAt'] as String? ?? '',
    latestPrice: json['latestPrice'] == null ? null : _num(json['latestPrice']),
    checks: (json['checks'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(),
    error: json['error'] as String? ?? '',
  );
}

class _DailyBar {
  const _DailyBar(
    this.date,
    this.open,
    this.close,
    this.high,
    this.low,
    this.volume,
  );
  final String date;
  final double open;
  final double close;
  final double high;
  final double low;
  final double volume;
}

class _IntradayPoint {
  const _IntradayPoint(
    this.time,
    this.close,
    this.high,
    this.low,
    this.volume,
    this.amount,
  );
  final String time;
  final double close;
  final double high;
  final double low;
  final double volume;
  final double amount;
}

double _num(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

class _TurnoverScreenerPageState extends State<TurnoverScreenerPage> {
  static const _storageKey = 'turnover_screener_watchlist_v1';
  static const _green = Color(0xFF16865B);
  static const _red = Color(0xFFD14B4B);
  static const _muted = Color(0xFF6D7B8E);
  static const _canvas = Color(0xFFF4F6F8);

  final _client = http.Client();
  final _watchlist = <_WatchItem>[];
  final _rows = <_TurnoverCandidate>[];
  bool _loading = false;
  bool _refreshing = false;
  String _progress = '';
  String _error = '';
  String _lastRefresh = '';
  double _smallCapThreshold = 8;
  double _midCapThreshold = 10;
  double _largeCapThreshold = 5;
  double _volumeMultipleThreshold = 2;
  int _maxCandidates = 200;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  Future<void> _loadWatchlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _watchlist
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map(
              (item) => _WatchItem.fromJson(Map<String, dynamic>.from(item)),
            ),
          );
        if (mounted) setState(() {});
      }
    } catch (_) {
      // Keep the screen usable if local data is malformed.
    }
  }

  Future<void> _saveWatchlist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_watchlist.map((item) => item.toJson()).toList()),
    );
  }

  String _marketPrefix(String code) =>
      code.startsWith(RegExp(r'[569]')) ? '1' : '0';

  double _threshold(double marketCap) {
    if (marketCap < 50) return _smallCapThreshold;
    if (marketCap < 200) return _midCapThreshold;
    return _largeCapThreshold;
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200)
      throw Exception('行情接口 HTTP ${response.statusCode}');
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) throw Exception('行情接口返回格式异常');
    return decoded;
  }

  Future<List<Map<String, dynamic>>> _fetchAllQuotes() async {
    const fields = 'f12,f14,f2,f3,f8,f21';
    final uri = Uri.https('push2.eastmoney.com', '/api/qt/clist/get', {
      'pn': '1',
      'pz': '10000',
      'po': '1',
      'np': '1',
      'fltt': '2',
      'invt': '2',
      'fid': 'f3',
      'fs': 'm:0+t:6,m:0+t:80,m:1+t:2,m:1+t:23',
      'fields': fields,
    });
    final data = (await _getJson(uri))['data'] as Map<String, dynamic>?;
    final diff = data?['diff'];
    if (diff is! List) throw Exception('全市场行情数据为空');
    return diff
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<_DailyBar>> _fetchDailyBars(String code) async {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 180));
    String apiDate(DateTime date) =>
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final uri = Uri.https('push2his.eastmoney.com', '/api/qt/stock/kline/get', {
      'secid': '${_marketPrefix(code)}.$code',
      'ut': '7eea3edcaed734bea9cbfc24409ed989',
      'fields1': 'f1,f2,f3,f4,f5,f6',
      'fields2': 'f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61',
      'klt': '101',
      'fqt': '1',
      'beg': apiDate(start),
      'end': apiDate(end),
    });
    final data = (await _getJson(uri))['data'] as Map<String, dynamic>?;
    final rows = data?['klines'];
    if (rows is! List) throw Exception('日 K 不可用');
    return rows
        .whereType<String>()
        .map((row) {
          final parts = row.split(',');
          if (parts.length < 6) return null;
          return _DailyBar(
            parts[0],
            _num(parts[1]),
            _num(parts[2]),
            _num(parts[3]),
            _num(parts[4]),
            _num(parts[5]),
          );
        })
        .whereType<_DailyBar>()
        .toList();
  }

  Future<_TurnoverCandidate?> _evaluate(Map<String, dynamic> quote) async {
    final code = '${quote['f12'] ?? ''}';
    final name = '${quote['f14'] ?? code}';
    final marketCap = _num(quote['f21']) / 100000000;
    final turnover = _num(quote['f8']);
    final threshold = _threshold(marketCap);
    if (code.length != 6 || marketCap <= 0 || turnover < threshold) return null;
    final bars = await _fetchDailyBars(code);
    if (bars.length < 21) return null;
    final latest = bars.last;
    final previous = bars.sublist(bars.length - 21, bars.length - 1);
    final avgVol =
        previous.map((bar) => bar.volume).reduce((a, b) => a + b) /
        previous.length;
    final volumeMultiple = avgVol == 0 ? 0.0 : latest.volume / avgVol;
    final closes = bars.map((bar) => bar.close).toList();
    double mean(List<double> values) =>
        values.reduce((a, b) => a + b) / values.length;
    final ma5 = mean(closes.sublist(closes.length - 5));
    final ma10 = mean(closes.sublist(closes.length - 10));
    final ma20 = mean(closes.sublist(closes.length - 20));
    final change20 = (latest.close / closes[closes.length - 20] - 1) * 100;
    final change60 =
        (latest.close / closes[max(0, closes.length - 60).toInt()] - 1) * 100;
    final priorHigh = previous
        .map((bar) => bar.high)
        .reduce((a, b) => a > b ? a : b);
    final low60 = bars
        .sublist(max(0, bars.length - 60).toInt())
        .map((bar) => bar.low)
        .reduce((a, b) => a < b ? a : b);
    final downtrend = latest.close < ma20 && ma5 < ma10;
    final weakClose =
        latest.close < latest.open ||
        (latest.high - latest.close) / latest.high >= .03;
    var position = '量价观察';
    if (change60 >= 80 && weakClose) {
      position = '高位放量滞涨';
    } else if (downtrend) {
      position = '下跌趋势放量';
    } else if (latest.close <= low60 * 1.2 &&
        latest.close > priorHigh &&
        latest.close >= latest.open) {
      position = '低位平台突破';
    } else if (change20 >= 20 && change20 <= 40 && latest.close >= ma10) {
      position = '上涨途中整理';
    }
    final confirmed =
        volumeMultiple >= _volumeMultipleThreshold &&
        latest.close >= latest.open &&
        latest.close >= ma5 &&
        !downtrend &&
        position != '高位放量滞涨';
    final now = DateTime.now();
    final quoteDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final closeConfirmed = quoteDate == latest.date && now.hour >= 15;
    final tomorrowCandidate =
        closeConfirmed &&
        confirmed &&
        position != '高位放量滞涨' &&
        position != '下跌趋势放量';
    return _TurnoverCandidate(
      code: code,
      name: name,
      price: _num(quote['f2']),
      changePercent: _num(quote['f3']),
      turnover: turnover,
      marketCap: marketCap,
      threshold: threshold,
      date: latest.date,
      close: latest.close,
      ma5: ma5,
      ma10: ma10,
      volumeMultiple: volumeMultiple,
      change20: change20,
      position: position,
      confirmed: confirmed,
      tomorrowCandidate: tomorrowCandidate,
      reason:
          '量能 ${volumeMultiple.toStringAsFixed(2)}x；MA5 ${latest.close >= ma5 ? '上方' : '下方'}；MA10 ${latest.close >= ma10 ? '上方' : '下方'}；20日涨幅 ${change20.toStringAsFixed(1)}%',
    );
  }

  Future<void> _runScreen() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
      _progress = '获取全市场行情…';
      _rows.clear();
    });
    try {
      final quotes = await _fetchAllQuotes();
      final turnoverCandidates =
          quotes.where((quote) {
            final cap = _num(quote['f21']) / 100000000;
            return cap > 0 && _num(quote['f8']) >= _threshold(cap);
          }).toList()..sort((a, b) {
            final capA = _num(a['f21']) / 100000000;
            final capB = _num(b['f21']) / 100000000;
            return (_num(b['f8']) - _threshold(capB)).compareTo(
              _num(a['f8']) - _threshold(capA),
            );
          });
      final selected = turnoverCandidates
          .take(_maxCandidates.clamp(1, 1000).toInt())
          .toList();
      final evaluated = <_TurnoverCandidate>[];
      for (var start = 0; start < selected.length; start += 5) {
        final batch = selected.skip(start).take(5);
        final results = await Future.wait(
          batch.map((quote) async {
            try {
              return await _evaluate(quote);
            } catch (_) {
              return null;
            }
          }),
        );
        evaluated.addAll(results.whereType<_TurnoverCandidate>());
        if (mounted)
          setState(
            () => _progress =
                '日 K 核验：${min(start + 5, selected.length)}/${selected.length}',
          );
      }
      evaluated.sort((a, b) {
        if (a.tomorrowCandidate != b.tomorrowCandidate)
          return a.tomorrowCandidate ? -1 : 1;
        if (a.confirmed != b.confirmed) return a.confirmed ? -1 : 1;
        return b.volumeMultiple.compareTo(a.volumeMultiple);
      });
      if (mounted) {
        setState(() {
          _rows.addAll(evaluated);
          _progress =
              '扫描 ${quotes.length} 只；换手率达标 ${turnoverCandidates.length} 只；日 K 核验 ${selected.length} 只';
        });
      }
    } catch (error) {
      if (mounted)
        setState(
          () => _error =
              '扫描失败：${error.toString().replaceFirst('Exception: ', '')}',
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<_IntradayPoint>> _fetchIntraday(String code) async {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final uri = Uri.https('push2his.eastmoney.com', '/api/qt/stock/kline/get', {
      'secid': '${_marketPrefix(code)}.$code',
      'ut': '7eea3edcaed734bea9cbfc24409ed989',
      'fields1': 'f1,f2,f3,f4,f5,f6',
      'fields2': 'f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61',
      'klt': '1',
      'fqt': '1',
      'beg': date,
      'end': date,
    });
    final data = (await _getJson(uri))['data'] as Map<String, dynamic>?;
    final rows = data?['klines'];
    if (rows is! List) return [];
    return rows
        .whereType<String>()
        .map((row) {
          final parts = row.split(',');
          if (parts.length < 7) return null;
          return _IntradayPoint(
            parts[0].split(' ').last,
            _num(parts[2]),
            _num(parts[3]),
            _num(parts[4]),
            _num(parts[5]),
            _num(parts[6]),
          );
        })
        .whereType<_IntradayPoint>()
        .toList();
  }

  Future<void> _refreshWatchlist() async {
    if (_refreshing || _watchlist.isEmpty) return;
    setState(() => _refreshing = true);
    try {
      for (final item in _watchlist) {
        try {
          final points = await _fetchIntraday(item.code);
          item.checkedAt = _nowText();
          item.error = '';
          if (points.isEmpty) {
            item.status = '分时数据暂不可用';
            item.checks = [];
            continue;
          }
          final latest = points.last;
          final dayLow = points
              .map((point) => point.low)
              .reduce((a, b) => a < b ? a : b);
          final totalVolume = points
              .map((point) => point.volume)
              .reduce((a, b) => a + b);
          final totalAmount = points
              .map((point) => point.amount)
              .reduce((a, b) => a + b);
          final vwap = totalVolume > 0 ? totalAmount / totalVolume / 100 : 0;
          item.latestPrice = latest.close;
          item.checks = [
            {
              'label': '现价高于昨收 ${item.close.toStringAsFixed(2)}',
              'passed': latest.close > item.close,
            },
            {
              'label': '现价高于昨日 MA5 ${item.ma5.toStringAsFixed(2)}',
              'passed': latest.close > item.ma5,
            },
            {
              'label': '现价高于昨日 MA10 ${item.ma10.toStringAsFixed(2)}',
              'passed': latest.close > item.ma10,
            },
            {
              'label': '现价不低于分时均价 ${vwap.toStringAsFixed(2)}',
              'passed': vwap > 0 && latest.close >= vwap,
            },
            {
              'label': '较日内低点反弹 ≥0.5% (${dayLow.toStringAsFixed(2)})',
              'passed': dayLow > 0 && latest.close >= dayLow * 1.005,
            },
          ];
          item.status = latest.time.compareTo('09:45') < 0
              ? '等待09:45复核（当前 ${latest.time}）'
              : item.checks.every((check) => check['passed'] == true)
              ? '次日条件满足（候选）'
              : '条件未全部满足';
        } catch (error) {
          item.status = '行情获取失败';
          item.error = error.toString().replaceFirst('Exception: ', '');
          item.checkedAt = _nowText();
        }
        if (mounted) setState(() {});
      }
      await _saveWatchlist();
      if (mounted) setState(() => _lastRefresh = '最近刷新：${_nowText()}');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _addWatch(_TurnoverCandidate row) async {
    if (!row.tomorrowCandidate ||
        _watchlist.any((item) => item.code == row.code))
      return;
    _watchlist.insert(
      0,
      _WatchItem(
        code: row.code,
        name: row.name,
        scanDate: row.date,
        close: row.close,
        ma5: row.ma5,
        ma10: row.ma10,
      ),
    );
    await _saveWatchlist();
    if (mounted) setState(() {});
  }

  Future<void> _removeWatch(String code) async {
    _watchlist.removeWhere((item) => item.code == code);
    await _saveWatchlist();
    if (mounted) setState(() {});
  }

  String _nowText() {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return '$date ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _card({required Widget child}) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );

  Widget _thresholdInput(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) => SizedBox(
    width: 150,
    child: TextFormField(
      initialValue: value.toStringAsFixed(0),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
        isDense: true,
      ),
      onChanged: (text) {
        final parsed = double.tryParse(text);
        if (parsed != null && parsed >= 0 && parsed <= 100) onChanged(parsed);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(title: const Text('换手率选股'), backgroundColor: _canvas),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '收盘筛选 + 次日手动复核',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  '按流通市值与换手率筛异动，再检查日 K 量价。次日 09:45 后可手动刷新观察名单的分时快照。',
                  style: TextStyle(color: _muted, height: 1.45),
                ),
                const SizedBox(height: 10),
                const Text(
                  '策略提示仅供研究，不代表主力行为确认或买入指令；行情可能延迟。',
                  style: TextStyle(color: _red, fontSize: 12),
                ),
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '筛选参数',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _thresholdInput(
                      '小盘 <50亿',
                      _smallCapThreshold,
                      (v) => _smallCapThreshold = v,
                    ),
                    _thresholdInput(
                      '中盘 50–200亿',
                      _midCapThreshold,
                      (v) => _midCapThreshold = v,
                    ),
                    _thresholdInput(
                      '大盘 ≥200亿',
                      _largeCapThreshold,
                      (v) => _largeCapThreshold = v,
                    ),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        initialValue: '2',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '均量倍数 ≥',
                          suffixText: 'x',
                          isDense: true,
                        ),
                        onChanged: (v) => _volumeMultipleThreshold =
                            double.tryParse(v) ?? _volumeMultipleThreshold,
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        initialValue: '200',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '最多核验候选',
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            _maxCandidates = int.tryParse(v) ?? _maxCandidates,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _runScreen,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_loading ? '扫描中…' : '开始全市场扫描'),
                ),
                if (_progress.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _progress,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(_error, style: const TextStyle(color: _red)),
                ],
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '筛选结果',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text('${_rows.length} 只'),
                  ],
                ),
                if (_rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      '点击“开始全市场扫描”获取候选股票',
                      style: TextStyle(color: _muted),
                    ),
                  ),
                ..._rows.map(_candidateTile),
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '次日观察名单',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _refreshing || _watchlist.isEmpty
                          ? null
                          : _refreshWatchlist,
                      icon: const Icon(Icons.refresh),
                      label: Text(_refreshing ? '刷新中' : '刷新信号'),
                    ),
                  ],
                ),
                Text(
                  _lastRefresh.isEmpty
                      ? '点击时获取一次快照，不持续订阅。建议下一交易日 09:45 后刷新。'
                      : _lastRefresh,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
                if (_watchlist.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      '尚无观察标的；从上方候选加入。',
                      style: TextStyle(color: _muted),
                    ),
                  ),
                ..._watchlist.map(_watchTile),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _candidateTile(_TurnoverCandidate row) {
    final watched = _watchlist.any((item) => item.code == row.code);
    final signal = row.tomorrowCandidate
        ? '次日买入候选'
        : row.confirmed
        ? '量价条件通过'
        : '需人工观察';
    final color = row.tomorrowCandidate
        ? _green
        : row.position.contains('风险') || row.position.contains('下跌')
        ? _red
        : _muted;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${row.name}  ${row.code}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                signal,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '换手 ${row.turnover.toStringAsFixed(2)}%（门槛 ${row.threshold.toStringAsFixed(0)}%） · 流通市值 ${row.marketCap.toStringAsFixed(1)} 亿 · ${row.position}',
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
          Text(
            '量能 ${row.volumeMultiple.toStringAsFixed(2)}x · 收盘 ${row.close.toStringAsFixed(2)} · MA5 ${row.ma5.toStringAsFixed(2)} / MA10 ${row.ma10.toStringAsFixed(2)} · 20日涨幅 ${row.change20.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 12, color: _muted),
          ),
          Text(row.reason, style: const TextStyle(fontSize: 12, color: _muted)),
          if (row.tomorrowCandidate)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: watched ? null : () => _addWatch(row),
                child: Text(watched ? '已加入观察' : '加入观察'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _watchTile(_WatchItem item) {
    final success = item.status.contains('条件满足');
    final statusColor = success
        ? _green
        : item.status.contains('未全部') || item.status.contains('失败')
        ? _red
        : _muted;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.name}  ${item.code}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => _removeWatch(item.code),
                icon: const Icon(Icons.close, size: 18),
                tooltip: '移除',
              ),
            ],
          ),
          Text(
            '${item.status}${item.latestPrice == null ? '' : ' · 最新价 ${item.latestPrice!.toStringAsFixed(2)}'}',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
          ),
          if (item.checks.isNotEmpty)
            ...item.checks.map((check) {
              final passed = check['passed'] == true;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${passed ? '✓' : '×'} ${check['label']}',
                  style: TextStyle(color: passed ? _green : _red, fontSize: 12),
                ),
              );
            }),
          if (item.error.isNotEmpty)
            Text(item.error, style: const TextStyle(color: _red, fontSize: 12)),
          if (item.checkedAt.isNotEmpty)
            Text(
              '更新于 ${item.checkedAt}',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
        ],
      ),
    );
  }
}
