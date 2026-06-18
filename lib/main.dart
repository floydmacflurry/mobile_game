import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FinanceQuestApp());
}

const MethodChannel _androidLinkChannel = MethodChannel(
  'calliano_project/android_links',
);

class FinanceQuestApp extends StatefulWidget {
  const FinanceQuestApp({super.key});

  @override
  State<FinanceQuestApp> createState() => _FinanceQuestAppState();
}

class _FinanceQuestAppState extends State<FinanceQuestApp> {
  static const double _minUiScale = 0.82;
  static const double _maxUiScale = 1.08;

  String? _playerName;
  double _uiScale = 1;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _playerName = prefs.getString('player_name');
      _uiScale = (prefs.getDouble('ui_scale') ?? 1)
          .clamp(_minUiScale, _maxUiScale)
          .toDouble();
      _loaded = true;
    });
  }

  Future<void> _saveProfile(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name', name);
    setState(() => _playerName = name);
  }

  Future<void> _saveUiScale(double scale) async {
    final nextScale = scale.clamp(_minUiScale, _maxUiScale).toDouble();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ui_scale', nextScale);
    setState(() => _uiScale = nextScale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinQuest',
      theme: _buildTheme(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return _UiScaleScope(
          scale: _uiScale,
          child: MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(_uiScale)),
            child: child ?? const SizedBox(),
          ),
        );
      },
      home: !_loaded
          ? const _LoadingScreen()
          : _playerName == null
          ? ProfileSetupScreen(onSaved: _saveProfile)
          : MainMenuScreen(
              playerName: _playerName!,
              uiScale: _uiScale,
              onEditProfile: () => setState(() => _playerName = null),
              onUiScaleChanged: _saveUiScale,
            ),
    );
  }
}

