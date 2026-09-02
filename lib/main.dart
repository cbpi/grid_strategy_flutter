import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _ink = Color(0xFF122033);
const _muted = Color(0xFF6D7B8E);
const _canvas = Color(0xFFF4F6F8);
const _blue = Color(0xFF1769E0);
const _green = Color(0xFF16865B);
const _red = Color(0xFFD14B4B);
const _amber = Color(0xFFB7791F);
const _storageKey = 'grid_strategy_flutter_v1';
const _gridShares = 500;
const _lotSize = 100;

void main() {
  runApp(const GridStrategyApp());
}

class GridStrategyApp extends StatelessWidget {
  const GridStrategyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '网格策略',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _blue,
          brightness: Brightness.light,
        ),
        fontFamily: 'sans',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: .06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _blue, width: 1.4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
      home: const GridStrategyPage(),
    );
  }
}

class TradeLog {
  TradeLog({
    required this.time,
    required this.action,
    required this.price,
    required this.shares,
    required this.profit,
  });

  final String time;
  final String action;
  final double price;
  final int shares;
  final double profit;

  Map<String, dynamic> toJson() => {
    'time': time,
    'action': action,
    'price': price,
    'shares': shares,
    'profit': profit,
  };

  factory TradeLog.fromJson(Map<String, dynamic> json) => TradeLog(
    time: json['time'] as String? ?? '',
    action: json['action'] as String? ?? '',
    price: _number(json['price']),
    shares: _number(json['shares']).round(),
    profit: _number(json['profit']),
  );
}

class StrategyLog {
  StrategyLog({required this.time, required this.action, required this.detail});

  final String time;
  final String action;
  final String detail;

  Map<String, dynamic> toJson() => {
    'time': time,
    'action': action,
    'detail': detail,
  };

  factory StrategyLog.fromJson(Map<String, dynamic> json) => StrategyLog(
    time: json['time'] as String? ?? '',
    action: json['action'] as String? ?? '',
    detail: json['detail'] as String? ?? '',
  );
}

class SnapshotRecord {
  SnapshotRecord({
    required this.id,
    required this.dataDate,
    required this.price,
    required this.ma20,
    required this.holdings,
    required this.costPrice,
    required this.basePrice,
    required this.createdAt,
  });

  final String id;
  final String dataDate;
  final double price;
  final double ma20;
  final int holdings;
  final double costPrice;
  final double basePrice;
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'dataDate': dataDate,
    'price': price,
    'ma20': ma20,
    'holdings': holdings,
    'costPrice': costPrice,
    'basePrice': basePrice,
    'createdAt': createdAt,
  };

  factory SnapshotRecord.fromJson(Map<String, dynamic> json) => SnapshotRecord(
    id: json['id'] as String? ?? '',
    dataDate: json['dataDate'] as String? ?? '',
    price: _number(json['price']),
    ma20: _number(json['ma20']),
    holdings: _number(json['holdings']).round(),
    costPrice: _number(json['costPrice']),
    basePrice: _number(json['basePrice']),
    createdAt: json['createdAt'] as String? ?? '',
  );
}

class StockProfile {
  StockProfile({
    required this.symbol,
    required this.name,
    this.dataDate = '',
    this.price,
    this.ma20,
    this.basePrice,
    this.holdings = 0,
    this.costPrice = 0,
    this.realizedPnl = 0,
    this.lastUpdatedAt = '',
    List<TradeLog>? tradeLogs,
    List<StrategyLog>? strategyLogs,
    List<SnapshotRecord>? snapshots,
  }) : tradeLogs = tradeLogs ?? [],
       strategyLogs = strategyLogs ?? [],
       snapshots = snapshots ?? [];

  final String symbol;
  String name;
  String dataDate;
  double? price;
  double? ma20;
  double? basePrice;
  int holdings;
  double costPrice;
  double realizedPnl;
  String lastUpdatedAt;
  List<TradeLog> tradeLogs;
  List<StrategyLog> strategyLogs;
  List<SnapshotRecord> snapshots;

