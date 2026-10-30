import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'feature_drawer.dart';

class AveragingCalculatorPage extends StatefulWidget {
  const AveragingCalculatorPage({super.key});

  @override
  State<AveragingCalculatorPage> createState() =>
      _AveragingCalculatorPageState();
}

class _AveragingCalculatorPageState extends State<AveragingCalculatorPage> {
  final _costPriceController = TextEditingController();
  final _holdingSharesController = TextEditingController();
  final _addPriceController = TextEditingController();
  final _addSharesController = TextEditingController();
  final _commissionController = TextEditingController();
  final _transferFeeController = TextEditingController();
  final _communicationFeeController = TextEditingController();

  double? _readNumber(TextEditingController controller) =>
      double.tryParse(controller.text.trim());

  int? _readShares(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  double? _optionalFee(TextEditingController controller) {
    if (controller.text.trim().isEmpty) return 0;
    final fee = _readNumber(controller);
    return fee != null && fee >= 0 ? fee : null;
  }

  int? get _finalShares {
    final holdings = _readShares(_holdingSharesController);
    final added = _readShares(_addSharesController);
    if (holdings == null || added == null || holdings < 0 || added <= 0) {
      return null;
    }
    return holdings.round() + added.round();
  }

  double? get _totalCost {
    final costPrice = _readNumber(_costPriceController);
    final holdings = _readShares(_holdingSharesController);
    final addPrice = _readNumber(_addPriceController);
    final added = _readShares(_addSharesController);
    if (costPrice == null ||
        holdings == null ||
        addPrice == null ||
        added == null ||
        costPrice < 0 ||
        holdings < 0 ||
        addPrice <= 0 ||
        added <= 0) {
      return null;
    }
    final fees = [
      _commissionController,
      _transferFeeController,
      _communicationFeeController,
    ].map(_optionalFee).toList();
    if (fees.any((fee) => fee == null)) return null;
    final totalFees = fees.cast<double>().fold<double>(
      0,
      (sum, fee) => sum + fee,
    );
    return costPrice * holdings + addPrice * added + totalFees;
  }

  double? get _averageCost {
    final shares = _finalShares;
    final total = _totalCost;
    if (shares == null || shares == 0 || total == null) return null;
    return total / shares;
  }

  @override
  void dispose() {
    _costPriceController.dispose();
    _holdingSharesController.dispose();
    _addPriceController.dispose();
    _addSharesController.dispose();
    _commissionController.dispose();
    _transferFeeController.dispose();
    _communicationFeeController.dispose();
    super.dispose();
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    String suffix = '',
    bool integer = false,
  }) => TextField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: !integer),
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix.isEmpty ? null : suffix,
      isDense: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final shares = _finalShares;
    final total = _totalCost;
    final average = _averageCost;

    return Scaffold(
      backgroundColor: appIsNight
          ? AppPalette.darkCanvas
          : AppPalette.lightCanvas,
      appBar: AppBar(
        backgroundColor: appIsNight
            ? AppPalette.darkCanvas
            : AppPalette.lightCanvas,
        title: const Text('补仓计算'),
      ),
      drawer: const AppFeatureDrawer(selectedRoute: '/averaging'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: appIsNight
                ? AppPalette.darkSurface
                : AppPalette.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '持仓信息',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _input('成本价', _costPriceController, suffix: '元/股'),
                  const SizedBox(height: 12),
                  _input(
                    '持股数',
                    _holdingSharesController,
                    suffix: '股',
                    integer: true,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '补仓信息',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _input('补仓价', _addPriceController, suffix: '元/股'),
                  const SizedBox(height: 12),
                  _input(
                    '补仓数',
                    _addSharesController,
                    suffix: '股',
                    integer: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: appIsNight
                ? AppPalette.darkSurface
                : AppPalette.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '可选费用',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '填写本次补仓产生的费用；留空按 0 元计算。',
                    style: TextStyle(
                      color: appIsNight
                          ? AppPalette.darkMuted
                          : AppPalette.lightMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _input('手续费', _commissionController, suffix: '元'),
                  const SizedBox(height: 12),
                  _input('过户费', _transferFeeController, suffix: '元'),
                  const SizedBox(height: 12),
                  _input('通信费', _communicationFeeController, suffix: '元'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: appIsNight
                ? const Color(0xFF202D40)
                : const Color(0xFFEAF1FC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '计算结果',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _result('最终持股数量', shares == null ? '—' : '$shares 股'),
                  const SizedBox(height: 10),
                  _result(
                    '最终总成本',
                    total == null ? '—' : '${total.toStringAsFixed(2)} 元',
                  ),
                  const SizedBox(height: 10),
                  _result(
                    '最终成本价',
                    average == null ? '—' : '${average.toStringAsFixed(4)} 元/股',
                    emphasize: true,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
            child: Text(
              '计算口径：原持仓成本 + 补仓金额 + 本次填写的费用。结果仅用于估算。',
              style: TextStyle(
                color: appIsNight
                    ? AppPalette.darkMuted
                    : AppPalette.lightMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _result(String label, String value, {bool emphasize = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          color: appIsNight ? AppPalette.darkMuted : const Color(0xFF536275),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: const Color(0xFF1769E0),
          fontSize: emphasize ? 20 : 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