class _UiScaleScope extends InheritedWidget {
  const _UiScaleScope({required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_UiScaleScope>();
    return scope?.scale ?? 1;
  }

  @override
  bool updateShouldNotify(_UiScaleScope oldWidget) {
    return scale != oldWidget.scale;
  }
}

double _ui(BuildContext context, double value) {
  return value * _UiScaleScope.of(context);
}

EdgeInsets _uiInsets(BuildContext context, EdgeInsets insets) {
  final scale = _UiScaleScope.of(context);
  return EdgeInsets.fromLTRB(
    insets.left * scale,
    insets.top * scale,
    insets.right * scale,
    insets.bottom * scale,
  );
}

int _scaledJoyGain(int value) {
  if (value <= 0) {
    return 0;
  }
  return max(1, (value * 0.65).round());
}

int _scaledJoyDeclineDelta(int value) {
  if (value == 0) {
    return 0;
  }
  if (value > 0) {
    return max(1, (value * 0.5).round());
  }
  return (value * 1.25).floor();
}

ThemeData _buildTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF35C94B),
      brightness: Brightness.light,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(fontSize: 20, height: 1.32, letterSpacing: 0),
      bodyMedium: TextStyle(fontSize: 16, height: 1.28, letterSpacing: 0),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.onSaved});

  final ValueChanged<String> onSaved;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _controller = TextEditingController();
  final RegExp _allowedName = RegExp(r'^[A-Za-zА-Яа-яЁё0-9 ._-]{3,20}$');

  bool get _valid => _allowedName.hasMatch(_controller.text.trim());

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: _uiInsets(
            context,
            const EdgeInsets.fromLTRB(32, 22, 32, 28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RoundIconButton(
                icon: Icons.close_rounded,
                color: const Color(0xFF35C94B),
                iconColor: Colors.black,
                onPressed: () => _controller.clear(),
              ),
              SizedBox(height: _ui(context, 44)),
              Text(
                'Введите ваше имя',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: _ui(context, 18)),
              Text(
                'Можно использовать псевдоним. Это офлайн-игра: имя хранится только на вашем устройстве и никому не отправляется.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: _ui(context, 92)),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_valid) {
                    widget.onSaved(_controller.text.trim());
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Имя',
                  errorText: _controller.text.isEmpty || _valid
                      ? null
                      : 'От 3 до 20 символов: буквы, цифры, точка, пробел, дефис и нижнее подчёркивание',
                ),
              ),
              SizedBox(height: _ui(context, 12)),
              Text(
                'От 3 до 20 символов: латинские и русские буквы, цифры, точка, пробел, дефис и нижнее подчёркивание.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _controller.text.isEmpty || _valid
                      ? const Color(0xFF8F96A3)
                      : const Color(0xFFB14652),
                ),
              ),
              const Spacer(),
              _GradientButton(
                label: 'Далее',
                icon: Icons.arrow_forward_rounded,
                enabled: _valid,
                onPressed: () => widget.onSaved(_controller.text.trim()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    super.key,
    required this.playerName,
    required this.uiScale,
    required this.onEditProfile,
    required this.onUiScaleChanged,
  });

  final String playerName;
  final double uiScale;
  final VoidCallback onEditProfile;
  final ValueChanged<double> onUiScaleChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: _uiInsets(
            context,
            const EdgeInsets.fromLTRB(32, 28, 32, 28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(name: playerName),
                  SizedBox(width: _ui(context, 16)),
                  Expanded(
                    child: Text(
                      playerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  _RoundIconButton(
                    icon: Icons.more_vert_rounded,
                    color: const Color(0xFFF1F2F6),
                    onPressed: () => _showProfileMenu(context),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    const _GameLogo(size: 118),
                    SizedBox(height: _ui(context, 12)),
                    Text(
                      'FinQuest',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    SizedBox(height: _ui(context, 8)),
                    Text(
                      'Офлайн-симулятор финансовых решений',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF7B818D),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _MenuGradientTile(
                title: 'Начать игру',
                icon: Icons.sports_esports_rounded,
                colors: const [Color(0xFF62C899), Color(0xFFD4F173)],
                height: 132,
                onPressed: () => _showDifficultyPicker(context),
              ),
              SizedBox(height: _ui(context, 22)),
              _MenuGradientTile(
                title: 'Как играть?',
                icon: Icons.help_outline_rounded,
                colors: const [Color(0xFF8BA8E8), Color(0xFFE178E8)],
                height: 132,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
                ),
              ),
              SizedBox(height: _ui(context, 18)),
              _MenuGradientTile(
                title: 'Поддержка',
                icon: Icons.groups_rounded,
                colors: const [Color(0xFFF0C95A), Color(0xFFF28E8B)],
                height: 92,
                onPressed: () => _openSupport(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSupport(BuildContext context) async {
    try {
      await _androidLinkChannel.invokeMethod<void>(
        'openUrl',
        'https://vk.com/callianoproject',
      );
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть ссылку поддержки.')),
        );
      }
    }
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ActionSheet(
          children: [
            _SheetButton(
              label: 'Изменить имя',
              icon: Icons.edit_rounded,
              colors: const [Color(0xFF89C4FF), Color(0xFFD57BEA)],
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onEditProfile();
              },
            ),
            _SheetButton(
              label: 'Размер интерфейса',
              icon: Icons.format_size_rounded,
              colors: const [Color(0xFF67C89B), Color(0xFFD6F37C)],
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _showUiScaleDialog(context);
              },
            ),
            _SheetButton(
              label: 'Закрыть',
              icon: Icons.close_rounded,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showUiScaleDialog(BuildContext context) {
    var draftScale = uiScale;
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final percent = (draftScale * 100).round();
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_ui(context, 28)),
              ),
              title: const Text('Размер интерфейса'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: _ui(context, 8)),
                  Text(
                    'Уменьшите масштаб, если на маленьком экране карточки и кнопки кажутся слишком крупными.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF777D88),
                    ),
                  ),
                  SizedBox(height: _ui(context, 22)),
                  Row(
                    children: [
                      const Text('Мельче'),
                      Expanded(
                        child: Slider(
                          min: 0.82,
                          max: 1.08,
                          divisions: 13,
                          label: '$percent%',
                          value: draftScale,
                          onChanged: (value) {
                            setDialogState(() => draftScale = value);
                          },
                        ),
                      ),
                      const Text('Крупнее'),
                    ],
                  ),
                  SizedBox(height: _ui(context, 16)),
                  Container(
                    width: double.infinity,
                    padding: _uiInsets(context, const EdgeInsets.all(16)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F6),
                      borderRadius: BorderRadius.circular(_ui(context, 18)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54 * draftScale,
                          height: 54 * draftScale,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF67C89B), Color(0xFFD6F37C)],
                            ),
                          ),
                          child: Icon(
                            Icons.sports_esports_rounded,
                            color: Colors.white,
                            size: 28 * draftScale,
                          ),
                        ),
                        SizedBox(width: _ui(context, 16)),
                        Expanded(
                          child: Text(
                            'Пример масштаба',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => setDialogState(() => draftScale = 1),
                  child: const Text('Сбросить'),
                ),
                FilledButton(
                  onPressed: () {
                    onUiScaleChanged(draftScale);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDifficultyPicker(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: _uiInsets(
            context,
            const EdgeInsets.symmetric(horizontal: 28),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ui(context, 28)),
          ),
          child: Padding(
            padding: _uiInsets(context, const EdgeInsets.all(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Выбери сложность',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _RoundIconButton(
                      icon: Icons.close_rounded,
                      color: const Color(0xFFE9EAEE),
                      size: 44,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: _ui(context, 18)),
                _DifficultyTile(
                  title: 'Лёгкий',
                  subtitle: '5 игровых лет',
                  colors: const [Color(0xFF62C899), Color(0xFFD4F173)],
                  onPressed: () => _startGame(context, GameDifficulty.easy),
                ),
                SizedBox(height: _ui(context, 14)),
                _DifficultyTile(
                  title: 'Средний',
                  subtitle:
                      '7 игровых лет. Больше активов, кредит и обязательные расходы.',
                  colors: const [Color(0xFF8AAFE8), Color(0xFF72D0EF)],
                  onPressed: () => _startGame(context, GameDifficulty.medium),
                ),
                SizedBox(height: _ui(context, 14)),
                _DifficultyTile(
                  title: 'Сложный',
                  subtitle:
                      '10 игровых лет. Криптовалюты, больше риска и событий.',
                  colors: const [Color(0xFFE16169), Color(0xFFFF9B93)],
                  onPressed: () => _startGame(context, GameDifficulty.hard),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startGame(BuildContext context, GameDifficulty difficulty) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FinanceGameScreen(playerName: playerName, difficulty: difficulty),
      ),
    );
  }
}

const double _startingAnnualSalary = 568560;

enum GameDifficulty {
  easy('Лёгкий', 5, 700000, _startingAnnualSalary, false, false),
  medium('Средний', 7, 650000, _startingAnnualSalary, true, false),
  hard('Сложный', 10, 600000, _startingAnnualSalary, true, true);

  const GameDifficulty(
    this.label,
    this.years,
    this.startCash,
    this.startSalary,
    this.hasCredit,
    this.hasCrypto,
  );

  final String label;
  final int years;
  final double startCash;
  final double startSalary;
  final bool hasCredit;
  final bool hasCrypto;
}

enum GameTab {
  budget('Бюджет', Icons.account_balance_wallet_outlined),
  investments('Инвестиции', Icons.show_chart_rounded),
  news('Новости', Icons.newspaper_rounded);

  const GameTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

enum InstrumentCategory {
  stocks('Акции'),
  bonds('Облигации'),
  deposits('Вклады'),
  crypto('Криптовалюты'),
  other('Прочее');

  const InstrumentCategory(this.label);

  final String label;
}

class MarketInstrument {
  const MarketInstrument({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.icon,
    required this.color,
    required this.minimum,
    required this.baseReturn,
    required this.volatility,
    required this.risk,
  });

  final String id;
  final String name;
  final InstrumentCategory category;
  final String description;
  final IconData icon;
  final Color color;
  final double minimum;
  final double baseReturn;
  final double volatility;
  final double risk;
}

class NewsItem {
  const NewsItem({
    required this.title,
    required this.body,
    this.impacts = const {},
    this.bankruptcyRisks = const {},
  });

  final String title;
  final String body;
  final Map<String, double> impacts;
  final Map<String, double> bankruptcyRisks;
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.cost,
    required this.joy,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double cost;
  final int joy;
}

class LifeChoice {
  const LifeChoice({
    required this.id,
    required this.title,
    required this.body,
    required this.cost,
    required this.acceptJoy,
    required this.declineJoy,
    this.annualExpenseDelta = 0,
  });

  final String id;
  final String title;
  final String body;
  final double cost;
  final int acceptJoy;
  final int declineJoy;
  final double annualExpenseDelta;
}

class EducationOffer {
  const EducationOffer({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.cost,
    required this.boostMin,
    required this.boostMax,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final double cost;
  final double boostMin;
  final double boostMax;
}

class InsuranceOffer {
  const InsuranceOffer({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.cost,
    required this.coverage,
  });

  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final double cost;
  final double coverage;
}

class BankCardOffer {
  const BankCardOffer({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.cashback,
    required this.colors,
  });

  final String id;
  final String title;
  final String subtitle;
  final double cost;
  final double cashback;
  final List<Color> colors;
}

class CreditState {
  const CreditState({
    required this.bank,
    required this.amount,
    required this.yearsLeft,
    required this.payment,
  });

  final String bank;
  final double amount;
  final int yearsLeft;
  final double payment;
}

class CardDebtState {
  const CardDebtState({
    required this.amount,
    required this.yearsLeft,
    required this.payment,
  });

  final double amount;
  final int yearsLeft;
  final double payment;
}

class CreditOffer {
  const CreditOffer({
    required this.id,
    required this.bank,
    required this.icon,
    required this.color,
    required this.annualRate,
    required this.baseLimit,
    required this.limitMultiplier,
  });

  final String id;
  final String bank;
  final IconData icon;
  final Color color;
  final double annualRate;
  final double baseLimit;
  final double limitMultiplier;
}

class FinanceGameScreen extends StatefulWidget {
  const FinanceGameScreen({
    super.key,
    required this.playerName,
    required this.difficulty,
  });

  final String playerName;
  final GameDifficulty difficulty;

  @override
  State<FinanceGameScreen> createState() => _FinanceGameScreenState();
}

class _FinanceGameScreenState extends State<FinanceGameScreen> {
  static const List<MarketInstrument> _allInstruments = [
    MarketInstrument(
      id: 'all_market',
      name: 'All-Market',
      category: InstrumentCategory.stocks,
      description:
          'Маркетплейс повседневных товаров. Растёт на сильном потребительском спросе.',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFFF8618),
      minimum: 45000,
      baseReturn: 0.11,
      volatility: 0.2,
      risk: 0.16,
    ),
    MarketInstrument(
      id: 'spacecar',
      name: 'SpaceCar',
      category: InstrumentCategory.stocks,
      description:
          'Ракеты, космические запуски и научные проекты. Любой контракт может дать резкий рост, а неудачный запуск — сильное падение.',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFE91E63),
      minimum: 50000,
      baseReturn: 0.13,
      volatility: 0.28,
      risk: 0.2,
    ),
    MarketInstrument(
      id: 'buildaero',
      name: 'BuildAero',
      category: InstrumentCategory.stocks,
      description:
          'Самолёты, дроны и космические сервисы. Сильно зависит от контрактов.',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF54D5EE),
      minimum: 45000,
      baseReturn: 0.1,
      volatility: 0.19,
      risk: 0.15,
    ),
    MarketInstrument(
      id: 'igadgets',
      name: 'iGadgets',
      category: InstrumentCategory.stocks,
      description:
          'Смартфоны, ноутбуки и устройства для дома. Зависит от поставок чипов.',
      icon: Icons.phone_iphone_rounded,
      color: Color(0xFF202020),
      minimum: 40000,
      baseReturn: 0.09,
      volatility: 0.18,
      risk: 0.13,
    ),
    MarketInstrument(
      id: 'foodstyle',
      name: 'FoodStyle',
      category: InstrumentCategory.stocks,
      description:
          'Сеть супермаркетов с товарами на каждый день. Обычно спокойнее технологичных компаний.',
      icon: Icons.eco_rounded,
      color: Color(0xFF7ECF65),
      minimum: 35000,
      baseReturn: 0.075,
      volatility: 0.12,
      risk: 0.09,
    ),
    MarketInstrument(
      id: 'green_bond',
      name: 'Зеленый банк',
      category: InstrumentCategory.bonds,
      description:
          'Частный банк. Облигации дают умеренный купон, но зависят от качества кредитного портфеля.',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF83D9A3),
      minimum: 30000,
      baseReturn: 0.075,
      volatility: 0.05,
      risk: 0.05,
    ),
    MarketInstrument(
      id: 'federal_bond',
      name: 'Федеральный банк',
      category: InstrumentCategory.bonds,
      description:
          'Государственный банк. Самый стабильный инструмент: не банкротится, но доходность скромнее.',
      icon: Icons.flag_rounded,
      color: Color(0xFF83AEE0),
      minimum: 30000,
      baseReturn: 0.065,
      volatility: 0.015,
      risk: 0,
    ),
    MarketInstrument(
      id: 'toy_bond',
      name: 'Мир игрушек',
      category: InstrumentCategory.bonds,
      description:
          'Корпоративные облигации с повышенным купоном и средним риском.',
      icon: Icons.casino_rounded,
      color: Color(0xFF4CC7EE),
      minimum: 35000,
      baseReturn: 0.087,
      volatility: 0.065,
      risk: 0.07,
    ),
    MarketInstrument(
      id: 'western_deposit',
      name: 'Западный',
      category: InstrumentCategory.deposits,
      description:
          'Частный банк с вкладом до 8% годовых. Проценты начисляются раз в ход.',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF0E6D83),
      minimum: 25000,
      baseReturn: 0.055,
      volatility: 0.015,
      risk: 0.01,
    ),
    MarketInstrument(
      id: 'safe_deposit',
      name: 'Зеленый банк',
      category: InstrumentCategory.deposits,
      description:
          'Вклад в частном банке с умеренной доходностью и низким риском.',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF94E080),
      minimum: 25000,
      baseReturn: 0.045,
      volatility: 0.012,
      risk: 0.01,
    ),
    MarketInstrument(
      id: 'coin_crypto',
      name: 'CoinCrypto',
      category: InstrumentCategory.crypto,
      description:
          'Высокая волатильность: можно много заработать или потерять почти всё.',
      icon: Icons.currency_bitcoin_rounded,
      color: Color(0xFFFFBE3D),
      minimum: 30000,
      baseReturn: 0.04,
      volatility: 0.9,
      risk: 0.45,
    ),
    MarketInstrument(
      id: 'virtual_coin',
      name: 'VirtualCoin',
      category: InstrumentCategory.crypto,
      description: 'Мемный цифровой актив. Доходность непредсказуема.',
      icon: Icons.flutter_dash_rounded,
      color: Color(0xFFFFA51E),
      minimum: 25000,
      baseReturn: 0.02,
      volatility: 1.0,
      risk: 0.52,
    ),
    MarketInstrument(
      id: 'fortuna',
      name: 'Fortuna Invest',
      category: InstrumentCategory.other,
      description:
          'Альтернативный проект с высокой обещанной доходностью и высоким риском.',
      icon: Icons.casino_rounded,
      color: Color(0xFF1C82F6),
      minimum: 40000,
      baseReturn: 0.35,
      volatility: 0.7,
      risk: 0.45,
    ),
    MarketInstrument(
      id: 'city_project',
      name: 'Мой город',
      category: InstrumentCategory.other,
      description: 'Инфраструктурный проект с шансом на крупный рост.',
      icon: Icons.favorite_rounded,
      color: Color(0xFF333333),
      minimum: 35000,
      baseReturn: 0.18,
      volatility: 0.35,
      risk: 0.24,
    ),
  ];

  static const List<NewsItem> _newsPool = [
    NewsItem(
      title: 'SpaceCar получила окно для научного запуска',
      body:
          'Компания готовит серию запусков для университетских лабораторий. Если испытания пройдут без переносов, инвесторы могут резко пересмотреть её стоимость.',
      impacts: {'spacecar': 0.22, 'buildaero': 0.04},
    ),
    NewsItem(
      title: 'Центробанк поднял ставку',
      body:
          'Банки повышают доходность вкладов, а инвесторы осторожнее относятся к рискованным акциям и криптовалютам. Частные банки получают шанс привлечь деньги, но слабые игроки чувствуют давление.',
      impacts: {
        'western_deposit': 0.03,
        'safe_deposit': 0.025,
        'coin_crypto': -0.12,
        'spacecar': -0.07,
      },
      bankruptcyRisks: {
        'green_bond': 0.025,
        'western_deposit': 0.015,
        'coin_crypto': 0.08,
      },
    ),
    NewsItem(
      title: 'Маркетплейсы спорят с поставщиками о комиссиях',
      body:
          'All-Market обещает сохранить цены для покупателей, но партнёры жалуются на рост расходов. Если конфликт решат, оборот вырастет; если нет, маржа может просесть.',
      impacts: {'all_market': 0.07, 'foodstyle': 0.025},
      bankruptcyRisks: {'all_market': 0.01},
    ),
    NewsItem(
      title: 'Поставщики электроники столкнулись с дефицитом чипов',
      body:
          'iGadgets переносит часть поставок смартфонов на конец года. Покупатели всё ещё ждут новую линейку, но задержка может ударить по прибыли.',
      impacts: {'igadgets': -0.18, 'all_market': -0.03, 'toy_bond': 0.025},
      bankruptcyRisks: {'igadgets': 0.012},
    ),
    NewsItem(
      title: 'Супермаркеты выигрывают от экономии покупателей',
      body:
          'Потребители чаще покупают базовые товары и меньше тратят на дорогие развлечения. FoodStyle расширяет полки с товарами первой необходимости.',
      impacts: {'foodstyle': 0.13, 'all_market': 0.08, 'igadgets': -0.04},
    ),
    NewsItem(
      title: 'Крипторынок обсуждает новые правила',
      body:
          'Регуляторы обещают навести порядок. Часть инвесторов выходит из CoinCrypto и VirtualCoin, часть ждёт нового роста после очистки рынка.',
      impacts: {
        'coin_crypto': -0.2,
        'virtual_coin': -0.26,
        'federal_bond': 0.025,
      },
      bankruptcyRisks: {'coin_crypto': 0.18, 'virtual_coin': 0.24},
    ),
    NewsItem(
      title: 'Федеральный банк получил госпрограмму',
      body:
          'Государство направит деньги через Федеральный банк. Доходность невысокая, зато рынок считает этот инструмент защитным в сложные годы.',
      impacts: {'federal_bond': 0.035, 'green_bond': 0.025},
    ),
    NewsItem(
      title: 'Зеленый банк резко наращивает выдачу кредитов',
      body:
          'Частный банк обещает быстрый рост портфеля. Аналитики спорят: это может поддержать доходность, но просрочки по новым клиентам способны испортить год.',
      impacts: {'green_bond': 0.08, 'safe_deposit': 0.035},
      bankruptcyRisks: {'green_bond': 0.045, 'safe_deposit': 0.025},
    ),
    NewsItem(
      title: 'Сеть «Мир игрушек» готовится к сезону подарков',
      body:
          'Компания заранее закупила популярные наборы и расширила онлайн-продажи. Если спрос подтвердится, облигации могут пройти год спокойнее.',
      impacts: {'toy_bond': 0.075, 'all_market': 0.025},
    ),
  ];

  static const List<EducationOffer> _education = [
    EducationOffer(
      id: 'courses',
      title: 'Курсы повышения квалификации',
      icon: Icons.groups_rounded,
      color: Color(0xFFE4BD57),
      cost: 159000,
      boostMin: 0.03,
      boostMax: 0.07,
    ),
    EducationOffer(
      id: 'exchange',
      title: 'Обмен опытом за границей',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF82C7E8),
      cost: 318000,
      boostMin: 0.07,
      boostMax: 0.13,
    ),
    EducationOffer(
      id: 'degree',
      title: 'Второе высшее образование',
      icon: Icons.school_rounded,
      color: Color(0xFF9B7ADD),
      cost: 636000,
      boostMin: 0.15,
      boostMax: 0.3,
    ),
    EducationOffer(
      id: 'mba',
      title: 'MBA',
      icon: Icons.business_center_rounded,
      color: Color(0xFFE57373),
      cost: 1060000,
      boostMin: 0.2,
      boostMax: 0.4,
    ),
  ];

  static const List<InsuranceOffer> _insurance = [
    InsuranceOffer(
      id: 'medical',
      title: 'ДМС',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFE76F72),
      cost: 10600,
      coverage: 250000,
    ),
    InsuranceOffer(
      id: 'car',
      title: 'КАСКО',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF78AEDD),
      cost: 21200,
      coverage: 300000,
    ),
    InsuranceOffer(
      id: 'flat',
      title: 'Квартира',
      icon: Icons.apartment_rounded,
      color: Color(0xFF8E77D8),
      cost: 31800,
      coverage: 350000,
    ),
  ];

  static const List<BankCardOffer> _cards = [
    BankCardOffer(
      id: 'credit_card',
      title: 'Кредитная карта',
      subtitle: '300 000 ₽ без процентов',
      cost: 2500,
      cashback: 0,
      colors: [Color(0xFFEAC455), Color(0xFFFF6B5C)],
    ),
    BankCardOffer(
      id: 'knowledge_card',
      title: 'Карта знаний',
      subtitle: '+5% кэшбэк на обучение',
      cost: 3800,
      cashback: 0.05,
      colors: [Color(0xFF72C59B), Color(0xFFD7F06C)],
    ),
    BankCardOffer(
      id: 'adventure_card',
      title: 'Карта приключений',
      subtitle: '+5% кэшбэк на радость',
      cost: 5000,
      cashback: 0.05,
      colors: [Color(0xFF7FA8EC), Color(0xFFE079E8)],
    ),
  ];

  static const List<CreditOffer> _creditOffers = [
    CreditOffer(
      id: 'green_credit',
      bank: 'Зеленый банк',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF72C59B),
      annualRate: 0.15,
      baseLimit: 620000,
      limitMultiplier: 2.4,
    ),
    CreditOffer(
      id: 'city_credit',
      bank: 'Городской банк',
      icon: Icons.apartment_rounded,
      color: Color(0xFF83B7E6),
      annualRate: 0.12,
      baseLimit: 430000,
      limitMultiplier: 1.8,
    ),
    CreditOffer(
      id: 'fast_credit',
      bank: 'Быстрые деньги',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFF9A4D),
      annualRate: 0.22,
      baseLimit: 900000,
      limitMultiplier: 3.1,
    ),
  ];

  static const List<LifeChoice> _lifeChoicePool = [
    LifeChoice(
      id: 'parents_europe',
      title: 'Выходные в Европе для родителей',
      body:
          'У ваших родителей в этом году большая годовщина. Вы думаете над тем, чтобы подарить им незабываемую поездку.',
      cost: 127200,
      acceptJoy: 8,
      declineJoy: -3,
    ),
    LifeChoice(
      id: 'crypto_mining',
      title: 'Майнинг криптовалют',
      body:
          'Вам попалась реклама пассивного дохода на криптовалюте. Можно арендовать оборудование для майнинга с высокой производительностью.',
      cost: 53000,
      acceptJoy: 3,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'furniture',
      title: 'Обновление мебели в квартире',
      body:
          'Старая мебель разваливается на части. Вы давно думаете пройтись по мебельным центрам и закрыть этот вопрос.',
      cost: 84800,
      acceptJoy: 0,
      declineJoy: -5,
    ),
    LifeChoice(
      id: 'wardrobe',
      title: 'Переделка чулана в гардеробную',
      body:
          'Вы разобрали хлам и поняли, что из маленького чулана получится удобная гардеробная комната.',
      cost: 63600,
      acceptJoy: 3,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'animal_shelter',
      title: 'Ежемесячная помощь приюту для животных',
      body:
          'Поездки в приют стали доброй семейной традицией. Можно оформить небольшой регулярный взнос.',
      cost: 8480,
      acceptJoy: 1,
      declineJoy: 0,
      annualExpenseDelta: 4240,
    ),
    LifeChoice(
      id: 'birthday',
      title: 'Большой праздник для близкого человека',
      body:
          'У важного для вас человека круглая дата. Можно устроить праздник, который запомнится всей семье.',
      cost: 74200,
      acceptJoy: 6,
      declineJoy: -2,
    ),
    LifeChoice(
      id: 'laptop_repair',
      title: 'Замена старого ноутбука',
      body:
          'Техника постоянно зависает и мешает работать. Новый ноутбук не увеличит доход напрямую, но снизит раздражение.',
      cost: 92000,
      acceptJoy: 2,
      declineJoy: -4,
    ),
    LifeChoice(
      id: 'health_check',
      title: 'Профилактический чек-ап',
      body:
          'Вы давно откладывали обследование. Сейчас можно пройти его спокойно, не дожидаясь проблем.',
      cost: 38800,
      acceptJoy: 2,
      declineJoy: -3,
    ),
    LifeChoice(
      id: 'family_trip',
      title: 'Поездка всей семьёй на выходные',
      body:
          'Год был напряжённым. Короткая поездка поможет восстановиться и провести время с близкими.',
      cost: 58600,
      acceptJoy: 5,
      declineJoy: -1,
    ),
    LifeChoice(
      id: 'old_friend_wedding',
      title: 'Свадьба старого друга',
      body:
          'Друг зовёт вас на свадьбу в другой город. Можно поехать, купить хороший подарок и провести выходные вне привычной рутины.',
      cost: 68400,
      acceptJoy: 5,
      declineJoy: -2,
    ),
    LifeChoice(
      id: 'home_workplace',
      title: 'Удобное рабочее место дома',
      body:
          'Спина устала от кухонного стула и ноутбука на коленях. Нормальный стол, кресло и свет сделают будни спокойнее.',
      cost: 112000,
      acceptJoy: 4,
      declineJoy: -4,
    ),
    LifeChoice(
      id: 'concert_ticket',
      title: 'Концерт любимой группы',
      body:
          'Билеты почти распроданы, а вы давно хотели сходить на живой концерт. Это не инвестиция, но отличный способ перезагрузиться.',
      cost: 28600,
      acceptJoy: 4,
      declineJoy: -1,
    ),
    LifeChoice(
      id: 'sport_membership',
      title: 'Годовой абонемент в спортзал',
      body:
          'Вы замечаете, что энергии стало меньше. Абонемент поможет держать режим, но добавит регулярную статью расходов.',
      cost: 44800,
      acceptJoy: 3,
      declineJoy: -2,
      annualExpenseDelta: 12000,
    ),
    LifeChoice(
      id: 'dental_treatment',
      title: 'Лечение зубов без откладывания',
      body:
          'Стоматолог предупредил: если заняться сейчас, будет дешевле и спокойнее. Если тянуть, настроение точно просядет.',
      cost: 76400,
      acceptJoy: 1,
      declineJoy: -6,
    ),
    LifeChoice(
      id: 'parents_repair',
      title: 'Помощь родителям с ремонтом',
      body:
          'У родителей давно протекает ванная. Можно помочь деньгами и закрыть проблему до больших последствий.',
      cost: 139000,
      acceptJoy: 6,
      declineJoy: -4,
    ),
    LifeChoice(
      id: 'language_trip',
      title: 'Языковой интенсив на неделю',
      body:
          'Вам предлагают короткий интенсив с практикой общения. Это не полноценное образование, но уверенности прибавит.',
      cost: 58400,
      acceptJoy: 4,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'phone_upgrade',
      title: 'Новый телефон вместо уставшего',
      body:
          'Старый телефон быстро садится и зависает в самый неподходящий момент. Можно обновиться сейчас или потерпеть ещё год.',
      cost: 94200,
      acceptJoy: 3,
      declineJoy: -3,
    ),
    LifeChoice(
      id: 'week_without_work',
      title: 'Неделя отпуска без ноутбука',
      body:
          'Вы чувствуете, что работаете на автопилоте. Спонтанный отпуск поможет восстановиться, но часть бюджета придётся отдать отдыху.',
      cost: 118000,
      acceptJoy: 8,
      declineJoy: -5,
    ),
    LifeChoice(
      id: 'kitchen_appliances',
      title: 'Обновление техники на кухне',
      body:
          'Холодильник шумит, чайник течёт, а плита живёт своей жизнью. Можно купить комплект новой техники и снизить бытовой стресс.',
      cost: 156000,
      acceptJoy: 4,
      declineJoy: -5,
    ),
    LifeChoice(
      id: 'charity_subscription',
      title: 'Регулярная благотворительная подписка',
      body:
          'Вы нашли фонд с прозрачными отчётами. Небольшой регулярный взнос не сделает вас богаче, но добавит ощущение смысла.',
      cost: 12000,
      acceptJoy: 2,
      declineJoy: 0,
      annualExpenseDelta: 9000,
    ),
    LifeChoice(
      id: 'city_marathon',
      title: 'Подготовка к городскому забегу',
      body:
          'Коллеги собирают команду на забег. Нужны экипировка и стартовый взнос, зато будет цель и приятное чувство победы над собой.',
      cost: 23200,
      acceptJoy: 3,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'online_course_for_fun',
      title: 'Творческий курс для себя',
      body:
          'Вы давно хотели попробовать фотографию, музыку или дизайн без давления результата. Курс не поднимет зарплату, но оживит неделю.',
      cost: 37600,
      acceptJoy: 5,
      declineJoy: -1,
    ),
    LifeChoice(
      id: 'car_tires',
      title: 'Новые шины перед зимой',
      body:
          'Старые шины ещё крутятся, но уже не внушают доверия. Можно заменить их сейчас и ездить спокойнее.',
      cost: 52400,
      acceptJoy: 1,
      declineJoy: -4,
    ),
    LifeChoice(
      id: 'quiet_weekend_hotel',
      title: 'Тихие выходные в хорошем отеле',
      body:
          'Вы нашли предложение на два дня без дел, звонков и ремонта за стеной. Иногда тишина стоит денег.',
      cost: 69200,
      acceptJoy: 6,
      declineJoy: -2,
    ),
    LifeChoice(
      id: 'family_photo_day',
      title: 'Семейная фотосъёмка',
      body:
          'Все давно собирались сделать нормальные фотографии, но каждый год откладывали. Можно наконец организовать день для памяти.',
      cost: 33400,
      acceptJoy: 3,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'moving_closer_to_work',
      title: 'Переезд ближе к работе',
      body:
          'Дорога съедает часы каждую неделю. Переезд потребует затрат сейчас и чуть увеличит ежегодные расходы, зато жизнь станет спокойнее.',
      cost: 184000,
      acceptJoy: 7,
      declineJoy: -4,
      annualExpenseDelta: 36000,
    ),
    LifeChoice(
      id: 'medical_subscription',
      title: 'Годовая медицинская программа',
      body:
          'Клиника предлагает программу наблюдения на год. Это дорого, но снижает тревогу и помогает не запускать здоровье.',
      cost: 98000,
      acceptJoy: 4,
      declineJoy: -3,
      annualExpenseDelta: 18000,
    ),
    LifeChoice(
      id: 'repair_bathroom',
      title: 'Ремонт ванной комнаты',
      body:
          'Плитка треснула, смеситель капает, а шкафчик держится на честном слове. Можно сделать ремонт сейчас или снова привыкать.',
      cost: 221000,
      acceptJoy: 5,
      declineJoy: -6,
    ),
    LifeChoice(
      id: 'hobby_equipment',
      title: 'Оборудование для хобби',
      body:
          'Ваше хобби давно просит нормальные инструменты. Покупка не обязательна, но заметно добавит удовольствия от свободного времени.',
      cost: 47600,
      acceptJoy: 4,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'gift_for_child',
      title: 'Дорогой подарок ребёнку',
      body:
          'Ребёнок мечтает о подарке уже несколько месяцев. Можно исполнить мечту, но бюджет почувствует этот жест.',
      cost: 72800,
      acceptJoy: 5,
      declineJoy: -3,
    ),
    LifeChoice(
      id: 'premium_vacation',
      title: 'Отпуск мечты у моря',
      body:
          'Появился шанс взять красивую поездку по хорошей цене. Это ощутимый удар по деньгам, зато мощная прибавка к радости.',
      cost: 246000,
      acceptJoy: 12,
      declineJoy: -4,
    ),
    LifeChoice(
      id: 'repair_neighbors_damage',
      title: 'Компенсация соседям за протечку',
      body:
          'У вас сорвало гибкую подводку, и вода ушла к соседям. Можно быстро компенсировать ущерб и не превращать год в конфликт.',
      cost: 116000,
      acceptJoy: 0,
      declineJoy: -7,
    ),
    LifeChoice(
      id: 'psychologist_sessions',
      title: 'Несколько встреч с психологом',
      body:
          'Накопилось много напряжения. Серия консультаций не решит финансы напрямую, но поможет принимать решения спокойнее.',
      cost: 54000,
      acceptJoy: 5,
      declineJoy: -2,
    ),
    LifeChoice(
      id: 'home_security',
      title: 'Система безопасности дома',
      body:
          'После неприятной новости в районе вы задумались о датчиках, замке и камере. Спокойствие тоже иногда покупается.',
      cost: 64400,
      acceptJoy: 2,
      declineJoy: -2,
      annualExpenseDelta: 6000,
    ),
    LifeChoice(
      id: 'winter_clothes',
      title: 'Нормальная зимняя одежда',
      body:
          'Старые вещи уже не спасают от холода. Можно купить качественный комплект и перестать каждое утро спорить с погодой.',
      cost: 48800,
      acceptJoy: 3,
      declineJoy: -4,
    ),
    LifeChoice(
      id: 'subscription_bundle',
      title: 'Пакет подписок для дома',
      body:
          'Музыка, кино, облако и сервисы для семьи можно объединить в один пакет. Удобно, но каждый год это будет отдельная строка.',
      cost: 9600,
      acceptJoy: 2,
      declineJoy: 0,
      annualExpenseDelta: 14400,
    ),
    LifeChoice(
      id: 'legal_consultation',
      title: 'Юридическая консультация по документам',
      body:
          'В старых договорах и наследственных бумагах накопилась путаница. Можно разобраться сейчас и снять фоновую тревогу.',
      cost: 42600,
      acceptJoy: 2,
      declineJoy: -2,
    ),
    LifeChoice(
      id: 'new_mattress',
      title: 'Хороший матрас вместо старого',
      body:
          'Сон стал хуже, а утро начинается с усталости. Новый матрас не выглядит яркой покупкой, но влияет на каждый день.',
      cost: 67200,
      acceptJoy: 5,
      declineJoy: -4,
    ),
    LifeChoice(
      id: 'small_business_friend',
      title: 'Поддержать проект друга',
      body:
          'Друг запускает небольшое дело и просит помочь предзаказом. Это не инвестиция в портфель, а скорее поддержка отношений.',
      cost: 35000,
      acceptJoy: 3,
      declineJoy: -1,
    ),
    LifeChoice(
      id: 'city_festival',
      title: 'Большой городской фестиваль',
      body:
          'В городе редкое событие с лекциями, музыкой и едой. Можно сходить на весь день и получить заряд впечатлений.',
      cost: 18400,
      acceptJoy: 3,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'emergency_savings_box',
      title: 'Домашний аварийный набор',
      body:
          'Вы решили собрать аптечку, запасные аккумуляторы, инструменты и базовые вещи на случай внезапных проблем.',
      cost: 29400,
      acceptJoy: 1,
      declineJoy: -1,
    ),
    LifeChoice(
      id: 'relative_education_help',
      title: 'Помочь родственнику с учёбой',
      body:
          'Младший родственник поступил на курсы, но семье не хватает денег. Можно поддержать его старт.',
      cost: 88000,
      acceptJoy: 6,
      declineJoy: -2,
    ),
    LifeChoice(
      id: 'home_internet_upgrade',
      title: 'Быстрый интернет для дома',
      body:
          'Связь постоянно проседает на созвонах и фильмах. Новый тариф дороже, зато меньше раздражения каждый месяц.',
      cost: 6000,
      acceptJoy: 2,
      declineJoy: -1,
      annualExpenseDelta: 9600,
    ),
    LifeChoice(
      id: 'wardrobe_refresh',
      title: 'Обновить базовый гардероб',
      body:
          'Одежда выглядит уставшей, а важные встречи стали случаться чаще. Можно собрать аккуратный базовый набор.',
      cost: 78600,
      acceptJoy: 4,
      declineJoy: -2,
    ),
    LifeChoice(
      id: 'parents_health_resort',
      title: 'Санаторий для родителей',
      body:
          'Врач посоветовал родителям спокойное восстановление. Путёвка стоит дорого, но семья давно об этом говорила.',
      cost: 168000,
      acceptJoy: 8,
      declineJoy: -3,
    ),
    LifeChoice(
      id: 'streaming_year',
      title: 'Годовая подписка на кино и музыку',
      body:
          'Домашние вечера стали однообразными. Можно оплатить общий пакет развлечений на год: фильмов больше, но финансового смысла в этом нет.',
      cost: 14900,
      acceptJoy: 3,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'cloud_backup',
      title: 'Облако для семейных фотографий',
      body:
          'Телефон постоянно напоминает, что память закончилась. Подписка на облако сохранит фотографии и уберёт мелкое раздражение.',
      cost: 7900,
      acceptJoy: 1,
      declineJoy: -1,
    ),
    LifeChoice(
      id: 'cleaning_subscription',
      title: 'Подписка на уборку квартиры',
      body:
          'После работы всё меньше сил на быт. Можно оформить регулярную уборку: дома станет спокойнее, но расходы будут повторяться каждый год.',
      cost: 18000,
      acceptJoy: 4,
      declineJoy: -2,
      annualExpenseDelta: 24000,
    ),
    LifeChoice(
      id: 'coffee_machine',
      title: 'Кофемашина для дома',
      body:
          'Утренний кофе из ближайшей точки стал слишком дорогой привычкой. Кофемашина дома порадует сейчас, но капсулы добавят небольшие постоянные расходы.',
      cost: 38200,
      acceptJoy: 2,
      declineJoy: 0,
      annualExpenseDelta: 7200,
    ),
    LifeChoice(
      id: 'theater_pass',
      title: 'Абонемент в театр на год',
      body:
          'Друзья зовут чаще выходить из дома и предлагают купить абонемент на несколько спектаклей. Это не инвестиция, но хороший повод не жить одной работой.',
      cost: 46000,
      acceptJoy: 5,
      declineJoy: -1,
    ),
    LifeChoice(
      id: 'board_game_evenings',
      title: 'Набор настольных игр',
      body:
          'Появилась идея собирать близких без больших трат на кафе. Набор игр стоит умеренно и может сделать вечера живее.',
      cost: 15800,
      acceptJoy: 2,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'noise_canceling_headphones',
      title: 'Наушники с шумоподавлением',
      body:
          'Дорога, соседи и офисный шум всё чаще утомляют. Хорошие наушники не принесут денег, зато помогут выдыхать в течение дня.',
      cost: 41900,
      acceptJoy: 3,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'finance_app_premium',
      title: 'Премиум-приложение для бюджета',
      body:
          'Сервис обещает красивые отчёты, категории и напоминания. Можно попробовать на год, но это скорее удобство, чем гарантированная польза.',
      cost: 6900,
      acceptJoy: 1,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'cooking_masterclass',
      title: 'Кулинарный мастер-класс',
      body:
          'В городе проводят вечерний мастер-класс с ужином. Это разовая трата ради впечатления и нового навыка без влияния на зарплату.',
      cost: 23800,
      acceptJoy: 3,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'city_bicycle',
      title: 'Городской велосипед',
      body:
          'Короткие поездки по району можно делать без такси и пробок. Покупка дороговата, но добавит свободы и движения.',
      cost: 72000,
      acceptJoy: 4,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'smart_lamp',
      title: 'Умная лампа с красивым светом',
      body:
          'В магазине попалась лампа, которая меняет цвет и выглядит уютно. Приятная вещь, но на радость и деньги почти не влияет.',
      cost: 9900,
      acceptJoy: 0,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'game_console',
      title: 'Игровая приставка',
      body:
          'Давно хотелось купить приставку и пару игр для вечеров. Это чистое удовольствие: деньги уйдут, зато отдых станет разнообразнее.',
      cost: 65000,
      acceptJoy: 4,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'home_plants',
      title: 'Зелёный уголок дома',
      body:
          'Квартира выглядит слишком пустой. Небольшой домашний уголок с растениями сделает пространство спокойнее и приятнее.',
      cost: 14200,
      acceptJoy: 2,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'collectible_shelf_item',
      title: 'Коллекционная вещь на полку',
      body:
          'Вы увидели красивую коллекционную вещь, которую давно хотели. Она не даст радости по шкале игры, но иногда хочется купить просто потому что нравится.',
      cost: 14500,
      acceptJoy: 0,
      declineJoy: 0,
    ),
    LifeChoice(
      id: 'massage_course',
      title: 'Курс массажа после тяжёлого года',
      body:
          'Спина и плечи напоминают, что стресс тоже копится. Несколько сеансов помогут восстановиться, хотя это заметная разовая трата.',
      cost: 51000,
      acceptJoy: 4,
      declineJoy: -1,
    ),
  ];

  final Random _random = Random();
  final Map<String, double> _holdings = {
    for (final item in _allInstruments) item.id: 0,
  };
  final Map<String, int> _depositTerms = {};
  final Map<String, int> _depositInitialTerms = {};
  final Map<String, double> _depositRates = {};
  final Set<String> _completedEducation = {};
  final Set<String> _activeInsurance = {};
  final Set<String> _issuedCards = {};
  final Set<String> _usedLifeChoiceIds = {};
  final Set<String> _bankruptInstruments = {};
  final List<String> _yearLog = [];

  late List<NewsItem> _yearNews;
  late List<LifeChoice> _lifeChoices;
  GameTab _tab = GameTab.budget;
  InstrumentCategory _category = InstrumentCategory.stocks;
  int _year = 1;
  int _lifeChoiceIndex = 0;
  int _selectedCreditYears = 1;
  int _joy = 70;
  double _cash = 0;
  double _salary = 0;
  double _inflation = 0.06;
  double _baseMandatoryExpense = 300000;
  double _recurringAnnualExpenses = 0;
  double _priceIndex = 1;
  double _selectedCreditAmount = 0;
  String _selectedCreditOfferId = 'green_credit';
  bool _mandatoryPaid = false;
  bool _finished = false;
  CreditState? _credit;
  CardDebtState? _cardDebt;

  @override
  void initState() {
    super.initState();
    _cash = widget.difficulty.startCash;
    _salary = widget.difficulty.startSalary;
    _yearNews = _generateNewsPack();
    _lifeChoices = _generateLifeChoices();
    _selectedCreditYears = widget.difficulty.hasCredit ? 2 : 1;
    _selectedCreditAmount = widget.difficulty.hasCredit
        ? min(150000.0, _creditLimit(_selectedCreditOffer))
        : 0;
    if (!widget.difficulty.hasCrypto) {
      _category = InstrumentCategory.stocks;
    }
  }

  int get _totalYears => widget.difficulty.years;
  double get _portfolioValue =>
      _holdings.values.fold(0, (sum, value) => sum + value);
  double get _netWorth =>
      _cash +
      _portfolioValue -
      (_credit?.amount ?? 0) -
      (_cardDebt?.amount ?? 0);
  double get _mandatoryExpense =>
      (_baseMandatoryExpense + _recurringAnnualExpenses) * _priceIndex;
  bool get _lifeChoicesDone => _lifeChoiceIndex >= _lifeChoices.length;
  LifeChoice? get _currentLifeChoice =>
      _lifeChoicesDone ? null : _lifeChoices[_lifeChoiceIndex];
  CreditOffer get _selectedCreditOffer => _creditOffers.firstWhere(
    (offer) => offer.id == _selectedCreditOfferId,
    orElse: () => _creditOffers.first,
  );
  int get _maxCreditYears {
    if (!widget.difficulty.hasCredit) {
      return 1;
    }
    final difficultyMax = switch (widget.difficulty) {
      GameDifficulty.easy => 1,
      GameDifficulty.medium => 3,
      GameDifficulty.hard => 5,
    };
    return min(difficultyMax, _totalYears - _year + 1).clamp(1, 5).toInt();
  }

  List<MarketInstrument> get _availableInstruments {
    return _allInstruments.where((instrument) {
      if (instrument.category == InstrumentCategory.crypto &&
          !widget.difficulty.hasCrypto) {
        return false;
      }
      if (instrument.category == InstrumentCategory.other &&
          widget.difficulty == GameDifficulty.easy) {
        return false;
      }
      return true;
    }).toList();
  }

  double _creditLimit(CreditOffer offer) {
    return min(offer.baseLimit, _salary * offer.limitMultiplier);
  }

  double _inflatedCost(double baseCost) => baseCost * _priceIndex;
  double _educationCost(EducationOffer item) => _inflatedCost(item.cost);
  double _insuranceCost(InsuranceOffer item) => _inflatedCost(item.cost);
  double _cardCost(BankCardOffer item) => _inflatedCost(item.cost);

  double _creditPayment(CreditOffer offer, double amount, int years) {
    return amount * (1 + offer.annualRate * years) / years;
  }

  void _normalizeCreditSelection() {
    final offer = _selectedCreditOffer;
    final maxYears = _maxCreditYears;
    _selectedCreditYears = _selectedCreditYears.clamp(1, maxYears).toInt();
    final limit = _creditLimit(offer);
    if (_selectedCreditAmount <= 0) {
      _selectedCreditAmount = min(150000.0, limit);
    }
    _selectedCreditAmount = _selectedCreditAmount
        .clamp(50000.0, limit)
        .toDouble();
  }

  void _selectCreditOffer(String id) {
    setState(() {
      _selectedCreditOfferId = id;
      _normalizeCreditSelection();
    });
  }

  void _selectCreditAmount(double amount) {
    setState(() {
      _selectedCreditAmount = amount;
      _normalizeCreditSelection();
    });
  }

  void _selectCreditYears(int years) {
    setState(() {
      _selectedCreditYears = years;
      _normalizeCreditSelection();
    });
  }

  List<NewsItem> _generateNewsPack() {
    final news = <NewsItem>[
      _newsPool[_random.nextInt(_newsPool.length)],
      _generateMacroNews(),
    ];
    final companies = [..._availableInstruments]..shuffle(_random);
    final companyNewsCount = widget.difficulty == GameDifficulty.easy ? 2 : 3;
    for (final instrument in companies.take(companyNewsCount)) {
      news.add(_generateCompanyNews(instrument));
    }
    return news;
  }

  NewsItem _generateMacroNews() {
    switch (_random.nextInt(5)) {
      case 0:
        return const NewsItem(
          title: 'Банки меняют ставки по продуктам',
          body:
              'После заседания регулятора вклады стали немного привлекательнее. Рискованные активы временно получают меньше внимания инвесторов, а частные банки проходят проверку на прочность.',
          impacts: {
            'western_deposit': 0.025,
            'safe_deposit': 0.02,
            'coin_crypto': -0.08,
            'virtual_coin': -0.1,
            'fortuna': -0.06,
          },
          bankruptcyRisks: {
            'green_bond': 0.02,
            'western_deposit': 0.015,
            'coin_crypto': 0.06,
            'virtual_coin': 0.08,
          },
        );
      case 1:
        return const NewsItem(
          title: 'Покупатели активнее тратят деньги',
          body:
              'Розничные сети и сервисы доставки сообщают о росте спроса. Компании повседневного потребления могут показать сильный год.',
          impacts: {
            'all_market': 0.09,
            'foodstyle': 0.11,
            'toy_bond': 0.035,
            'igadgets': 0.025,
          },
        );
      case 2:
        return const NewsItem(
          title: 'Инвесторы уходят в защитные активы',
          body:
              'На фоне неопределённости участники рынка выбирают облигации и вклады. Акции роста и альтернативные проекты становятся волатильнее.',
          impacts: {
            'green_bond': 0.05,
            'federal_bond': 0.045,
            'western_deposit': 0.018,
            'spacecar': -0.055,
            'fortuna': -0.08,
          },
        );
      case 3:
        return const NewsItem(
          title: 'Государство поддержит инфраструктуру',
          body:
              'Новые программы финансирования помогают городским и зелёным проектам. Компании, связанные с транспортом и строительством, получают шанс на рост.',
          impacts: {
            'city_project': 0.1,
            'green_bond': 0.07,
            'buildaero': 0.055,
            'federal_bond': 0.025,
          },
        );
      default:
        return const NewsItem(
          title: 'Рынок спорит о будущем цифровых активов',
          body:
              'Одни аналитики ждут нового роста криптовалют, другие предупреждают о резких просадках. Решения в этом секторе становятся особенно рискованными.',
          impacts: {
            'coin_crypto': 0.1,
            'virtual_coin': 0.14,
            'safe_deposit': 0.01,
          },
        );
    }
  }

  NewsItem _generateCompanyNews(MarketInstrument instrument) {
    final positive = _random.nextBool();
    final critical =
        !positive && _random.nextDouble() < 0.18 + instrument.risk * 0.7;
    final impactBase =
        0.045 + instrument.risk * 0.38 + _random.nextDouble() * 0.055;
    final impact = positive
        ? impactBase
        : critical
        ? -(0.16 + instrument.risk * 0.62 + _random.nextDouble() * 0.12)
        : -impactBase;
    final title = positive
        ? '${instrument.name} улучшает прогнозы'
        : critical
        ? '${instrument.name}: тревожный сигнал'
        : '${instrument.name} столкнулась с проблемами';
    final body = positive
        ? _positiveCompanyBody(instrument)
        : critical
        ? _criticalCompanyBody(instrument)
        : _negativeCompanyBody(instrument);
    final bankruptcyRisks =
        critical &&
            (instrument.category == InstrumentCategory.crypto ||
                !_bankruptcyProtected(instrument))
        ? <String, double>{
            instrument.id: (0.12 + instrument.risk * 0.65)
                .clamp(0.08, 0.55)
                .toDouble(),
          }
        : const <String, double>{};
    return NewsItem(
      title: title,
      body: body,
      impacts: {instrument.id: impact},
      bankruptcyRisks: bankruptcyRisks,
    );
  }

  String _positiveCompanyBody(MarketInstrument instrument) {
    final specific = switch (instrument.id) {
      'all_market' =>
        'All-Market расширяет пункты выдачи и ускоряет доставку. Если покупатели продолжат заказывать чаще, маркетплейс может показать год лучше рынка.',
      'spacecar' =>
        'SpaceCar получила предварительный интерес к научным запускам. Успешный испытательный год способен резко поднять оценку компании.',
      'igadgets' =>
        'iGadgets удачно представила новую линейку смартфонов. Предзаказы выглядят сильными, но всё ещё важны поставки комплектующих.',
      'foodstyle' =>
        'FoodStyle открывает новые супермаркеты в районах с высоким трафиком. Стабильный спрос на продукты может поддержать прибыль.',
      'green_bond' || 'safe_deposit' =>
        'Зеленый банк отчитывается о росте клиентов. Частный банк выглядит бодро, но его устойчивость всё равно зависит от качества выданных кредитов.',
      'federal_bond' =>
        'Федеральный банк получил поддержку госпрограммы. Доходность остаётся спокойной, зато риск банкротства для него отсутствует.',
      'toy_bond' =>
        'Мир игрушек заранее закупил популярные товары. Сильный сезон подарков может улучшить обслуживание долга.',
      'western_deposit' =>
        'Западный поднимает ставки по вкладам, чтобы привлечь клиентов. Доходность может стать выше, но банк остаётся частным.',
      'coin_crypto' =>
        'CoinCrypto снова обсуждают крупные игроки. Спрос может быстро поднять цену, но сектор остаётся крайне нервным.',
      'virtual_coin' =>
        'VirtualCoin набирает популярность в сообществе. Рост может быть резким, но такая же резкой бывает и просадка.',
      _ => null,
    };
    if (specific != null) {
      return specific;
    }
    return switch (instrument.category) {
      InstrumentCategory.stocks =>
        '${instrument.name} сообщает о росте продаж и новых клиентах. Если планы подтвердятся, стоимость акций может вырасти быстрее рынка.',
      InstrumentCategory.bonds =>
        '${instrument.name} улучшает финансовые показатели. Для держателей облигаций это снижает риск и поддерживает цену бумаг.',
      InstrumentCategory.deposits =>
        '${instrument.name} предлагает более выгодные условия по вкладам. Доходность депозитов в этом банке может стать выше.',
      InstrumentCategory.crypto =>
        '${instrument.name} привлекает внимание сообщества и крупных игроков. Спрос может резко поднять цену, но риск остаётся высоким.',
      InstrumentCategory.other =>
        '${instrument.name} объявляет о сильных результатах проекта. Альтернативные инвестиции получают шанс на высокий доход.',
    };
  }

  String _negativeCompanyBody(MarketInstrument instrument) {
    final specific = switch (instrument.id) {
      'all_market' =>
        'Партнёры All-Market жалуются на комиссии и задержки выплат. Если конфликт затянется, рост оборота может не превратиться в прибыль.',
      'spacecar' =>
        'SpaceCar переносит часть испытаний из-за технических замечаний. Для космических проектов даже небольшая задержка может дорого стоить.',
      'igadgets' =>
        'iGadgets сообщает о задержках поставок смартфонов. Бренд остаётся популярным, но продажи этого года могут оказаться слабее.',
      'foodstyle' =>
        'FoodStyle сталкивается с ростом закупочных цен. Супермаркеты устойчивы, но маржа может стать тоньше.',
      'green_bond' || 'safe_deposit' =>
        'Зеленый банк увеличивает резервы под проблемные кредиты. Это не приговор, но частный банк выглядит менее спокойно.',
      'federal_bond' =>
        'Федеральный банк снижает прогноз доходности. Инструмент остаётся стабильным и не несёт риска банкротства.',
      'toy_bond' =>
        'Мир игрушек недосчитался поставок к сезону. Купон остаётся, но инвесторы могут осторожнее оценить компанию.',
      'western_deposit' =>
        'Западный тратит больше на привлечение вкладчиков. Доходность выглядит интересно, но запас прочности у частного банка важен.',
      'coin_crypto' =>
        'CoinCrypto попала под волну продаж. Монета может восстановиться, но сильная просадка в этом году вполне возможна.',
      'virtual_coin' =>
        'VirtualCoin теряет активность после слухов о крупной распродаже. Движение может быть резким в любую сторону.',
      _ => null,
    };
    if (specific != null) {
      return specific;
    }
    return switch (instrument.category) {
      InstrumentCategory.stocks =>
        '${instrument.name} предупреждает о снижении спроса и росте расходов. Акции компании могут оказаться слабее рынка.',
      InstrumentCategory.bonds =>
        '${instrument.name} столкнулась с ростом долговой нагрузки. Купоны остаются, но инвесторы требуют большую премию за риск.',
      InstrumentCategory.deposits =>
        '${instrument.name} снижает привлекательность вкладов из-за расходов на обслуживание. Доходность может оказаться ниже ожиданий.',
      InstrumentCategory.crypto =>
        '${instrument.name} попала под волну продаж после слухов о регулировании. Цена может резко просесть.',
      InstrumentCategory.other =>
        '${instrument.name} задерживает запуск проекта. Обещанная высокая доходность становится менее надёжной.',
    };
  }

  String _criticalCompanyBody(MarketInstrument instrument) {
    final specific = switch (instrument.id) {
      'all_market' =>
        'У All-Market всплыли вопросы к расчётам с поставщиками. В новости нет прямого вывода, но такой сигнал обычно заставляет рынок готовиться к плохому сценарию.',
      'spacecar' =>
        'SpaceCar закрыла доступ журналистов к испытательному стенду после аварийной остановки. Если проблема системная, стоимость компании может резко обнулиться.',
      'igadgets' =>
        'iGadgets срочно проверяет партию устройств после жалоб покупателей. Бренд сильный, но отзыв партии способен ударить очень больно.',
      'foodstyle' =>
        'FoodStyle спорит с арендодателями и поставщиками сразу в нескольких регионах. Для супермаркетов это редкая, но серьёзная тревога.',
      'green_bond' || 'safe_deposit' =>
        'Зеленый банк отложил публикацию отчёта и ограничил крупные операции. Официально всё под контролем, но частный банк стал заметно рискованнее.',
      'toy_bond' =>
        'Мир игрушек просит поставщиков о переносе платежей. Формально это ещё не дефолт, но держателям бумаг стоит быть осторожнее.',
      'western_deposit' =>
        'Западный столкнулся с резким оттоком вкладчиков. Банк ищет ликвидность, и год может закончиться неприятно.',
      'coin_crypto' =>
        'CoinCrypto приостановила часть операций после сбоя в инфраструктуре. Если доверие не восстановится, монета может сильно просесть.',
      'virtual_coin' =>
        'У VirtualCoin исчезла активность ключевых разработчиков. Сообщество спорит, временная ли это пауза или начало большого обвала.',
      _ => null,
    };
    if (specific != null) {
      return specific;
    }
    return switch (instrument.category) {
      InstrumentCategory.stocks =>
        '${instrument.name} задерживает отчёт и не отвечает на вопросы инвесторов. Прямого банкротства никто не объявил, но риск стал намного выше.',
      InstrumentCategory.bonds =>
        '${instrument.name} ведёт переговоры о переносе платежей. Купон может сохраниться, но риск дефолта заметно вырос.',
      InstrumentCategory.deposits =>
        '${instrument.name} ограничивает часть операций. Вклады выглядят менее спокойно, чем в начале года.',
      InstrumentCategory.crypto =>
        '${instrument.name} переживает технический и репутационный сбой. Цена может резко провалиться.',
      InstrumentCategory.other =>
        '${instrument.name} потерял ключевого партнёра. Высокая доходность теперь сопровождается риском обнуления.',
    };
  }

  double _newsImpactFor(String instrumentId) {
    final total = _yearNews.fold<double>(
      0,
      (sum, news) => sum + (news.impacts[instrumentId] ?? 0),
    );
    return total.clamp(-0.35, 0.35).toDouble();
  }

  double _newsBankruptcyRiskFor(String instrumentId) {
    final total = _yearNews.fold<double>(
      0,
      (sum, news) => sum + (news.bankruptcyRisks[instrumentId] ?? 0),
    );
    return total.clamp(0, 0.7).toDouble();
  }

  bool _bankruptcyProtected(MarketInstrument item) {
    return item.id == 'federal_bond' ||
        item.id == 'green_bond' ||
        item.id == 'safe_deposit';
  }

  bool _isBankrupt(MarketInstrument item) {
    return _bankruptInstruments.contains(item.id);
  }

  double _collapseRiskFor(MarketInstrument item) {
    if (item.category == InstrumentCategory.crypto) {
      final newsImpact = _newsImpactFor(item.id);
      final explicitRisk = _newsBankruptcyRiskFor(item.id);
      if (explicitRisk <= 0 && newsImpact > -0.08) {
        return 0;
      }
      final newsPanic = newsImpact <= -0.24
          ? 0.48
          : newsImpact <= -0.16
          ? 0.34
          : newsImpact <= -0.08
          ? 0.2
          : 0.0;
      return (explicitRisk + newsPanic).clamp(0, 0.9).toDouble();
    }
    if (_bankruptcyProtected(item) || _isBankrupt(item)) {
      return 0;
    }
    final newsImpact = _newsImpactFor(item.id);
    final explicitRisk = _newsBankruptcyRiskFor(item.id);
    if (explicitRisk <= 0 && newsImpact > -0.08) {
      return 0;
    }
    final badNewsRisk = newsImpact <= -0.24
        ? 0.22
        : newsImpact <= -0.16
        ? 0.14
        : newsImpact <= -0.08
        ? 0.07
        : 0.0;
    final categoryRisk = switch (item.category) {
      InstrumentCategory.bonds => item.risk * 0.04,
      InstrumentCategory.deposits => item.risk * 0.03,
      InstrumentCategory.stocks => item.risk * 0.08,
      InstrumentCategory.other => item.risk * 0.1,
      InstrumentCategory.crypto => 0.0,
    };
    return (explicitRisk + badNewsRisk + categoryRisk)
        .clamp(0, 0.72)
        .toDouble();
  }

  List<LifeChoice> _generateLifeChoices() {
    const count = 4;
    var choices = _lifeChoicePool
        .where((choice) => !_usedLifeChoiceIds.contains(choice.id))
        .toList();
    if (choices.length < count) {
      _usedLifeChoiceIds.clear();
      choices = [..._lifeChoicePool];
    }
    choices.shuffle(_random);
    final selected = choices.take(count).toList();
    _usedLifeChoiceIds.addAll(selected.map((choice) => choice.id));
    return selected;
  }

  double _lifeChoiceCost(LifeChoice choice) {
    return _inflatedCost(choice.cost);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _payMandatory() {
    if (_mandatoryPaid) {
      _message('Обязательные расходы уже оплачены.');
      return;
    }
    if (_cash < _mandatoryExpense) {
      _message(
        'Не хватает ${_money(_mandatoryExpense - _cash)} на обязательные расходы.',
      );
      return;
    }
    setState(() {
      _cash -= _mandatoryExpense;
      _mandatoryPaid = true;
      _yearLog.insert(
        0,
        'Оплачены обязательные расходы: ${_money(_mandatoryExpense)}.',
      );
    });
  }

  void _buyEducation(EducationOffer item) {
    if (_completedEducation.contains(item.id)) {
      _message('Это обучение уже оплачено.');
      return;
    }
    final cost = _educationCost(item);
    if (_cash < cost) {
      _message('Не хватает ${_money(cost - _cash)}.');
      return;
    }
    final boost =
        item.boostMin + _random.nextDouble() * (item.boostMax - item.boostMin);
    final joyGain = _scaledJoyGain(3);
    setState(() {
      _cash -= cost;
      _salary *= 1 + boost;
      _completedEducation.add(item.id);
      _joy = min(100, _joy + joyGain);
      _yearLog.insert(
        0,
        '${item.title}: зарплата +${_percent(boost)}, радость +$joyGain.',
      );
    });
  }

  void _buyInsurance(InsuranceOffer item) {
    if (_activeInsurance.contains(item.id)) {
      _message('${item.title} уже действует до конца текущего года.');
      return;
    }
    final cost = _insuranceCost(item);
    if (_cash < cost) {
      _message('Не хватает ${_money(cost - _cash)}.');
      return;
    }
    setState(() {
      _cash -= cost;
      _activeInsurance.add(item.id);
      _yearLog.insert(0, 'Оформлена страховка ${item.title}.');
    });
  }

  void _issueCard(BankCardOffer item) {
    if (_issuedCards.contains(item.id)) {
      _message('${item.title} уже выпущена.');
      return;
    }
    final cost = _cardCost(item);
    if (_cash < cost) {
      _message('Не хватает ${_money(cost - _cash)}.');
      return;
    }
    setState(() {
      _cash -= cost;
      _issuedCards.add(item.id);
      if (item.id == 'credit_card') {
        const cardLimit = 300000.0;
        final years = min(5, _totalYears - _year + 1);
        _cash += cardLimit;
        _cardDebt = CardDebtState(
          amount: cardLimit,
          yearsLeft: years,
          payment: cardLimit / years,
        );
        _yearLog.insert(
          0,
          'Кредитная карта: +${_money(cardLimit)} на баланс, без процентов. Ежегодное списание ${_money(cardLimit / years)}.',
        );
      } else {
        _yearLog.insert(0, 'Выпущена карта "${item.title}".');
      }
    });
  }

  void _acceptLifeChoice() {
    final choice = _currentLifeChoice;
    if (choice == null) {
      return;
    }
    final cost = _lifeChoiceCost(choice);
    if (_cash < cost) {
      _message('Не хватает ${_money(cost - _cash)}.');
      return;
    }
    final joyGain = _scaledJoyGain(choice.acceptJoy);
    setState(() {
      _cash -= cost;
      _joy = min(100, _joy + joyGain);
      if (choice.annualExpenseDelta > 0) {
        _recurringAnnualExpenses += choice.annualExpenseDelta;
      }
      _lifeChoiceIndex += 1;
      final recurring = choice.annualExpenseDelta > 0
          ? ' +${_money(_inflatedCost(choice.annualExpenseDelta))} к ежегодным расходам.'
          : '';
      final joyText = joyGain == 0
          ? 'радость без изменений'
          : 'радость +$joyGain';
      _yearLog.insert(
        0,
        '${choice.title}: оплачено ${_money(cost)}, $joyText.$recurring',
      );
    });
  }

  void _declineLifeChoice() {
    final choice = _currentLifeChoice;
    if (choice == null) {
      return;
    }
    final declineDelta = _scaledJoyDeclineDelta(choice.declineJoy);
    setState(() {
      _joy = declineDelta >= 0
          ? min(100, _joy + declineDelta)
          : max(0, _joy + declineDelta);
      _lifeChoiceIndex += 1;
      final joyText = declineDelta == 0
          ? 'радость без изменений'
          : 'радость ${declineDelta > 0 ? '+' : ''}$declineDelta';
      _yearLog.insert(0, '${choice.title}: отклонено, $joyText.');
    });
  }

  void _takeCredit() {
    if (!widget.difficulty.hasCredit) {
      _message('Кредиты доступны со средней сложности.');
      return;
    }
    if (_credit != null) {
      _message('У вас уже есть активный кредит.');
      return;
    }
    _normalizeCreditSelection();
    final offer = _selectedCreditOffer;
    final amount = min(_selectedCreditAmount, _creditLimit(offer));
    final years = min(_selectedCreditYears, _maxCreditYears);
    final payment = _creditPayment(offer, amount, years);
    if (payment > _salary * 0.55) {
      _message('Ежегодный платёж слишком высокий для текущей зарплаты.');
      return;
    }
    setState(() {
      final totalDebt = payment * years;
      _credit = CreditState(
        bank: offer.bank,
        amount: totalDebt,
        yearsLeft: years,
        payment: payment,
      );
      _cash += amount;
      _yearLog.insert(
        0,
        '${offer.bank}: кредит ${_money(amount)} на $years г., платёж ${_money(payment)} в год.',
      );
    });
  }

  void _showInvestDialog(MarketInstrument item) {
    if (_isBankrupt(item)) {
      _message('${item.name} обанкротилась. Операции недоступны.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _InvestmentSheet(
          item: item,
          cash: _cash,
          invested: _holdings[item.id] ?? 0,
          signal: _investmentSignalText(item),
          newsImpact: _newsImpactFor(item.id),
          collapseRisk: _collapseRiskFor(item),
          maxDepositYears: max(1, _totalYears - _year + 1),
          depositYearsLeft: _depositTerms[item.id],
          depositInitialYears: _depositInitialTerms[item.id],
          depositRate: _depositRates[item.id],
          rateForDepositTerm: (years) => _depositRateFor(item, years),
          onInvest: (amount, years) {
            Navigator.of(sheetContext).pop();
            _invest(item, amount, depositYears: years);
          },
          onWithdraw: (amount) {
            Navigator.of(sheetContext).pop();
            _withdraw(item, amount);
          },
        );
      },
    );
  }

  double _depositRateFor(MarketInstrument item, int years) {
    final longTermDiscount = min(0.018, max(0, years - 1) * 0.0025);
    return (item.baseReturn - longTermDiscount).clamp(0.025, 0.12).toDouble();
  }

  String _investmentSignalText(MarketInstrument item) {
    final impact = _newsImpactFor(item.id);
    final collapseRisk = _collapseRiskFor(item);
    if (item.id == 'federal_bond') {
      return 'Новостной сигнал: государственный инструмент, ставка стабильна.';
    }
    if (item.category == InstrumentCategory.bonds ||
        item.category == InstrumentCategory.deposits) {
      if (collapseRisk >= 0.18 || impact <= -0.08) {
        return 'Новостной сигнал: фон выглядит напряжённым, но процент остаётся фиксированным.';
      }
      if (impact >= 0.08) {
        return 'Новостной сигнал: фон выглядит спокойнее, процент остаётся фиксированным.';
      }
      return 'Новостной сигнал: ставка фиксированная, явного преимущества нет.';
    }
    if (item.category == InstrumentCategory.crypto) {
      if (collapseRisk >= 0.18) {
        return 'Новостной сигнал: вокруг монеты тревожный фон, возможен полный обвал.';
      }
      if (impact >= 0.08) {
        return 'Новостной сигнал: спрос оживился, возможен резкий рост, но риск остаётся высоким.';
      }
      if (impact <= -0.08) {
        return 'Новостной сигнал: рынок осторожничает, возможна глубокая просадка.';
      }
      return 'Новостной сигнал: явного преимущества нет, цена будет идти за настроением рынка.';
    }
    if (collapseRisk >= 0.18) {
      return 'Новостной сигнал: есть тревожные признаки, возможен резкий обвал.';
    }
    if (impact >= 0.08) {
      return 'Новостной сигнал: новости выглядят благоприятно, но гарантий нет.';
    }
    if (impact <= -0.08) {
      return 'Новостной сигнал: вокруг инструмента много осторожности.';
    }
    return 'Новостной сигнал: явного преимущества нет, исход ближе к рыночному.';
  }

  void _invest(MarketInstrument item, double amount, {int? depositYears}) {
    if (_isBankrupt(item)) {
      _message('${item.name} обанкротилась. Операции недоступны.');
      return;
    }
    const minAmount = 1000.0;
    if (amount < minAmount) {
      _message('Введите сумму от ${_money(minAmount)}.');
      return;
    }
    if (_cash < amount) {
      _message('Не хватает ${_money(amount - _cash)}.');
      return;
    }
    setState(() {
      _cash -= amount;
      _holdings[item.id] = (_holdings[item.id] ?? 0) + amount;
      if (item.category == InstrumentCategory.deposits) {
        final years = (_depositTerms[item.id] ?? depositYears ?? 1)
            .clamp(1, max(1, _totalYears - _year + 1))
            .toInt();
        final rate = _depositRates[item.id] ?? _depositRateFor(item, years);
        _depositTerms[item.id] = years;
        _depositInitialTerms[item.id] = _depositInitialTerms[item.id] ?? years;
        _depositRates[item.id] = rate;
        _yearLog.insert(
          0,
          '${item.name}: вклад ${_money(amount)} на $years ${_yearsWord(years)}, ставка ${_percent(rate)}.',
        );
      } else {
        _yearLog.insert(0, '${item.name}: вложено ${_money(amount)}.');
      }
    });
  }

  void _withdraw(MarketInstrument item, double amount) {
    if (_isBankrupt(item)) {
      _message('${item.name} обанкротилась. Операции недоступны.');
      return;
    }
    final value = _holdings[item.id] ?? 0;
    if (value <= 0) {
      _message('В ${item.name} пока нет вложений.');
      return;
    }
    final withdrawAmount = amount.clamp(0.0, value).toDouble();
    if (withdrawAmount <= 0) {
      _message('Введите сумму для вывода.');
      return;
    }
    setState(() {
      final left = value - withdrawAmount;
      _holdings[item.id] = left;
      _cash += withdrawAmount;
      if (left <= 0) {
        _holdings[item.id] = 0;
        _depositTerms.remove(item.id);
        _depositInitialTerms.remove(item.id);
        _depositRates.remove(item.id);
      }
      final early = item.category == InstrumentCategory.deposits && left > 0
          ? ' Досрочный частичный вывод.'
          : '';
      _yearLog.insert(
        0,
        '${item.name}: выведено ${_money(withdrawAmount)}.$early',
      );
    });
  }

  void _advanceYear() {
    if (_finished) {
      return;
    }
    if (!_mandatoryPaid) {
      _message('Сначала оплатите обязательные расходы за год.');
      setState(() => _tab = GameTab.budget);
      return;
    }
    if (!_lifeChoicesDone) {
      _message('Сначала оплатите или отклоните предложения года.');
      setState(() => _tab = GameTab.budget);
      return;
    }

    final summary = <String>[];
    setState(() {
      final salaryIncome = _salary;
      _cash += salaryIncome;
      summary.add('Зарплата: +${_money(salaryIncome)}');

      var marketTotal = 0.0;
      var bondCouponTotal = 0.0;
      for (final item in _availableInstruments) {
        if (_isBankrupt(item)) {
          continue;
        }
        final value = _holdings[item.id] ?? 0;
        final bankruptcyRisk = _collapseRiskFor(item);
        if (bankruptcyRisk > 0 && _random.nextDouble() < bankruptcyRisk) {
          if (item.category != InstrumentCategory.crypto) {
            _bankruptInstruments.add(item.id);
          }
          if (value > 0) {
            _holdings[item.id] = 0;
            _depositTerms.remove(item.id);
            _depositInitialTerms.remove(item.id);
            _depositRates.remove(item.id);
            marketTotal -= value;
          }
          if (value > 0 || item.category != InstrumentCategory.crypto) {
            summary.add(_collapseSummary(item, value));
          }
          continue;
        }
        if (value <= 0) {
          continue;
        }
        if (item.category == InstrumentCategory.deposits) {
          final baseRate = _depositRates[item.id] ?? item.baseReturn;
          final rate = baseRate.clamp(0.0, 0.16).toDouble();
          final next = value * (1 + rate);
          final yearsLeft = (_depositTerms[item.id] ?? 1) - 1;
          marketTotal += next - value;
          if (yearsLeft <= 0) {
            _holdings[item.id] = 0;
            _depositTerms.remove(item.id);
            _depositInitialTerms.remove(item.id);
            _depositRates.remove(item.id);
            _cash += next;
            summary.add('${item.name}: срок вклада завершён, +${_money(next)}');
          } else {
            _holdings[item.id] = next;
            _depositTerms[item.id] = yearsLeft;
          }
          continue;
        }
        if (item.category == InstrumentCategory.bonds) {
          final coupon = value * item.baseReturn;
          _cash += coupon;
          bondCouponTotal += coupon;
          continue;
        }
        if (item.category == InstrumentCategory.crypto) {
          final newsImpact = _newsImpactFor(item.id);
          final swing = (_random.nextDouble() * 2 - 1) * item.volatility;
          final rate = (item.baseReturn + newsImpact * 1.7 + swing)
              .clamp(-0.9, 2.4)
              .toDouble();
          final next = max(0.0, value * (1 + rate));
          _holdings[item.id] = next;
          marketTotal += next - value;
          continue;
        }
        final newsImpact = _newsImpactFor(item.id);
        final swing = (_random.nextDouble() * 2 - 1) * item.volatility;
        final rate = (item.baseReturn + newsImpact + swing)
            .clamp(-0.55, 0.8)
            .toDouble();
        final next = max(0.0, value * (1 + rate));
        _holdings[item.id] = next;
        marketTotal += next - value;
      }
      if (bondCouponTotal > 0) {
        summary.add('Купоны по облигациям: +${_money(bondCouponTotal)}');
      }
      if (marketTotal != 0) {
        summary.add('Изменение стоимости инвестиций: ${_money(marketTotal)}');
      }

      summary.add(_applyEvent(1));
      summary.add(_applyEvent(2));

      final credit = _credit;
      if (credit != null) {
        final payment = min(credit.payment, credit.amount);
        _cash -= payment;
        final nextAmount = max(0.0, credit.amount - payment);
        final nextYears = credit.yearsLeft - 1;
        summary.add('Платёж по кредиту: -${_money(payment)}');
        _credit = nextYears <= 0 || nextAmount <= 0
            ? null
            : CreditState(
                bank: credit.bank,
                amount: nextAmount,
                yearsLeft: nextYears,
                payment: credit.payment,
              );
      }

      final cardDebt = _cardDebt;
      if (cardDebt != null) {
        final payment = min(cardDebt.payment, cardDebt.amount);
        _cash -= payment;
        final nextAmount = max(0.0, cardDebt.amount - payment);
        final nextYears = cardDebt.yearsLeft - 1;
        summary.add('Кредитная карта: -${_money(payment)} без процентов');
        _cardDebt = nextYears <= 0 || nextAmount <= 0
            ? null
            : CardDebtState(
                amount: nextAmount,
                yearsLeft: nextYears,
                payment: cardDebt.payment,
              );
      }

      if (_year < _totalYears && _issuedCards.isNotEmpty) {
        final serviceFee = _cards
            .where((card) => _issuedCards.contains(card.id))
            .fold<double>(0, (sum, card) => sum + _cardCost(card));
        if (serviceFee > 0) {
          _cash -= serviceFee;
          summary.add(
            'Обслуживание карт на следующий год: -${_money(serviceFee)}',
          );
        }
      }

      final joyDecay = 10 + _random.nextInt(7) + (_joy >= 90 ? 3 : 0);
      _joy = max(0, _joy - joyDecay);
      summary.add('Эмоциональная усталость года: -$joyDecay радости.');
      _inflation = (0.08 + _random.nextDouble() * 0.035).clamp(0.08, 0.115);
      final salaryGrowth =
          max(0.05, _inflation * 0.78) +
          (_joy >= 80 ? 0.012 : 0) +
          _random.nextDouble() * 0.018;
      _priceIndex *= 1 + _inflation;
      _salary *= 1 + salaryGrowth;
      summary.add(
        'Инфляция: ${_percent(_inflation)}. Расходы следующего года — ${_money(_mandatoryExpense)}.',
      );
      summary.add('Рост зарплаты: +${_percent(salaryGrowth)}.');
      _mandatoryPaid = false;
      _activeInsurance.clear();

      if (_year >= _totalYears) {
        _finished = true;
      } else {
        _year += 1;
        _yearNews = _generateNewsPack();
        _lifeChoices = _generateLifeChoices();
        _lifeChoiceIndex = 0;
        _normalizeCreditSelection();
      }
    });

    _showYearSummary(summary);
  }

  String _collapseSummary(MarketInstrument item, double value) {
    if (value <= 0 && item.category != InstrumentCategory.crypto) {
      return '${item.name}: после плохих новостей компания закрыта для вложений.';
    }
    final loss = '-${_money(value)}';
    return switch (item.category) {
      InstrumentCategory.crypto =>
        '${item.name}: новостной обвал до нуля, $loss',
      InstrumentCategory.bonds =>
        '${item.name}: дефолт по обязательствам, $loss',
      InstrumentCategory.deposits =>
        '${item.name}: проблемы банка, вклад потерян, $loss',
      InstrumentCategory.other => '${item.name}: проект сорвался, $loss',
      InstrumentCategory.stocks => '${item.name}: банкротство компании, $loss',
    };
  }

  String _applyEvent(int index) {
    final roll = _random.nextDouble();
    final prefix = 'Событие $index';
    if (roll < 0.24) {
      final events = [
        ('дважды признали работником месяца', 3),
        ('удачно выступили на рабочей встрече', 2),
        ('провели спокойные выходные без крупных трат', 2),
        ('нашли удобный режим сна и тренировок', 3),
      ];
      final item = events[_random.nextInt(events.length)];
      _joy = min(100, _joy + item.$2);
      return '$prefix: ${item.$1}, радость +${item.$2}.';
    }
    if (roll < 0.5) {
      final cases = [
        ('medical', 'лечение после травмы', 120000.0, 12, 'ДМС'),
        ('car', 'ДТП на перекрёстке', 160000.0, 14, 'КАСКО'),
        ('flat', 'протечка в квартире', 135000.0, 11, 'страховка квартиры'),
      ];
      final item = cases[_random.nextInt(cases.length)];
      final insured = _activeInsurance.contains(item.$1);
      final cost = insured ? 0.0 : _inflatedCost(item.$3);
      final joyLoss = insured ? max(1, (item.$4 / 3).round()) : item.$4;
      _cash -= cost;
      _joy = max(0, _joy - joyLoss);
      return insured
          ? '$prefix: ${item.$2}. ${item.$5} всё покрыла, радость -$joyLoss.'
          : '$prefix: ${item.$2}. Расход -${_money(cost)}, радость -$joyLoss.';
    }
    if (roll < 0.7) {
      final bonus = _inflatedCost((15000 + _random.nextInt(45000)).toDouble());
      _cash += bonus;
      final joyGain = _scaledJoyGain(3);
      _joy = min(100, _joy + joyGain);
      return '$prefix: небольшой внеплановый доход +${_money(bonus)}, радость +$joyGain.';
    }
    if (roll < 0.86) {
      final cost = _inflatedCost((18000 + _random.nextInt(42000)).toDouble());
      _cash -= cost;
      final joyLoss = 3 + _random.nextInt(4);
      _joy = max(0, _joy - joyLoss);
      return '$prefix: бытовая поломка. Расход -${_money(cost)}, радость -$joyLoss.';
    }
    return '$prefix: год прошёл без заметных финансовых сюрпризов.';
  }

  void _showYearSummary(List<String> summary) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ui(context, 28)),
          ),
          title: Text(_finished ? 'Игра завершена' : 'Год завершён'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in summary)
                Padding(
                  padding: _uiInsets(context, const EdgeInsets.only(bottom: 8)),
                  child: Text(line),
                ),
              SizedBox(height: _ui(context, 10)),
              Text('Капитал: ${_money(_netWorth)}'),
              Text('Радость: $_joy/100'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_finished) {
                  _showResult();
                }
              },
              child: Text(_finished ? 'Результат' : 'Продолжить'),
            ),
          ],
        );
      },
    );
  }

  void _showResult() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final success = _joy >= 60 && _netWorth > 0;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ui(context, 28)),
          ),
          title: const Text('Результат игры'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _money(_netWorth),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: _ui(context, 10)),
              Text(
                success
                    ? 'Капитал засчитан: вы сохранили достаточный уровень радости.'
                    : 'Результат не засчитан полностью: радость или капитал оказались слишком низкими.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('В меню'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: const Text('Новая игра'),
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    setState(() {
      for (final item in _allInstruments) {
        _holdings[item.id] = 0;
      }
      _completedEducation.clear();
      _activeInsurance.clear();
      _issuedCards.clear();
      _depositTerms.clear();
      _depositInitialTerms.clear();
      _depositRates.clear();
      _usedLifeChoiceIds.clear();
      _bankruptInstruments.clear();
      _yearLog.clear();
      _year = 1;
      _joy = 70;
      _cash = widget.difficulty.startCash;
      _salary = widget.difficulty.startSalary;
      _inflation = 0.06;
      _baseMandatoryExpense = 300000;
      _priceIndex = 1;
      _recurringAnnualExpenses = 0;
      _mandatoryPaid = false;
      _finished = false;
      _credit = null;
      _cardDebt = null;
      _tab = GameTab.budget;
      _category = InstrumentCategory.stocks;
      _yearNews = _generateNewsPack();
      _lifeChoices = _generateLifeChoices();
      _lifeChoiceIndex = 0;
      _selectedCreditOfferId = 'green_credit';
      _selectedCreditYears = widget.difficulty.hasCredit ? 2 : 1;
      _selectedCreditAmount = widget.difficulty.hasCredit
          ? min(150000.0, _creditLimit(_selectedCreditOffer))
          : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _GameHeader(
                  year: _year,
                  totalYears: _totalYears,
                  invested: _portfolioValue,
                  cash: _cash,
                  joy: _joy,
                  onMenu: _showGameMenu,
                  onAdvance: _advanceYear,
                ),
                Expanded(child: _buildTab()),
              ],
            ),
            Positioned(
              left: _ui(context, 68),
              right: _ui(context, 68),
              bottom: _ui(context, 18),
              child: _BottomGameTabs(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    return switch (_tab) {
      GameTab.budget => _buildBudget(),
      GameTab.investments => _buildInvestments(),
      GameTab.news => _buildNews(),
    };
  }

  Widget _buildBudget() {
    return ListView(
      key: const ValueKey('budget-scroll'),
      padding: _uiInsets(context, const EdgeInsets.fromLTRB(32, 12, 32, 120)),
      children: [
        _MandatoryExpenseCard(
          amount: _mandatoryExpense,
          paid: _mandatoryPaid,
          onPay: _payMandatory,
        ),
        if (_mandatoryPaid) ...[
          SizedBox(height: _ui(context, 28)),
          _buildLifeChoiceStage(),
        ],
        SizedBox(height: _ui(context, 28)),
        _ShelfTitle(
          title: 'Образование',
          onHelp: () => _openHelp('Образование'),
        ),
        SizedBox(height: _ui(context, 12)),
        _HorizontalCards(
          children: [
            for (final item in _education)
              _LargeActionCard(
                icon: item.icon,
                color: item.color,
                title: item.title,
                price: _money(_educationCost(item)),
                subtitle:
                    '+ ${_percent(item.boostMin)}-${_percent(item.boostMax)} к зарплате',
                button: _completedEducation.contains(item.id)
                    ? 'Оплачено'
                    : 'Оплатить',
                enabled:
                    !_completedEducation.contains(item.id) &&
                    _cash >= _educationCost(item),
                onPressed: () => _buyEducation(item),
              ),
          ],
        ),
        SizedBox(height: _ui(context, 28)),
        _ShelfTitle(title: 'Страхование', onHelp: () => _openHelp('Страховка')),
        SizedBox(height: _ui(context, 12)),
        _HorizontalCards(
          children: [
            for (final item in _insurance)
              _LargeActionCard(
                icon: item.icon,
                color: item.color,
                title: item.title,
                price: _money(_insuranceCost(item)),
                subtitle: 'за год',
                button: _activeInsurance.contains(item.id)
                    ? 'Активно'
                    : 'Оплатить',
                enabled:
                    !_activeInsurance.contains(item.id) &&
                    _cash >= _insuranceCost(item),
                onPressed: () => _buyInsurance(item),
              ),
          ],
        ),
        SizedBox(height: _ui(context, 28)),
        _ShelfTitle(
          title: 'Банковские карты',
          onHelp: () => _openHelp('Банковские карты'),
        ),
        SizedBox(height: _ui(context, 12)),
        _HorizontalCards(
          children: [
            for (final item in _cards)
              _CardOfferTile(
                item: item,
                cost: _cardCost(item),
                issued: _issuedCards.contains(item.id),
                enabled:
                    !_issuedCards.contains(item.id) && _cash >= _cardCost(item),
                onPressed: () => _issueCard(item),
              ),
          ],
        ),
        if (_cardDebt != null) ...[
          SizedBox(height: _ui(context, 14)),
          _CardDebtBanner(debt: _cardDebt!),
        ],
        SizedBox(height: _ui(context, 28)),
        _ShelfTitle(title: 'Кредит', onHelp: () => _openHelp('Кредит')),
        SizedBox(height: _ui(context, 12)),
        _CreditPanel(
          credit: _credit,
          offers: _creditOffers,
          selectedOffer: _selectedCreditOffer,
          selectedAmount: _selectedCreditAmount
              .clamp(50000.0, _creditLimit(_selectedCreditOffer))
              .toDouble(),
          selectedYears: _selectedCreditYears.clamp(1, _maxCreditYears).toInt(),
          maxYears: _maxCreditYears,
          limit: _creditLimit(_selectedCreditOffer),
          payment: _creditPayment(
            _selectedCreditOffer,
            _selectedCreditAmount
                .clamp(50000.0, _creditLimit(_selectedCreditOffer))
                .toDouble(),
            _selectedCreditYears.clamp(1, _maxCreditYears).toInt(),
          ),
          salary: _salary,
          enabled: widget.difficulty.hasCredit && _credit == null,
          onOfferChanged: _selectCreditOffer,
          onAmountChanged: _selectCreditAmount,
          onYearsChanged: _selectCreditYears,
          onTake: _takeCredit,
        ),
        if (_yearLog.isNotEmpty) ...[
          SizedBox(height: _ui(context, 28)),
          Text('Журнал хода', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: _ui(context, 12)),
          for (final line in _yearLog.take(5))
            Padding(
              padding: _uiInsets(context, const EdgeInsets.only(bottom: 8)),
              child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
            ),
        ],
      ],
    );
  }

  Widget _buildLifeChoiceStage() {
    final choice = _currentLifeChoice;
    if (choice == null) {
      return _YearReadyCard(
        onNews: () => setState(() => _tab = GameTab.news),
        onInvestments: () => setState(() => _tab = GameTab.investments),
        onFinish: _advanceYear,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShelfTitle(
          title: 'Решение года',
          onHelp: () => _openHelp('Необязательные расходы'),
        ),
        SizedBox(height: _ui(context, 12)),
        _LifeChoiceCard(
          choice: choice,
          cost: _lifeChoiceCost(choice),
          annualExpenseDelta: _inflatedCost(choice.annualExpenseDelta),
          canPay: _cash >= _lifeChoiceCost(choice),
          index: _lifeChoiceIndex + 1,
          total: _lifeChoices.length,
          onAccept: _acceptLifeChoice,
          onDecline: _declineLifeChoice,
        ),
      ],
    );
  }

  Widget _buildInvestments() {
    final categories = InstrumentCategory.values.where((category) {
      if (category == InstrumentCategory.crypto &&
          !widget.difficulty.hasCrypto) {
        return false;
      }
      if (category == InstrumentCategory.other &&
          widget.difficulty == GameDifficulty.easy) {
        return false;
      }
      return true;
    }).toList();
    final visible = _availableInstruments
        .where((item) => item.category == _category)
        .toList();
    if (!categories.contains(_category)) {
      _category = categories.first;
    }

    return Column(
      children: [
        SizedBox(
          height: _ui(context, 56),
          child: ListView.separated(
            padding: _uiInsets(
              context,
              const EdgeInsets.symmetric(horizontal: 32),
            ),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = category == _category;
              return TextButton(
                onPressed: () => setState(() => _category = category),
                child: Text(
                  category.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.black : const Color(0xFFC3C4C8),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) =>
                SizedBox(width: _ui(context, 18)),
            itemCount: categories.length,
          ),
        ),
        Expanded(
          child: ListView(
            padding: _uiInsets(
              context,
              const EdgeInsets.fromLTRB(32, 8, 32, 120),
            ),
            children: [
              for (final item in visible)
                _InstrumentRow(
                  item: item,
                  invested: _holdings[item.id] ?? 0,
                  bankrupt: _isBankrupt(item),
                  onInvest: () => _showInvestDialog(item),
                  onWithdraw: () => _showInvestDialog(item),
                ),
              SizedBox(height: _ui(context, 10)),
              Center(
                child: TextButton.icon(
                  onPressed: () => _openHelp(_helpTitleForCategory(_category)),
                  icon: Icon(Icons.help_rounded, size: _ui(context, 24)),
                  label: Text(
                    'Как работают ${_helpTextForCategory(_category)}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNews() {
    return ListView(
      padding: _uiInsets(context, const EdgeInsets.fromLTRB(64, 20, 64, 120)),
      children: [
        Text(
          'Финансовые\nНовости',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontFamily: 'serif'),
        ),
        SizedBox(height: _ui(context, 24)),
        Container(height: _ui(context, 5), color: const Color(0xFF8BC0E3)),
        SizedBox(height: _ui(context, 28)),
        for (final item in _yearNews) ...[
          _NewsParagraph(text: item.title, strong: true),
          SizedBox(height: _ui(context, 12)),
          _NewsParagraph(text: item.body),
          _NewsDivider(),
        ],
      ],
    );
  }

  void _openHelp(String title) {
    final topic = howToTopics.firstWhere(
      (topic) => topic.title == title,
      orElse: () => howToTopics.first,
    );
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => HowToDetailScreen(topic: topic)));
  }

  String _helpTitleForCategory(InstrumentCategory category) {
    return switch (category) {
      InstrumentCategory.stocks => 'Акции',
      InstrumentCategory.bonds => 'Облигации',
      InstrumentCategory.deposits => 'Вклады',
      InstrumentCategory.crypto => 'Криптовалюта',
      InstrumentCategory.other => 'Прочие инвестиции',
    };
  }

  String _helpTextForCategory(InstrumentCategory category) {
    return switch (category) {
      InstrumentCategory.stocks => 'акции',
      InstrumentCategory.bonds => 'облигации',
      InstrumentCategory.deposits => 'вклады',
      InstrumentCategory.crypto => 'криптовалюты',
      InstrumentCategory.other => 'прочие инвестиции',
    };
  }

  void _showGameMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ActionSheet(
          children: [
            _SheetButton(
              label: 'Выйти в меню',
              icon: Icons.home_rounded,
              colors: const [Color(0xFFEAC455), Color(0xFFFF8A80)],
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            _SheetButton(
              label: 'Начать новую игру',
              icon: Icons.sports_esports_rounded,
              colors: const [Color(0xFF62C899), Color(0xFFD4F173)],
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
            ),
            _SheetButton(
              label: 'Как играть?',
              icon: Icons.help_outline_rounded,
              colors: const [Color(0xFF8BA8E8), Color(0xFFE178E8)],
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
                );
              },
            ),
            _SheetButton(
              label: 'Закрыть',
              icon: Icons.close_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.year,
    required this.totalYears,
    required this.invested,
    required this.cash,
    required this.joy,
    required this.onMenu,
    required this.onAdvance,
  });

  final int year;
  final int totalYears;
  final double invested;
  final double cash;
  final int joy;
  final VoidCallback onMenu;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _uiInsets(context, const EdgeInsets.fromLTRB(32, 10, 32, 14)),
      child: Column(
        children: [
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.menu_rounded,
                color: const Color(0xFFF3F4F7),
                onPressed: onMenu,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Ход $year из $totalYears',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: _ui(context, 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 1; i <= totalYears; i++)
                          Container(
                            width: _ui(context, 17),
                            height: _ui(context, 7),
                            margin: _uiInsets(
                              context,
                              const EdgeInsets.symmetric(horizontal: 2),
                            ),
                            decoration: BoxDecoration(
                              color: i == year
                                  ? const Color(0xFFF6B937)
                                  : const Color(0xFFDADBDD),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _RoundIconButton(
                icon: Icons.fast_forward_rounded,
                color: const Color(0xFF35C94B),
                iconColor: Colors.black,
                size: 70,
                onPressed: onAdvance,
              ),
            ],
          ),
          SizedBox(height: _ui(context, 22)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeaderStat(
                icon: Icons.business_center_rounded,
                color: const Color(0xFF7CB4DF),
                value: _money(invested),
                label: 'Вложено',
              ),
              _HeaderStat(
                icon: Icons.payments_rounded,
                color: const Color(0xFF91D684),
                value: _money(cash),
                label: 'Деньги',
              ),
              _HeaderStat(
                icon: Icons.sentiment_neutral_rounded,
                color: const Color(0xFFF1C34A),
                value: '$joy/100',
                label: 'Радость',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ui(context, 110),
      child: Column(
        children: [
          Icon(icon, color: color, size: _ui(context, 36)),
          SizedBox(height: _ui(context, 4)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFF626773)),
          ),
        ],
      ),
    );
  }
}

class _BottomGameTabs extends StatelessWidget {
  const _BottomGameTabs({required this.selected, required this.onChanged});

  final GameTab selected;
  final ValueChanged<GameTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _ui(context, 78),
      padding: _uiInsets(context, const EdgeInsets.all(6)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(_ui(context, 40)),
        border: Border.all(color: const Color(0xFFE9EAEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: _ui(context, 24),
            offset: Offset(0, _ui(context, 8)),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final tab in GameTab.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(tab),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: tab == selected
                        ? const Color(0xFFE4E4E4)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(_ui(context, 34)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab.icon,
                        color: Colors.black,
                        size: _ui(context, 28),
                      ),
                      Text(tab.label, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MandatoryExpenseCard extends StatelessWidget {
  const _MandatoryExpenseCard({
    required this.amount,
    required this.paid,
    required this.onPay,
  });

  final double amount;
  final bool paid;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _uiInsets(context, const EdgeInsets.all(28)),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(
            paid ? Icons.check_circle_rounded : Icons.point_of_sale_rounded,
            color: const Color(0xFF83D29A),
            size: _ui(context, 44),
          ),
          SizedBox(height: _ui(context, 20)),
          Text(
            paid
                ? 'Расходы на жизнь оплачены'
                : 'Минимальные расходы на жизнь за год',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: _ui(context, 14)),
          Text(
            'Еда, жильё, транспорт и одежда. Без оплаты нельзя завершить ход.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF666C78)),
          ),
          SizedBox(height: _ui(context, 24)),
          Text(
            _money(amount),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: _ui(context, 34)),
          _PlainButton(
            label: paid ? 'Оплачено' : 'Оплатить',
            enabled: !paid,
            onPressed: onPay,
          ),
        ],
      ),
    );
  }
}

class _LifeChoiceCard extends StatelessWidget {
  const _LifeChoiceCard({
    required this.choice,
    required this.cost,
    required this.annualExpenseDelta,
    required this.canPay,
    required this.index,
    required this.total,
    required this.onAccept,
    required this.onDecline,
  });

  final LifeChoice choice;
  final double cost;
  final double annualExpenseDelta;
  final bool canPay;
  final int index;
  final int total;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final declineDelta = _scaledJoyDeclineDelta(choice.declineJoy);
    final acceptJoy = _scaledJoyGain(choice.acceptJoy);
    final declineText = declineDelta == 0
        ? 'без потери радости'
        : '${declineDelta > 0 ? '+' : ''}$declineDelta радости';
    final acceptText = acceptJoy == 0 ? 'без эффекта' : '+$acceptJoy радости';
    return Container(
      padding: _uiInsets(context, const EdgeInsets.fromLTRB(26, 28, 26, 20)),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: _ui(context, 44),
                height: _ui(context, 44),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF77CA9A), Color(0xFFD8F47C)],
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: _ui(context, 24),
                ),
              ),
              SizedBox(width: _ui(context, 14)),
              Expanded(
                child: Text(
                  'Предложение $index из $total',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF7F8590),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _ui(context, 26)),
          Text(
            choice.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: _ui(context, 18)),
          Text(
            choice.body,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF5F6570)),
          ),
          SizedBox(height: _ui(context, 28)),
          Text(_money(cost), style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: _ui(context, 22)),
          Wrap(
            alignment: WrapAlignment.center,
            runSpacing: _ui(context, 8),
            spacing: _ui(context, 16),
            children: [
              if (declineDelta < 0)
                _JoyEffectPill(
                  icon: Icons.sentiment_dissatisfied_rounded,
                  color: const Color(0xFFE6AA52),
                  text: 'Отказ: $declineText',
                ),
              _JoyEffectPill(
                icon: Icons.sentiment_satisfied_alt_rounded,
                color: const Color(0xFF77CFA0),
                text: 'Оплата: $acceptText',
              ),
            ],
          ),
          if (choice.annualExpenseDelta > 0) ...[
            SizedBox(height: _ui(context, 8)),
            Text(
              '+ ${_money(annualExpenseDelta)} к расходам каждый год',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF777D88)),
            ),
          ],
          SizedBox(height: _ui(context, 28)),
          Row(
            children: [
              Expanded(
                child: _CompactButton(label: 'Отклонить', onPressed: onDecline),
              ),
              SizedBox(width: _ui(context, 8)),
              Expanded(
                child: _CompactButton(
                  label: 'Оплатить',
                  enabled: canPay,
                  onPressed: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YearReadyCard extends StatelessWidget {
  const _YearReadyCard({
    required this.onNews,
    required this.onInvestments,
    required this.onFinish,
  });

  final VoidCallback onNews;
  final VoidCallback onInvestments;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _uiInsets(context, const EdgeInsets.all(28)),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F6),
        borderRadius: BorderRadius.circular(_ui(context, 24)),
      ),
      child: Column(
        children: [
          Container(
            width: _ui(context, 58),
            height: _ui(context, 58),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF69C991), Color(0xFFD4F173)],
              ),
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: _ui(context, 36),
            ),
          ),
          SizedBox(height: _ui(context, 24)),
          Text(
            'Основные решения приняты',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: _ui(context, 12)),
          Text(
            'Можно закончить ход, но перед этим полезно посмотреть новости и инвестировать свободные средства.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF666C78)),
          ),
          SizedBox(height: _ui(context, 26)),
          Row(
            children: [
              Expanded(
                child: _CompactButton(label: 'Новости', onPressed: onNews),
              ),
              SizedBox(width: _ui(context, 12)),
              Expanded(
                child: _CompactButton(
                  label: 'Инвестиции',
                  onPressed: onInvestments,
                ),
              ),
            ],
          ),
          SizedBox(height: _ui(context, 18)),
          _GradientButton(label: 'Закончить ход', onPressed: onFinish),
        ],
      ),
    );
  }
}