  double get totalCost => holdings * costPrice;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'name': name,
    'dataDate': dataDate,
    'price': price,
    'ma20': ma20,
    'basePrice': basePrice,
    'holdings': holdings,
    'costPrice': costPrice,
    'realizedPnl': realizedPnl,
    'lastUpdatedAt': lastUpdatedAt,
    'tradeLogs': tradeLogs.map((item) => item.toJson()).toList(),
    'strategyLogs': strategyLogs.map((item) => item.toJson()).toList(),
    'snapshots': snapshots.map((item) => item.toJson()).toList(),
  };

  factory StockProfile.fromJson(Map<String, dynamic> json) => StockProfile(
    symbol: json['symbol'] as String? ?? '',
    name: json['name'] as String? ?? '',
    dataDate: json['dataDate'] as String? ?? '',
    price: _nullableNumber(json['price']),
    ma20: _nullableNumber(json['ma20']),
    basePrice: _nullableNumber(json['basePrice']),
    holdings: _number(json['holdings']).round(),
    costPrice: _number(json['costPrice']),
    realizedPnl: _number(json['realizedPnl']),
    lastUpdatedAt: json['lastUpdatedAt'] as String? ?? '',
    tradeLogs: _listOf(json['tradeLogs'], (item) => TradeLog.fromJson(item)),
    strategyLogs: _listOf(
      json['strategyLogs'],
      (item) => StrategyLog.fromJson(item),
    ),
    snapshots: _listOf(
      json['snapshots'],
      (item) => SnapshotRecord.fromJson(item),
    ),
  );
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? 0;
}

double? _nullableNumber(dynamic value) {
  if (value == null) return null;
  final result = _number(value);
  return result == 0 && '$value' != '0' ? null : result;
}

List<T> _listOf<T>(dynamic value, T Function(Map<String, dynamic>) mapper) {
  if (value is! List) return [];
  return value.whereType<Map<String, dynamic>>().map(mapper).toList();
}

class MarketData {
  const MarketData({
    required this.price,
    required this.ma20,
    required this.date,
    required this.name,
  });

  final double price;
  final double ma20;
  final String date;
  final String name;
}

class GridLevel {
  const GridLevel(this.label, this.price, this.isSell);

  final String label;
  final double? price;
  final bool isSell;
}

class GridStrategyPage extends StatefulWidget {
  const GridStrategyPage({
    super.key,
    this.autoRefresh = true,
    this.loadStorage = true,
  });

  final bool autoRefresh;
  final bool loadStorage;

  @override
  State<GridStrategyPage> createState() => _GridStrategyPageState();
}

class _GridStrategyPageState extends State<GridStrategyPage> {
  final _newStockController = TextEditingController();
  final _holdingsController = TextEditingController();
  final _costController = TextEditingController();
  final _bulkController = TextEditingController();
  final _tradePriceController = TextEditingController();
  final _tradeSharesController = TextEditingController();

  final Map<String, StockProfile> _profiles = {};
  String _selectedSymbol = '002402';
  bool _loading = false;
  bool _ready = false;
  String _marketError = '';
  String _tradeAction = '买入';

  StockProfile get _profile => _profiles[_selectedSymbol]!;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void dispose() {
    _newStockController.dispose();
    _holdingsController.dispose();
    _costController.dispose();
    _bulkController.dispose();
    _tradePriceController.dispose();
    _tradeSharesController.dispose();
    super.dispose();
  }