class _JoyEffectPill extends StatelessWidget {
  const _JoyEffectPill({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: _ui(context, 24)),
        SizedBox(width: _ui(context, 6)),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    );
  }
}

class _ShelfTitle extends StatelessWidget {
  const _ShelfTitle({required this.title, required this.onHelp});

  final String title;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        _RoundIconButton(
          icon: Icons.question_mark_rounded,
          color: const Color(0xFFF0F1F5),
          iconColor: const Color(0xFF8C9098),
          size: 48,
          onPressed: onHelp,
        ),
      ],
    );
  }
}

class _HorizontalCards extends StatelessWidget {
  const _HorizontalCards({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _ui(context, 318),
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => children[index],
        separatorBuilder: (context, index) => SizedBox(width: _ui(context, 16)),
        itemCount: children.length,
      ),
    );
  }
}

class _LargeActionCard extends StatelessWidget {
  const _LargeActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.button,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String price;
  final String subtitle;
  final String button;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ui(context, 226),
      padding: _uiInsets(context, const EdgeInsets.all(18)),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: color, size: _ui(context, 42)),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: _ui(context, 16)),
          FittedBox(
            child: Text(price, style: Theme.of(context).textTheme.titleLarge),
          ),
          SizedBox(height: _ui(context, 4)),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          _PlainButton(label: button, enabled: enabled, onPressed: onPressed),
        ],
      ),
    );
  }
}

class _CardOfferTile extends StatelessWidget {
  const _CardOfferTile({
    required this.item,
    required this.cost,
    required this.issued,
    required this.enabled,
    required this.onPressed,
  });

  final BankCardOffer item;
  final double cost;
  final bool issued;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ui(context, 226),
      padding: _uiInsets(context, const EdgeInsets.all(18)),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: _ui(context, 56),
            height: _ui(context, 38),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: item.colors),
              borderRadius: BorderRadius.circular(_ui(context, 8)),
            ),
            child: const Icon(Icons.more_horiz_rounded, color: Colors.white),
          ),
          const Spacer(),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: _ui(context, 10)),
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: _ui(context, 16)),
          FittedBox(
            child: Text(
              '${_money(cost)}/год',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const Spacer(),
          _PlainButton(
            label: issued ? 'Выпущена' : 'Выпустить',
            enabled: enabled,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class _CardDebtBanner extends StatelessWidget {
  const _CardDebtBanner({required this.debt});

  final CardDebtState debt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _uiInsets(context, const EdgeInsets.all(18)),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(_ui(context, 20)),
      ),
      child: Row(
        children: [
          Container(
            width: _ui(context, 52),
            height: _ui(context, 38),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAC455), Color(0xFFFF6B5C)],
              ),
              borderRadius: BorderRadius.circular(_ui(context, 8)),
            ),
            child: const Icon(Icons.credit_card_rounded, color: Colors.white),
          ),
          SizedBox(width: _ui(context, 14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Кредитная карта без процентов',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Остаток ${_money(debt.amount)}, списание ${_money(debt.payment)} каждый ход.',
                  style: _mutedLabel(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditPanel extends StatelessWidget {
  const _CreditPanel({
    required this.credit,
    required this.offers,
    required this.selectedOffer,
    required this.selectedAmount,
    required this.selectedYears,
    required this.maxYears,
    required this.limit,
    required this.payment,
    required this.salary,
    required this.enabled,
    required this.onOfferChanged,
    required this.onAmountChanged,
    required this.onYearsChanged,
    required this.onTake,
  });

  final CreditState? credit;
  final List<CreditOffer> offers;
  final CreditOffer selectedOffer;
  final double selectedAmount;
  final int selectedYears;
  final int maxYears;
  final double limit;
  final double payment;
  final double salary;
  final bool enabled;
  final ValueChanged<String> onOfferChanged;
  final ValueChanged<double> onAmountChanged;
  final ValueChanged<int> onYearsChanged;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final activeCredit = credit;
    return Container(
      padding: _uiInsets(context, const EdgeInsets.all(22)),
      decoration: _cardDecoration(),
      child: activeCredit != null
          ? _ActiveCreditInfo(credit: activeCredit)
          : !enabled
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _CircleIcon(
                      icon: Icons.lock_rounded,
                      color: Color(0xFFB8BAC0),
                    ),
                    SizedBox(width: _ui(context, 16)),
                    Expanded(
                      child: Text(
                        'Кредит недоступен',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _ui(context, 14)),
                Text(
                  'Банковские кредиты открываются со средней сложности. Кредитная карта доступна в блоке банковских карт.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF808691),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CircleIcon(
                      icon: selectedOffer.icon,
                      color: selectedOffer.color,
                    ),
                    SizedBox(width: _ui(context, 16)),
                    Expanded(
                      child: Text(
                        selectedOffer.bank,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      _percent(selectedOffer.annualRate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                SizedBox(height: _ui(context, 18)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final offer in offers)
                      ChoiceChip(
                        selected: offer.id == selectedOffer.id,
                        label: Text(offer.bank),
                        avatar: Icon(offer.icon, size: 18),
                        onSelected: (_) => onOfferChanged(offer.id),
                      ),
                  ],
                ),
                SizedBox(height: _ui(context, 20)),
                _CreditValueLine(
                  label: 'Сумма кредита',
                  value: _money(selectedAmount),
                ),
                Slider(
                  min: 50000,
                  max: limit,
                  divisions: max(1, ((limit - 50000) / 50000).round()),
                  value: selectedAmount.clamp(50000.0, limit).toDouble(),
                  onChanged: onAmountChanged,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '50 000 ₽',
                        overflow: TextOverflow.ellipsis,
                        style: _mutedLabel(context),
                      ),
                    ),
                    SizedBox(width: _ui(context, 12)),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Лимит ${_money(limit)}',
                          overflow: TextOverflow.ellipsis,
                          style: _mutedLabel(context),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _ui(context, 14)),
                _CreditValueLine(
                  label: 'Срок',
                  value: '$selectedYears ${_yearsWord(selectedYears)}',
                ),
                if (maxYears > 1)
                  Slider(
                    min: 1,
                    max: maxYears.toDouble(),
                    divisions: maxYears - 1,
                    value: selectedYears.toDouble(),
                    onChanged: (value) => onYearsChanged(value.round()),
                  )
                else
                  Padding(
                    padding: _uiInsets(
                      context,
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'До конца игры остался 1 год.',
                      style: _mutedLabel(context),
                    ),
                  ),
                SizedBox(height: _ui(context, 12)),
                Container(
                  width: double.infinity,
                  padding: _uiInsets(context, const EdgeInsets.all(16)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(_ui(context, 16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CreditValueLine(
                        label: 'Платёж каждый ход',
                        value: _money(payment),
                      ),
                      SizedBox(height: _ui(context, 8)),
                      Text(
                        'Рекомендация: держать платёж ниже 55% годовой зарплаты. Сейчас зарплата ${_money(salary)}.',
                        style: _mutedLabel(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: _ui(context, 20)),
                _GradientButton(label: 'Взять кредит', onPressed: onTake),
              ],
            ),
    );
  }
}

class _ActiveCreditInfo extends StatelessWidget {
  const _ActiveCreditInfo({required this.credit});

  final CreditState credit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _CircleIcon(
              icon: Icons.account_balance_rounded,
              color: Color(0xFF85D88B),
            ),
            SizedBox(width: _ui(context, 16)),
            Expanded(
              child: Text(
                credit.bank,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              _money(credit.payment),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        SizedBox(height: _ui(context, 16)),
        _CreditValueLine(label: 'Остаток долга', value: _money(credit.amount)),
        SizedBox(height: _ui(context, 8)),
        _CreditValueLine(
          label: 'Осталось',
          value: '${credit.yearsLeft} ${_yearsWord(credit.yearsLeft)}',
        ),
        SizedBox(height: _ui(context, 20)),
        _PlainButton(label: 'Кредит активен', enabled: false, onPressed: () {}),
      ],
    );
  }
}

class _CreditValueLine extends StatelessWidget {
  const _CreditValueLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF777D88)),
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _InvestmentSheet extends StatefulWidget {
  const _InvestmentSheet({
    required this.item,
    required this.cash,
    required this.invested,
    required this.signal,
    required this.newsImpact,
    required this.collapseRisk,
    required this.maxDepositYears,
    required this.depositYearsLeft,
    required this.depositInitialYears,
    required this.depositRate,
    required this.rateForDepositTerm,
    required this.onInvest,
    required this.onWithdraw,
  });

  final MarketInstrument item;
  final double cash;
  final double invested;
  final String signal;
  final double newsImpact;
  final double collapseRisk;
  final int maxDepositYears;
  final int? depositYearsLeft;
  final int? depositInitialYears;
  final double? depositRate;
  final double Function(int years) rateForDepositTerm;
  final void Function(double amount, int? depositYears) onInvest;
  final ValueChanged<double> onWithdraw;

  @override
  State<_InvestmentSheet> createState() => _InvestmentSheetState();
}

class _InvestmentSheetState extends State<_InvestmentSheet> {
  late final TextEditingController _controller;
  late int _depositYears;

  static const double _minAmount = 1000;

  double get _amount => _parseMoneyInput(_controller.text);
  bool get _canInvest => _amount >= _minAmount && _amount <= widget.cash;
  bool get _canWithdraw => _amount > 0 && _amount <= widget.invested;

  bool get _isDeposit => widget.item.category == InstrumentCategory.deposits;
  bool get _hasActiveDeposit =>
      _isDeposit && (widget.depositYearsLeft ?? 0) > 0 && widget.invested > 0;

  @override
  void initState() {
    super.initState();
    final initialAmount = widget.cash >= _minAmount
        ? min(widget.cash, max(_minAmount, widget.item.minimum))
        : widget.invested;
    _controller = TextEditingController(
      text: initialAmount > 0 ? initialAmount.round().toString() : '',
    );
    _depositYears = (widget.depositYearsLeft ?? 1)
        .clamp(1, widget.maxDepositYears)
        .toInt();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final activeRate =
        widget.depositRate ?? widget.rateForDepositTerm(_depositYears);
    final projectedRate = widget.rateForDepositTerm(_depositYears);
    final errorText = _errorText();
    final contentPadding = _uiInsets(
      context,
      const EdgeInsets.fromLTRB(32, 12, 32, 28),
    );

    return FractionallySizedBox(
      heightFactor: 0.94,
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(_ui(context, 34)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: _uiInsets(
                  context,
                  const EdgeInsets.fromLTRB(32, 14, 32, 0),
                ),
                child: SizedBox(
                  height: _ui(context, 44),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: _ui(context, 54),
                        height: _ui(context, 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6E7EA),
                          borderRadius: BorderRadius.circular(_ui(context, 99)),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _RoundIconButton(
                          icon: Icons.close_rounded,
                          color: const Color(0xFFF1F2F6),
                          iconColor: const Color(0xFF8F96A3),
                          size: 44,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: contentPadding.copyWith(
                    bottom: contentPadding.bottom + bottomInset,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CircleIcon(
                        icon: widget.item.icon,
                        color: widget.item.color,
                      ),
                      SizedBox(height: _ui(context, 18)),
                      Text(
                        widget.item.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (_isDeposit) ...[
                        SizedBox(height: _ui(context, 6)),
                        Text(
                          '${_percent(_hasActiveDeposit ? activeRate : projectedRate)} в год',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: const Color(0xFF9A9CA3)),
                        ),
                      ],
                      SizedBox(height: _ui(context, 14)),
                      Text(
                        widget.item.description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF606672),
                        ),
                      ),
                      SizedBox(height: _ui(context, 16)),
                      _InvestmentSignalPanel(
                        signal: widget.signal,
                        newsImpact: widget.newsImpact,
                        collapseRisk: widget.collapseRisk,
                      ),
                      SizedBox(height: _ui(context, 16)),
                      Row(
                        children: [
                          Expanded(
                            child: _InvestmentAmountBox(
                              label: 'Вложено',
                              value: _money(widget.invested),
                            ),
                          ),
                          SizedBox(width: _ui(context, 12)),
                          Expanded(
                            child: _InvestmentAmountBox(
                              label: 'Доступно',
                              value: _money(widget.cash),
                            ),
                          ),
                        ],
                      ),
                      if (_isDeposit) ...[
                        SizedBox(height: _ui(context, 16)),
                        _DepositTermPicker(
                          years: _depositYears,
                          initialYears: widget.depositInitialYears,
                          maxYears: widget.maxDepositYears,
                          locked: _hasActiveDeposit,
                          rate: _hasActiveDeposit ? activeRate : projectedRate,
                          onChanged: (value) =>
                              setState(() => _depositYears = value),
                        ),
                      ],
                      SizedBox(height: _ui(context, 16)),
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF2F3F6),
                          labelText: 'Сумма',
                          suffixText: '₽',
                          helperText:
                              'Минимум ${_money(_minAmount)}. Можно пополнить или вывести.',
                          errorText: errorText,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              _ui(context, 18),
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: _ui(context, 14)),
                      Row(
                        children: [
                          Expanded(
                            child: _PlainButton(
                              label: 'Вывести',
                              enabled: _canWithdraw,
                              onPressed: () => widget.onWithdraw(_amount),
                            ),
                          ),
                          SizedBox(width: _ui(context, 12)),
                          Expanded(
                            child: _GradientButton(
                              label: 'Пополнить',
                              enabled: _canInvest,
                              onPressed: () => widget.onInvest(
                                _amount,
                                _isDeposit ? _depositYears : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _ui(context, 12)),
                      Row(
                        children: [
                          Expanded(
                            child: _PlainButton(
                              label: 'Вывести все',
                              enabled: widget.invested > 0,
                              onPressed: () =>
                                  widget.onWithdraw(widget.invested),
                            ),
                          ),
                          SizedBox(width: _ui(context, 12)),
                          Expanded(
                            child: _PlainButton(
                              label: 'Пополнить все',
                              enabled: widget.cash >= _minAmount,
                              onPressed: () => widget.onInvest(
                                widget.cash,
                                _isDeposit ? _depositYears : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _errorText() {
    if (_controller.text.isEmpty) {
      return null;
    }
    if (_amount <= 0) {
      return 'Введите сумму';
    }
    if (_amount < _minAmount && _amount > widget.invested) {
      return 'Пополнение доступно от ${_money(_minAmount)}';
    }
    if (_amount > widget.cash && _amount > widget.invested) {
      return 'Недостаточно денег для пополнения или вывода';
    }
    return null;
  }
}

class _InvestmentSignalPanel extends StatelessWidget {
  const _InvestmentSignalPanel({
    required this.signal,
    required this.newsImpact,
    required this.collapseRisk,
  });

  final String signal;
  final double newsImpact;
  final double collapseRisk;

  @override
  Widget build(BuildContext context) {
    final tone = collapseRisk > 0.16 || newsImpact < -0.08
        ? const Color(0xFFE7A34F)
        : newsImpact > 0.08
        ? const Color(0xFF73C995)
        : const Color(0xFF8F96A3);
    return Container(
      width: double.infinity,
      padding: _uiInsets(context, const EdgeInsets.all(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(_ui(context, 18)),
      ),
      child: Row(
        children: [
          Icon(Icons.newspaper_rounded, color: tone, size: _ui(context, 26)),
          SizedBox(width: _ui(context, 12)),
          Expanded(
            child: Text(
              signal,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF606672),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestmentAmountBox extends StatelessWidget {
  const _InvestmentAmountBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _uiInsets(context, const EdgeInsets.symmetric(vertical: 14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F6),
        borderRadius: BorderRadius.circular(_ui(context, 18)),
      ),
      child: Column(
        children: [
          FittedBox(
            child: Text(value, style: Theme.of(context).textTheme.titleMedium),
          ),
          SizedBox(height: _ui(context, 3)),
          Text(label, style: _mutedLabel(context)),
        ],
      ),
    );
  }
}

class _DepositTermPicker extends StatelessWidget {
  const _DepositTermPicker({
    required this.years,
    required this.initialYears,
    required this.maxYears,
    required this.locked,
    required this.rate,
    required this.onChanged,
  });

  final int years;
  final int? initialYears;
  final int maxYears;
  final bool locked;
  final double rate;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: _uiInsets(context, const EdgeInsets.all(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(_ui(context, 18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  locked
                      ? 'Осталось $years ${_yearsWord(years)} из ${initialYears ?? years}'
                      : 'Срок вклада: $years ${_yearsWord(years)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                _percent(rate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8F96A3),
                ),
              ),
            ],
          ),
          SizedBox(height: _ui(context, 8)),
          if (maxYears > 1)
            Slider(
              min: 1,
              max: maxYears.toDouble(),
              divisions: maxYears - 1,
              value: years.clamp(1, maxYears).toDouble(),
              onChanged: locked
                  ? null
                  : (value) => onChanged(value.round().clamp(1, maxYears)),
            )
          else
            SizedBox(height: _ui(context, 12)),
          Text(
            locked
                ? 'Пополнение пойдёт в уже открытый вклад с тем же сроком.'
                : 'Чем длиннее срок, тем немного ниже ставка. Вклад вернётся на баланс после завершения срока.',
            style: _mutedLabel(context),
          ),
        ],
      ),
    );
  }
}

class _InstrumentRow extends StatelessWidget {
  const _InstrumentRow({
    required this.item,
    required this.invested,
    required this.bankrupt,
    required this.onInvest,
    required this.onWithdraw,
  });

  final MarketInstrument item;
  final double invested;
  final bool bankrupt;
  final VoidCallback onInvest;
  final VoidCallback onWithdraw;

  String get _returnText {
    if (item.category == InstrumentCategory.stocks ||
        item.category == InstrumentCategory.crypto) {
      return bankrupt ? 'Банкрот' : '';
    }
    if (bankrupt) {
      return 'Банкрот';
    }
    final prefix = item.category == InstrumentCategory.deposits ? 'до ' : '';
    return '$prefix${_percent(item.baseReturn)} в год';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: _uiInsets(context, const EdgeInsets.only(bottom: 14)),
      padding: _uiInsets(context, const EdgeInsets.all(18)),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        children: [
          _CircleIcon(icon: item.icon, color: item.color),
          SizedBox(width: _ui(context, 18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: bankrupt ? const Color(0xFF9A9CA3) : Colors.black,
                  ),
                ),
                if (_returnText.isNotEmpty) ...[
                  SizedBox(height: _ui(context, 3)),
                  Text(
                    _returnText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: bankrupt
                          ? const Color(0xFFE36F6F)
                          : const Color(0xFF9A9CA3),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              _SmallPlainButton(
                label: bankrupt ? 'Банкрот' : 'Вложить',
                onPressed: bankrupt ? null : onInvest,
              ),
              if (!bankrupt && invested > 0) ...[
                SizedBox(height: _ui(context, 8)),
                _SmallPlainButton(label: 'Вывести', onPressed: onWithdraw),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NewsParagraph extends StatelessWidget {
  const _NewsParagraph({required this.text, this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: strong ? 24 : 22,
        fontWeight: strong ? FontWeight.w800 : FontWeight.w400,
        height: 1.17,
        color: strong ? Colors.black : const Color(0xFF5A5A5A),
      ),
    );
  }
}

class _NewsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ui(context, 48),
      height: _ui(context, 5),
      margin: _uiInsets(context, const EdgeInsets.symmetric(vertical: 28)),
      color: const Color(0xFF8BC0E3),
    );
  }
}

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final main = howToTopics
        .where((topic) => topic.group == 'Основное')
        .toList();
    final investment = howToTopics
        .where((topic) => topic.group == 'Инвестиции')
        .toList();
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _HelpTopBar(title: 'Как играть?')),
            _HelpGroup(title: 'Основное', topics: main),
            _HelpGroup(title: 'Инвестиции', topics: investment),
            SliverToBoxAdapter(child: SizedBox(height: _ui(context, 28))),
          ],
        ),
      ),
    );
  }
}

class _HelpGroup extends StatelessWidget {
  const _HelpGroup({required this.title, required this.topics});

  final String title;
  final List<HowToTopic> topics;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: _uiInsets(context, const EdgeInsets.fromLTRB(32, 24, 32, 0)),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: _ui(context, 20)),
          for (final topic in topics)
            Padding(
              padding: _uiInsets(context, const EdgeInsets.only(bottom: 16)),
              child: _HelpListTile(topic: topic),
            ),
        ]),
      ),
    );
  }
}

class _HelpListTile extends StatelessWidget {
  const _HelpListTile({required this.topic});

  final HowToTopic topic;

  @override
  Widget build(BuildContext context) {
    final radius = _ui(context, 22);
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => HowToDetailScreen(topic: topic)),
      ),
      child: Container(
        height: _ui(context, 106),
        padding: _uiInsets(context, const EdgeInsets.symmetric(horizontal: 30)),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F6),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Row(
          children: [
            Icon(topic.icon, color: topic.color, size: _ui(context, 50)),
            SizedBox(width: _ui(context, 26)),
            Expanded(
              child: Text(
                topic.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HowToDetailScreen extends StatelessWidget {
  const HowToDetailScreen({super.key, required this.topic});

  final HowToTopic topic;

  @override
  Widget build(BuildContext context) {
    final index = howToTopics.indexOf(topic);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: _uiInsets(
            context,
            const EdgeInsets.fromLTRB(32, 22, 32, 24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    color: const Color(0xFFF3F4F7),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: _ui(context, 28)),
                  Expanded(
                    child: _DotsIndicator(
                      count: howToTopics.length,
                      index: max(0, index),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _ui(context, 52)),
              Text(
                topic.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: _ui(context, 24)),
              Text(topic.body, style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              Center(child: _HelpIllustration(topic: topic)),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: _PlainButton(
                      label: 'Назад',
                      enabled: index > 0,
                      onPressed: () {
                        if (index > 0) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => HowToDetailScreen(
                                topic: howToTopics[index - 1],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  SizedBox(width: _ui(context, 14)),
                  Expanded(
                    child: _GradientButton(
                      label: index == howToTopics.length - 1
                          ? 'Готово'
                          : 'Дальше',
                      onPressed: () {
                        if (index == howToTopics.length - 1) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => HowToDetailScreen(
                                topic: howToTopics[index + 1],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpTopBar extends StatelessWidget {
  const _HelpTopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _uiInsets(context, const EdgeInsets.fromLTRB(32, 22, 32, 20)),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFFF3F4F7),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          SizedBox(width: _ui(context, 62)),
        ],
      ),
    );
  }
}

class HowToTopic {
  const HowToTopic({
    required this.group,
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String group;
  final String title;
  final String body;
  final IconData icon;
  final Color color;
}

const List<HowToTopic> howToTopics = [
  HowToTopic(
    group: 'Основное',
    title: 'Цель',
    body:
        'Цель игры — за несколько игровых лет приумножить капитал и не потерять качество жизни. Деньги важны, но итог засчитывается только при достаточном уровне радости.',
    icon: Icons.track_changes_rounded,
    color: Color(0xFF9D7AE2),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Радость',
    body:
        'Радость измеряется по шкале от 1 до 100. Если она падает слишком низко, зарплата и итоговый результат страдают. Поддерживайте радость покупками и отдыхом.',
    icon: Icons.sentiment_satisfied_alt_rounded,
    color: Color(0xFFB66BE6),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Ход игры',
    body:
        'Каждый ход — один год жизни. Вы получаете зарплату, оплачиваете расходы, принимаете решения по обучению, страховке, покупкам и инвестициям.',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFFB66BE6),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Расходы',
    body:
        'Каждый год нужно оплатить минимальные расходы на жизнь: еду, жильё, транспорт и одежду. Базовая сумма — 300 000 ₽, а в следующие годы она растёт вместе с инфляцией.',
    icon: Icons.point_of_sale_rounded,
    color: Color(0xFFB66BE6),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Необязательные расходы',
    body:
        'После обязательных расходов появляются случайные предложения года. Их можно оплатить или отклонить: часть решений повышает радость, а отказ от важных покупок может её снизить.',
    icon: Icons.pets_rounded,
    color: Color(0xFFB66BE6),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Образование',
    body:
        'Образование повышает зарплату на все следующие годы. Чем раньше вложиться в навыки, тем больше ходов вы будете получать повышенный доход.',
    icon: Icons.school_rounded,
    color: Color(0xFFB66BE6),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Страховка',
    body:
        'Страховка помогает пережить неприятные события. Полис действует один игровой год и снижает расходы при ремонте, лечении или других внезапных проблемах.',
    icon: Icons.car_crash_rounded,
    color: Color(0xFFB66BE6),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Завершение хода',
    body:
        'После завершения года игра покажет сводку: зарплату, доходность инвестиций, инфляцию, случайные события и изменение вашего капитала.',
    icon: Icons.check_circle_rounded,
    color: Color(0xFF9D7AE2),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Инфляция',
    body:
        'Инфляция показывает, насколько выросли цены. Чем она выше, тем дороже становятся обязательные расходы и покупки в следующих ходах.',
    icon: Icons.percent_rounded,
    color: Color(0xFFB66BE6),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Случайные события',
    body:
        'Каждый год могут произойти неожиданные события: премия, ремонт, лечение или удачный проект. Страховка снижает удар от плохих событий.',
    icon: Icons.theater_comedy_rounded,
    color: Color(0xFF9D7AE2),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Результат игры',
    body:
        'Результат — ваш итоговый капитал: свободные деньги плюс инвестиции минус долги. Он засчитывается только при приемлемом уровне радости.',
    icon: Icons.calculate_rounded,
    color: Color(0xFF8ACB88),
  ),
  HowToTopic(
    group: 'Основное',
    title: 'Кредит',
    body:
        'Банковский кредит даёт деньги сейчас, но каждый год требует платежа с процентом. Сумма, лимит и срок зависят от банка и сложности игры.',
    icon: Icons.credit_score_rounded,
    color: Color(0xFFB66BE6),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Инвестиции',
    body:
        'Инвестиции позволяют увеличить капитал за счёт разных финансовых инструментов. У каждого инструмента своя доходность, риск и реакция на новости.',
    icon: Icons.business_center_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Акции',
    body:
        'Акция — доля в бизнесе. Если компания растёт, цена может сильно увеличиться. Если дела идут плохо, можно потерять значительную часть вложений.',
    icon: Icons.area_chart_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Дивиденды',
    body:
        'Некоторые компании делятся прибылью с инвесторами. В игре это отражено через среднюю доходность и ежегодное изменение стоимости актива.',
    icon: Icons.percent_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Облигации',
    body:
        'Покупая облигацию, вы как будто даёте деньги в долг компании или государству. Каждый ход облигация выплачивает купон деньгами на баланс, а вложенная сумма остаётся прежней, если не случится дефолт.',
    icon: Icons.thumb_up_alt_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Криптовалюта',
    body:
        'Криптовалюта может резко вырасти или резко упасть. При тревожных новостях монета может обвалиться до нуля, и вложения полностью сгорят.',
    icon: Icons.currency_bitcoin_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Вклады',
    body:
        'Вклад — деньги, которые вы отдаёте банку под процент. Это спокойный инструмент: доход ниже, зато риск меньше.',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Процент по вкладам',
    body:
        'Проценты начисляются раз в год. Если не выводить деньги, сумма растёт вместе с начисленными процентами.',
    icon: Icons.percent_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Страхование вкладов',
    body:
        'В игре вклады считаются более защищёнными активами. При неприятных событиях они теряют меньше, чем рискованные проекты.',
    icon: Icons.verified_user_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Прочие инвестиции',
    body:
        'Прочие инвестиции дают большие обещания, но чаще всего имеют высокий риск. Они подходят для небольших долей портфеля.',
    icon: Icons.rocket_launch_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Банкротство',
    body:
        'Некоторые вложения могут обнулиться из-за банкротства проекта. Чем рискованнее инструмент, тем выше вероятность такого события.',
    icon: Icons.thumb_down_alt_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Новости',
    body:
        'Новости меняют ожидания по рынку. Читайте финансовую ленту перед вложениями: она подсказывает, какие компании могут выиграть или проиграть.',
    icon: Icons.newspaper_rounded,
    color: Color(0xFF7CB4DF),
  ),
  HowToTopic(
    group: 'Инвестиции',
    title: 'Банковские карты',
    body:
        'Карты дают бонусы и требуют ежегодного обслуживания. Кредитная карта отдельно добавляет 300 000 ₽ на баланс и списывает долг каждый год равными платежами без процентов.',
    icon: Icons.credit_card_rounded,
    color: Color(0xFF7CB4DF),
  ),
];

class _HelpIllustration extends StatelessWidget {
  const _HelpIllustration({required this.topic});

  final HowToTopic topic;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ui(context, 270),
      height: _ui(context, 220),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: _ui(context, 24),
            left: _ui(context, 10),
            right: _ui(context, 10),
            child: Container(
              height: _ui(context, 2),
              color: const Color(0xFF30303A),
            ),
          ),
          Container(
            width: _ui(context, 180),
            height: _ui(context, 140),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_ui(context, 28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: _ui(context, 28),
                  offset: Offset(0, _ui(context, 18)),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(topic.icon, color: topic.color, size: _ui(context, 52)),
                SizedBox(height: _ui(context, 14)),
                Text(
                  topic.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: _ui(context, 7),
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: _ui(context, 12),
            height: _ui(context, 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == index
                  ? const Color(0xFFB6B6B6)
                  : const Color(0xFFE4E4E4),
            ),
          ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.color = Colors.white,
    this.iconColor = Colors.black,
    this.size = 62,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scaledSize = _ui(context, size);
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: scaledSize,
          height: scaledSize,
          child: Icon(icon, color: iconColor, size: scaledSize * 0.52),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final radius = _ui(context, 20);
    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF67C89B), Color(0xFFD6F37C)],
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              width: double.infinity,
              height: _ui(context, 70),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: _ui(context, 24)),
                    SizedBox(width: _ui(context, 10)),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlainButton extends StatelessWidget {
  const _PlainButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _ui(context, 64),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF0F1F5),
          disabledBackgroundColor: const Color(0xFFF4F5F8),
          foregroundColor: Colors.black,
          disabledForegroundColor: const Color(0xFFB8BAC0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ui(context, 14)),
          ),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          elevation: 0,
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(label),
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  const _CompactButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _ui(context, 58),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF0F1F5),
          disabledBackgroundColor: const Color(0xFFF7F8FA),
          foregroundColor: Colors.black,
          disabledForegroundColor: const Color(0xFFC7C9CF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ui(context, 14)),
          ),
          textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          elevation: 0,
        ),
        onPressed: enabled ? onPressed : null,
        child: FittedBox(child: Text(label)),
      ),
    );
  }
}

class _SmallPlainButton extends StatelessWidget {
  const _SmallPlainButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ui(context, 116),
      height: _ui(context, 50),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFF5F5F7),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_ui(context, 10)),
          ),
          textStyle: const TextStyle(fontSize: 16),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class _MenuGradientTile extends StatelessWidget {
  const _MenuGradientTile({
    required this.title,
    required this.icon,
    required this.colors,
    required this.height,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final List<Color> colors;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = _ui(context, 22);
    final compact = height < 110;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child: Ink(
          height: _ui(context, height),
          padding: _uiInsets(
            context,
            compact
                ? const EdgeInsets.symmetric(horizontal: 26, vertical: 20)
                : const EdgeInsets.all(28),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: compact
              ? Row(
                  children: [
                    Icon(icon, color: Colors.white, size: _ui(context, 32)),
                    SizedBox(width: _ui(context, 16)),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: Colors.white, size: _ui(context, 34)),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = _ui(context, 20);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child: Ink(
          height: _ui(context, 150),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Center(
            child: Padding(
              padding: _uiInsets(
                context,
                const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: _ui(context, 6)),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _uiInsets(context, const EdgeInsets.all(32)),
      child: Container(
        padding: _uiInsets(context, const EdgeInsets.all(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_ui(context, 24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children
              .map(
                (child) => Padding(
                  padding: _uiInsets(
                    context,
                    const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: child,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.colors,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final gradient = colors;
    final radius = _ui(context, 16);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onPressed,
        child: Ink(
          height: _ui(context, 76),
          decoration: BoxDecoration(
            color: gradient == null ? const Color(0xFFF0F1F5) : null,
            gradient: gradient == null
                ? null
                : LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: gradient == null ? Colors.black : Colors.white,
                size: _ui(context, 28),
              ),
              SizedBox(width: _ui(context, 12)),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: gradient == null ? Colors.black : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameLogo extends StatelessWidget {
  const _GameLogo({this.size = 92});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scaledSize = _ui(context, size);
    return Transform.rotate(
      angle: -0.18,
      child: Container(
        width: scaledSize,
        height: scaledSize * 0.72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5E36A), Color(0xFF62C899), Color(0xFF4CC7EE)],
          ),
          borderRadius: BorderRadius.circular(scaledSize * 0.18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF62C899).withValues(alpha: 0.22),
              blurRadius: _ui(context, 24),
              offset: Offset(0, _ui(context, 14)),
            ),
          ],
        ),
        child: Icon(
          Icons.sports_esports_rounded,
          color: Colors.white,
          size: scaledSize * 0.48,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final first = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return CircleAvatar(
      radius: _ui(context, 34),
      backgroundColor: const Color(0xFF23272F),
      child: Text(
        first,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _ui(context, 68),
      height: _ui(context, 68),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, color: Colors.white, size: _ui(context, 36)),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 28}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ],
  );
}

TextStyle? _mutedLabel(BuildContext context) {
  return Theme.of(
    context,
  ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF777D88));
}

String _money(num value) {
  final rounded = value.round();
  final negative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buffer ₽';
}

double _parseMoneyInput(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return 0;
  }
  return double.tryParse(digits) ?? 0;
}

String _yearsWord(int years) {
  final lastTwo = years % 100;
  final last = years % 10;
  if (lastTwo >= 11 && lastTwo <= 14) {
    return 'лет';
  }
  if (last == 1) {
    return 'год';
  }
  if (last >= 2 && last <= 4) {
    return 'года';
  }
  return 'лет';
}

String _percent(double value) {
  final percentage = value * 100;
  final rounded = percentage.toStringAsFixed(
    percentage.truncateToDouble() == percentage ? 0 : 1,
  );
  return '$rounded%';
}