  Future<void> _hydrate() async {
    final defaults = [
      StockProfile(
        symbol: '002402',
        name: '和而泰',
        dataDate: _formatDate(DateTime.now()),
        price: 21.33,
        ma20: 21.35,
        basePrice: 21.33,
        holdings: 2200,
        costPrice: 22,
      ),
      StockProfile(symbol: '600326', name: '西藏天路'),
      StockProfile(symbol: '002639', name: '雪人集团'),
    ];
    for (final profile in defaults) {
      _profiles[profile.symbol] = profile;
    }

    if (widget.loadStorage) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey);
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final savedProfiles = data['profiles'];
          if (savedProfiles is Map) {
            for (final entry in savedProfiles.entries) {
              if (entry.value is Map<String, dynamic>) {
                _profiles[entry.key as String] = StockProfile.fromJson(
                  entry.value as Map<String, dynamic>,
                );
              }
            }
          }
          _selectedSymbol =
              data['selectedSymbol'] as String? ?? _selectedSymbol;
        }
      } catch (_) {
        // Keep the safe defaults when local data is malformed.
      }
    }

    if (!_profiles.containsKey(_selectedSymbol)) {
      _selectedSymbol = _profiles.keys.first;
    }
    _syncInputControllers();
    if (mounted) setState(() => _ready = true);
    if (widget.autoRefresh) {
      await _refreshMarketData();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'selectedSymbol': _selectedSymbol,
        'profiles': _profiles.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
      }),
    );
  }

  void _syncInputControllers() {
    _holdingsController.text = '${_profile.holdings}';
    _costController.text = _profile.costPrice == 0
        ? ''
        : _profile.costPrice.toStringAsFixed(2);
  }

  Future<MarketData> _fetchMarketData(String symbol) async {
    final prefix = symbol.startsWith(RegExp(r'[569]')) ? 'sh' : 'sz';
    final quoteUri = Uri.parse(
      'https://push2.eastmoney.com/api/qt/stock/get'
      '?secid=${prefix == 'sh' ? '1' : '0'}.$symbol'
      '&fields=f43,f57,f58'
      '&ut=fa5fd1943c7b386f172d6893dbfba10b'
      '&fltt=2&invt=2',
    );
    final klineUri = Uri.parse(
      'https://push2his.eastmoney.com/api/qt/stock/kline/get'
      '?secid=${prefix == 'sh' ? '1' : '0'}.$symbol'
      '&ut=fa5fd1943c7b386f172d6893dbfba10b'
      '&fields1=f1,f2,f3,f4,f5,f6'
      '&fields2=f51,f52,f53,f54,f55,f56,f57,f58,f59,f60,f61'
      '&klt=101&fqt=1&beg=0&end=20500101',
    );

    final responses = await Future.wait([
      http.get(quoteUri),
      http.get(klineUri),
    ]);

    final quoteResponse = responses[0];
    final klineResponse = responses[1];
    if (quoteResponse.statusCode != 200 || klineResponse.statusCode != 200) {
      throw Exception('行情接口响应异常');
    }

    final quoteJson = jsonDecode(
      utf8.decode(quoteResponse.bodyBytes),
    ) as Map<String, dynamic>;
    final quoteData = quoteJson['data'] as Map<String, dynamic>?;
    if (quoteData == null) throw Exception('未获取到最新行情');
    final name = (quoteData['f58'] as String? ?? '').trim();
    final price = _number(quoteData['f43']);
    if (price <= 0) throw Exception('最新价无效');

    final klineJson = jsonDecode(
      utf8.decode(klineResponse.bodyBytes),
    ) as Map<String, dynamic>;
    final data = klineJson['data'] as Map<String, dynamic>?;
    final rows = (data?['klines'] as List?)?.whereType<String>().toList() ?? [];
    if (rows.isEmpty) throw Exception('未获取到日 K 数据');
    final parsed = rows
        .map((row) => row.split(','))
        .where((parts) => parts.length >= 3)
        .toList();
    final closes = parsed
        .map((parts) => double.tryParse(parts[2]))
        .whereType<double>()
        .toList();
    if (closes.length < 20) throw Exception('日 K 数据不足以计算 MA20');
    final ma20 =
        closes.sublist(closes.length - 20).reduce((a, b) => a + b) / 20;

    return MarketData(
      price: price,
      ma20: ma20,
      date: parsed.last.first,
      name: name.isEmpty ? symbol : name,
    );
  }

  Future<void> _refreshMarketData() async {
    _dismissKeyboard();
    if (!_ready || _loading) return;
    setState(() {
      _loading = true;
      _marketError = '';
    });

    try {
      final market = await _fetchMarketData(_selectedSymbol);
      final profile = _profile;
      profile
        ..name = market.name
        ..price = double.parse(market.price.toStringAsFixed(2))
        ..ma20 = double.parse(market.ma20.toStringAsFixed(2))
        ..dataDate = market.date
        ..lastUpdatedAt = _nowText();
      await _persist();
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        setState(() {
          _marketError =
              '行情同步失败，当前显示本地数据。${error.toString().replaceFirst('Exception: ', '')}';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectStock(String symbol) async {
    _dismissKeyboard();
    if (symbol == _selectedSymbol) return;
    setState(() {
      _selectedSymbol = symbol;
      _marketError = '';
    });
    _syncInputControllers();
    await _persist();
    await _refreshMarketData();
  }

  Future<void> _addStock() async {
    _dismissKeyboard();
    final symbol = _newStockController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(symbol)) {
      _snack('请输入 6 位 A 股代码');
      return;
    }
    if (!_profiles.containsKey(symbol)) {
      _profiles[symbol] = StockProfile(symbol: symbol, name: symbol);
    }
    _newStockController.clear();
    await _selectStock(symbol);
  }

  Future<void> _deleteCurrentStock() async {
    _dismissKeyboard();
    if (_profiles.length <= 1) {
      _snack('至少保留一只股票，暂时不能删除最后一个标的');
      return;
    }

    final profile = _profile;
    final currentSymbol = _selectedSymbol;
    final symbols = _profiles.keys.toList();
    final currentIndex = symbols.indexOf(currentSymbol);
    final fallbackSymbol = currentIndex > 0
        ? symbols[currentIndex - 1]
        : symbols[1];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除当前股票'),
        content: Text('确认删除 ${profile.name}（${profile.symbol}）的本地策略、日志和快照吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _profiles.remove(currentSymbol);
      _selectedSymbol = fallbackSymbol;
      _marketError = '';
    });
    _syncInputControllers();
    await _persist();
    await _refreshMarketData();
    _snack('已删除 ${profile.name} ${profile.symbol}');
  }

  void _applyBulk() {
    _dismissKeyboard();
    final tokens = _bulkController.text
        .trim()
        .split(RegExp(r'[\n,，\s\t]+'))
        .where((item) => item.isNotEmpty)
        .toList();
    if (tokens.length != 2) {
      _snack('格式应为：持仓,成本价');
      return;
    }
    final holdings = int.tryParse(tokens[0]);
    final cost = double.tryParse(tokens[1]);
    if (holdings == null || holdings < 0 || cost == null || cost < 0) {
      _snack('请确认持仓和成本价有效');
      return;
    }
    _holdingsController.text = '$holdings';
    _costController.text = cost.toStringAsFixed(2);
    _bulkController.clear();
    _snack('已应用持仓数据，请点击更新策略');
  }

  void _updateStrategy() {
    _dismissKeyboard();
    final price = _profile.price;
    final holdings = int.tryParse(_holdingsController.text.trim());
    final cost = double.tryParse(_costController.text.trim());
    if (price == null || _profile.ma20 == null) {
      _snack('请先刷新行情');
      return;
    }
    if (holdings == null || holdings < 0 || cost == null || cost < 0) {
      _snack('请填写有效的持仓和成本价');
      return;
    }
    if (holdings > 0 && cost == 0) {
      _snack('有持仓时，成本价不能为 0');
      return;
    }

    final profile = _profile;
    profile
      ..holdings = holdings
      ..costPrice = cost
      ..basePrice = price
      ..lastUpdatedAt = _nowText();
    _addStrategyLog(
      '策略更新',
      '${_signalText()}；持仓 $holdings 股；成本价 ${cost.toStringAsFixed(2)}',
    );
    _saveSnapshot();
    _persist();
    setState(() {});
    _snack('策略已更新并保存快照');
  }

  void _submitTrade() {
    _dismissKeyboard();
    final price = double.tryParse(_tradePriceController.text.trim());
    final shares = int.tryParse(_tradeSharesController.text.trim());
    if (price == null || price <= 0 || shares == null || shares <= 0) {
      _snack('成交价必须大于 0，股数必须是正整数');
      return;
    }
    if (shares % _lotSize != 0) {
      _snack('为符合 A 股整手规则，股数请输入 100 的整数倍');
      return;
    }

    final profile = _profile;
    if (_tradeAction == '买入') {
      profile
        ..costPrice = profile.holdings + shares == 0
            ? 0
            : ((profile.totalCost + price * shares) /
                      (profile.holdings + shares))
                  .toDouble()
        ..holdings += shares;
    } else {
      if (shares > profile.holdings) {
        _snack('卖出股数不能超过当前持仓 ${profile.holdings} 股');
        return;
      }
      final profit = (price - profile.costPrice) * shares;
      profile
        ..realizedPnl += profit
        ..holdings -= shares
        ..costPrice = profile.holdings == 0 ? 0 : profile.costPrice;
      profile.tradeLogs.insert(
        0,
        TradeLog(
          time: _nowText(),
          action: '卖出',
          price: price,
          shares: shares,
          profit: profit,
        ),
      );
    }

    if (_tradeAction == '买入') {
      profile.tradeLogs.insert(
        0,
        TradeLog(
          time: _nowText(),
          action: '买入',
          price: price,
          shares: shares,
          profit: 0,
        ),
      );
    }
    if (profile.tradeLogs.length > 100) {
      profile.tradeLogs.removeLast();
    }
    _syncInputControllers();
    _tradePriceController.clear();
    _tradeSharesController.clear();
    _persist();
    setState(() {});
    _snack('成交记录已保存');
  }

  void _saveSnapshot() {
    final profile = _profile;
    if (profile.price == null ||
        profile.ma20 == null ||
        profile.basePrice == null) {
      return;
    }
    profile.snapshots.insert(
      0,
      SnapshotRecord(
        id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
        dataDate: profile.dataDate,
        price: profile.price!,
        ma20: profile.ma20!,
        holdings: profile.holdings,
        costPrice: profile.costPrice,
        basePrice: profile.basePrice!,
        createdAt: _nowText(),
      ),
    );
    if (profile.snapshots.length > 30) profile.snapshots.removeLast();
  }

  void _loadSnapshot(SnapshotRecord item) {
    _dismissKeyboard();
    final profile = _profile;
    profile
      ..dataDate = item.dataDate
      ..price = item.price
      ..ma20 = item.ma20
      ..holdings = item.holdings
      ..costPrice = item.costPrice
      ..basePrice = item.basePrice
      ..lastUpdatedAt = _nowText();
    _syncInputControllers();
    _addStrategyLog('载入快照', '已载入 ${item.dataDate} 的录入数据');
    _persist();
    setState(() {});
  }

  void _resetAccount() {
    _dismissKeyboard();
    final profile = _profile;
    profile
      ..holdings = 0
      ..costPrice = 0
      ..realizedPnl = 0;
    _syncInputControllers();
    _addStrategyLog('账户重置', '已清空当前标的持仓、成本和已实现盈亏');
    _persist();
    setState(() {});
  }

  void _addStrategyLog(String action, String detail) {
    _profile.strategyLogs.insert(
      0,
      StrategyLog(time: _nowText(), action: action, detail: detail),
    );
    if (_profile.strategyLogs.length > 100) {
      _profile.strategyLogs.removeLast();
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _dismissKeyboard() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus?.hasFocus ?? false) {
      focus?.unfocus();
    }
  }

  String _signalText() {
    final profile = _profile;
    if (profile.price == null || profile.ma20 == null) return '等待输入';
    return profile.price! > profile.ma20! ? '可买入' : '暂停买入';
  }

  double get _unrealizedPnl {
    final profile = _profile;
    if (profile.price == null) return 0;
    return (profile.price! - profile.costPrice) * profile.holdings;
  }

  List<GridLevel> get _gridLevels {
    final base = _profile.basePrice;
    return [
      GridLevel('+2%', base == null ? null : base * 1.02, true),
      GridLevel('+4%', base == null ? null : base * 1.04, true),
      GridLevel('+6%', base == null ? null : base * 1.06, true),
      GridLevel('-2%', base == null ? null : base * .98, false),
      GridLevel('-4%', base == null ? null : base * .96, false),
      GridLevel('-6%', base == null ? null : base * .94, false),
    ];
  }

  Map<String, dynamic> get _advisor {
    final profile = _profile;
    final current = profile.price;
    final base = profile.basePrice;
    final ma = profile.ma20;
    if (current == null || base == null || ma == null) {
      return {
        'tone': 'neutral',
        'badge': '等待策略基准',
        'title': '先刷新行情并更新策略',
        'reason': '建议器需要当前行情、MA20 和已保存的基准价。',
        'shares': 0,
        'amount': '--',
        'next': '--',
        'hint': '建立有效基准后生成建议。',
      };
    }

    final sells = _gridLevels.where((level) {
      return level.isSell && level.price != null && current >= level.price!;
    }).toList();
    final buys = _gridLevels.where((level) {
      return !level.isSell && level.price != null && current <= level.price!;
    }).toList();
    final availableSell = (profile.holdings ~/ _lotSize) * _lotSize;
    final signalBuy = current > ma;

    if (sells.isNotEmpty) {
      final planned = sells.length * _gridShares;
      final shares = min(planned, availableSell);
      return {
        'tone': 'danger',
        'badge': shares > 0 ? '建议减仓' : '卖点已到',
        'title': shares > 0 ? '已触发 ${sells.length} 档卖出网格' : '持仓不足，当前不可卖出',
        'reason':
            '当前价 ${_money(current)} 已到达 ${sells.map((e) => e.label).join(' / ')} 卖出位。',
        'shares': shares,
        'amount': shares > 0 ? '${_money(shares * current)} 元' : '--',
        'next': _nextLevel(current, true),
        'hint': '按每档 $_gridShares 股，A 股卖出按整手估算。',
      };
    }
    if (buys.isNotEmpty) {
      final shares = buys.length * _gridShares;
      final paused = !signalBuy;
      return {
        'tone': paused ? 'warning' : 'success',
        'badge': paused ? '暂缓加仓' : '建议加仓',
        'title': '已触发 ${buys.length} 档买入网格',
        'reason': paused
            ? '当前价已进入买入区，但仍低于 MA20，暂不建议机械加仓。'
            : '当前价已进入买入区，同时满足 MA20 过滤条件。',
        'shares': shares,
        'amount': '${_money(shares * current)} 元',
        'next': _nextLevel(current, false),
        'hint': '这里只估算占资，未扣手续费、滑点和可用资金。',
      };
    }
    return {
      'tone': 'neutral',
      'badge': '继续观察',
      'title': '当前未触发新的档位',
      'reason': '当前价仍在网格区间内，等待接近下一档位。',
      'shares': 0,
      'amount': '--',
      'next': _nextLevel(current, true),
      'hint': '默认单格执行 $_gridShares 股。',
    };
  }

  String _nextLevel(double current, bool preferSell) {
    final levels = preferSell
        ? _gridLevels.where((level) => level.isSell)
        : _gridLevels.where((level) => !level.isSell);
    final next = preferSell
        ? levels
              .where((level) => level.price != null && current < level.price!)
              .firstOrNull
        : levels
              .where((level) => level.price != null && current > level.price!)
              .lastOrNull;
    if (next != null) return '${next.label} · ${_money(next.price!)}';
    return preferSell ? '上方网格已触发' : '下方网格已触发';
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final profile = _profile;
    final signal = _signalText();
    final signalColor = signal == '可买入'
        ? _red
        : signal == '暂停买入'
        ? _green
        : _muted;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _canvas,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '操盘台',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: _muted, letterSpacing: 1.2),
            ),
            Text(
              '${profile.name} · 网格策略',
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.tonalIcon(
              onPressed: _loading ? null : _refreshMarketData,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(_loading ? '同步中' : '刷新'),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: _dismissKeyboard,
        behavior: HitTestBehavior.translucent,
        child: RefreshIndicator(
          onRefresh: _refreshMarketData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStockSelector(),
                const SizedBox(height: 14),
                _buildMarketCard(signal, signalColor),
                if (_marketError.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildNotice(_marketError, _amber),
                ],
                if (_riskMessage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildNotice(_riskMessage, _red),
                ],
                const SizedBox(height: 14),
                _buildAccountCard(),
                const SizedBox(height: 14),
                _buildAdvisorCard(),
                const SizedBox(height: 14),
                _buildGridCard(),
                const SizedBox(height: 14),
                _buildRecordsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _riskMessage {
    final profile = _profile;
    if (profile.price == null || profile.ma20 == null || profile.ma20 == 0) {
      return '';
    }
    final deviation =
        ((profile.price! - profile.ma20!).abs() / profile.ma20!) * 100;
    return deviation >= 5
        ? '当前价格偏离 MA20 ${deviation.toStringAsFixed(2)}%，不建议仅凭单一信号下单。'
        : '';
  }

  Widget _buildStockSelector() {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('标的管理', '当前保存 ${_profiles.length} 只股票'),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Row(
              children: _profiles.values.map((profile) {
                final selected = profile.symbol == _selectedSymbol;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: selected,
                    label: Text('${profile.name} ${profile.symbol}'),
                    onSelected: (_) => _selectStock(profile.symbol),
                    selectedColor: _blue.withValues(alpha: .14),
                    side: BorderSide(
                      color: selected
                          ? _blue
                          : Colors.black.withValues(alpha: .08),
                    ),
                    labelStyle: TextStyle(
                      color: selected ? _blue : _ink,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newStockController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _dismissKeyboard(),
            onTapOutside: (_) => _dismissKeyboard(),
            decoration: const InputDecoration(
              hintText: '新增代码，如 600326',
              counterText: '',
              prefixIcon: Icon(Icons.add_chart_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(onPressed: _addStock, child: const Text('添加')),
              OutlinedButton.icon(
                onPressed: _deleteCurrentStock,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('删除当前'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketCard(String signal, Color signalColor) {
    final profile = _profile;
    final price = profile.price;
    final change = profile.ma20 == null || price == null || profile.ma20 == 0
        ? null
        : ((price - profile.ma20!) / profile.ma20!) * 100;
    return _surface(
      color: _ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${profile.name}  ${profile.symbol}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              _badge(signal, signalColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price == null ? '--' : _money(price),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: .95,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                change == null
                    ? '等待 MA20'
                    : '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}% vs MA20',
                style: TextStyle(
                  color: change == null
                      ? Colors.white54
                      : (change >= 0
                            ? const Color(0xFFFF9A9A)
                            : const Color(0xFF74D7AA)),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric(
                'MA20',
                profile.ma20 == null ? '--' : _money(profile.ma20!),
              ),
              _metric(
                '基准价',
                profile.basePrice == null ? '--' : _money(profile.basePrice!),
              ),
              _metric(
                '数据日期',
                profile.dataDate.isEmpty ? '--' : profile.dataDate,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.lastUpdatedAt.isEmpty
                ? '最新价来自公开行情接口，持仓和成本保存在本机。'
                : '最后更新 ${profile.lastUpdatedAt}',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    final profile = _profile;
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('账户与策略', '本地记录，不会上传交易账户'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _readonlyField(
                  label: '最新价',
                  value: profile.price == null ? '--' : _money(profile.price!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _readonlyField(
                  label: 'MA20',
                  value: profile.ma20 == null ? '--' : _money(profile.ma20!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _holdingsController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _dismissKeyboard(),
                  onTapOutside: (_) => _dismissKeyboard(),
                  decoration: const InputDecoration(
                    labelText: '当前持仓（股）',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _costController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _dismissKeyboard(),
                  onTapOutside: (_) => _dismissKeyboard(),
                  decoration: const InputDecoration(
                    labelText: '持仓成本价',
                    prefixIcon: Icon(Icons.price_check_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bulkController,
            maxLines: 2,
            onTapOutside: (_) => _dismissKeyboard(),
            decoration: const InputDecoration(
              labelText: '一键粘贴持仓',
              hintText: '支持：2200,22.00',
              prefixIcon: Icon(Icons.content_paste_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _applyBulk,
                icon: const Icon(Icons.input_rounded, size: 18),
                label: const Text('应用粘贴'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _updateStrategy,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('更新策略'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _summaryMetric('当前持仓', '${profile.holdings} 股'),
              _summaryMetric(
                '未实现盈亏',
                '${_unrealizedPnl >= 0 ? '+' : ''}${_money(_unrealizedPnl)}',
                color: _unrealizedPnl >= 0 ? _red : _green,
              ),
              _summaryMetric(
                '已实现盈亏',
                '${profile.realizedPnl >= 0 ? '+' : ''}${_money(profile.realizedPnl)}',
                color: profile.realizedPnl >= 0 ? _red : _green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorCard() {
    final advisor = _advisor;
    final tone = advisor['tone'] as String;
    final color = tone == 'success'
        ? _green
        : tone == 'danger'
        ? _red
        : tone == 'warning'
        ? _amber
        : _muted;
    return _surface(
      color: color.withValues(alpha: .07),
      borderColor: color.withValues(alpha: .18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _sectionLabel('仓位建议器', '按网格触发和 A 股整手规则估算')),
              const SizedBox(width: 10),
              _badge(advisor['badge'] as String, color),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            advisor['title'] as String,
            style: const TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            advisor['reason'] as String,
            style: const TextStyle(color: _muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _advisorMetric('建议股数', '${advisor['shares']} 股'),
              _advisorMetric('预计成交额', advisor['amount'] as String),
              _advisorMetric('下一触发位', advisor['next'] as String),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advisor['hint'] as String,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard() {
    final cardWidth = (MediaQuery.sizeOf(context).width - 74).clamp(
      132.0,
      260.0,
    );
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('网格价位', '单格默认 $_gridShares 股'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _gridLevels.map((level) {
              final color = level.isSell ? _red : _green;
              return SizedBox(
                width: cardWidth,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: .15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            level.isSell
                                ? '卖出 ${level.label}'
                                : '买入 ${level.label}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            level.price == null ? '--' : _money(level.price!),
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsCard() {
    final profile = _profile;
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('交易与策略记录', '最多保留最近 100 条'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _tradeAction,
                  decoration: const InputDecoration(labelText: '动作'),
                  items: const [
                    DropdownMenuItem(value: '买入', child: Text('买入')),
                    DropdownMenuItem(value: '卖出', child: Text('卖出')),
                  ],
                  onChanged: (value) =>
                      setState(() => _tradeAction = value ?? '买入'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _tradePriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _dismissKeyboard(),
                  onTapOutside: (_) => _dismissKeyboard(),
                  decoration: const InputDecoration(labelText: '成交价'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _tradeSharesController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _dismissKeyboard(),
                  onTapOutside: (_) => _dismissKeyboard(),
                  decoration: const InputDecoration(labelText: '股数'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _submitTrade,
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('记录成交'),
            ),
          ),
          if (profile.tradeLogs.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...profile.tradeLogs
                .take(3)
                .map(
                  (log) => _logRow(
                    '${log.time}  ${log.action} ${_money(log.price)} × ${log.shares} 股',
                    log.profit == 0
                        ? '--'
                        : '${log.profit >= 0 ? '+' : ''}${_money(log.profit)}',
                    log.profit > 0 ? _red : (log.profit < 0 ? _green : _muted),
                  ),
                ),
          ] else
            _emptyText('暂无成交日志'),
          const Divider(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '每日快照',
                style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: profile.snapshots.isEmpty
                    ? null
                    : () {
                        setState(() => profile.snapshots.clear());
                        _persist();
                      },
                child: const Text('清空快照'),
              ),
            ],
          ),
          if (profile.snapshots.isEmpty)
            _emptyText('暂无快照，更新策略后自动生成')
          else
            ...profile.snapshots
                .take(3)
                .map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      '${item.dataDate}  价 ${_money(item.price)} / MA20 ${_money(item.ma20)}',
                      style: const TextStyle(color: _ink, fontSize: 13),
                    ),
                    subtitle: Text(
                      '持仓 ${item.holdings} 股，成本 ${_money(item.costPrice)}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: () => _loadSnapshot(item),
                      child: const Text('载入'),
                    ),
                  ),
                ),
          if (profile.strategyLogs.isNotEmpty) ...[
            const Divider(height: 26),
            const Text(
              '最近策略日志',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            ...profile.strategyLogs
                .take(3)
                .map(
                  (log) =>
                      _logRow('${log.time}  ${log.action}', log.detail, _muted),
                ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetAccount,
              icon: const Icon(Icons.restart_alt_rounded, size: 17),
              label: const Text('重置账户'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surface({
    required Widget child,
    Color color = Colors.white,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor ?? Colors.black.withValues(alpha: .055),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        Flexible(
          child: Text(
            subtitle,
            textAlign: TextAlign.right,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value, {Color color = _ink}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _advisorMetric(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readonlyField({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logRow(String title, String detail, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: _ink, fontSize: 12, height: 1.35),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              detail,
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
    );
  }
}

String _money(double value) => value.toStringAsFixed(2);

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _nowText() {
  final now = DateTime.now();
  final date = _formatDate(now);
  final hh = now.hour.toString().padLeft(2, '0');
  final mm = now.minute.toString().padLeft(2, '0');
  final ss = now.second.toString().padLeft(2, '0');
  return '$date $hh:$mm:$ss';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}
