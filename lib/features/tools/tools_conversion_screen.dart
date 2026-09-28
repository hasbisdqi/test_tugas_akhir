import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme/app_theme.dart';

class ToolsConversionScreen extends StatefulWidget {
  const ToolsConversionScreen({super.key});

  @override
  State<ToolsConversionScreen> createState() => _ToolsConversionScreenState();
}

class _ToolsConversionScreenState extends State<ToolsConversionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 1. Currency Conversion State
  final _amountController = TextEditingController(text: '100000');
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _convertedResult = 0.0;

  // Base rates normalized to 1 USD
  final Map<String, double> _ratesToUsd = {
    'USD': 1.0,
    'IDR': 15800.0,
    'EUR': 0.92,
    'JPY': 152.5,
    'SOL': 0.00688, // 1 SOL = ~145.34 USD -> 1 USD = ~0.00688 SOL
  };

  // 2. Timezone Converter State
  Timer? _timer;
  DateTime _currentUtc = DateTime.now().toUtc();

  // 3. Sensor Leveler State
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;
  double _accX = 0.0;
  double _accY = 0.0;
  double _accZ = 0.0;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;

  // 4. LBS / GPS Distance State
  Position? _currentPosition;
  bool _isLoadingGps = false;
  String? _gpsError;

  // Reference points (e.g. UPN Veteran Yogyakarta & Agro Central Hub)
  final double _refLat = -7.7794; // UPNYK Campus
  final double _refLng = 110.4162;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _calculateCurrency();

    // Time ticker
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentUtc = DateTime.now().toUtc();
        });
      }
    });

    // Sensor listeners
    _accelerometerSub = accelerometerEventStream().listen((event) {
      if (mounted) {
        setState(() {
          _accX = event.x;
          _accY = event.y;
          _accZ = event.z;
        });
      }
    });

    _gyroscopeSub = gyroscopeEventStream().listen((event) {
      if (mounted) {
        setState(() {
          _gyroX = event.x;
          _gyroY = event.y;
          _gyroZ = event.z;
        });
      }
    });

    // Auto-fetch GPS on load
    _fetchGpsLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _timer?.cancel();
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
    super.dispose();
  }

  void _calculateCurrency() {
    final raw = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(raw);
    if (amount == null || amount.isNaN || amount.isInfinite || amount < 0) {
      setState(() => _convertedResult = 0.0);
      return;
    }

    final fromRate = _ratesToUsd[_fromCurrency] ?? 1.0;
    final toRate = _ratesToUsd[_toCurrency] ?? 1.0;

    // Convert amount -> USD -> target currency
    final inUsd = amount / fromRate;
    final result = inUsd * toRate;

    setState(() {
      _convertedResult = result;
    });
  }

  Future<void> _fetchGpsLocation() async {
    setState(() {
      _isLoadingGps = true;
      _gpsError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _gpsError = 'Location services are disabled on device';
          _isLoadingGps = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsError = 'Location permissions are denied';
            _isLoadingGps = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsError = 'Location permissions are permanently denied';
          _isLoadingGps = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      final distanceMeters = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        _refLat,
        _refLng,
      );

      setState(() {
        _currentPosition = pos;
        _distanceKm = distanceMeters / 1000.0;
        _isLoadingGps = false;
      });
    } catch (e) {
      setState(() {
        _gpsError = e.toString();
        _isLoadingGps = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools & Converters'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          tabs: const [
            Tab(icon: Icon(Icons.currency_exchange_rounded), text: 'Currency'),
            Tab(icon: Icon(Icons.access_time_filled_rounded), text: 'Timezone'),
            Tab(icon: Icon(Icons.screen_rotation_rounded), text: 'Sensors / Level'),
            Tab(icon: Icon(Icons.location_on_rounded), text: 'LBS / GPS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrencyTab(),
          _buildTimezoneTab(),
          _buildSensorsTab(),
          _buildGpsTab(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: Multi-Currency Converter (IDR, USD, EUR, JPY, SOL)
  // -------------------------------------------------------------
  Widget _buildCurrencyTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyList = ['IDR', 'USD', 'EUR', 'JPY', 'SOL'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E2621), const Color(0xFF0F381E)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Text(
                  'CONVERTED ESTIMATE',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                Text(
                  _toCurrency == 'IDR'
                      ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2).format(_convertedResult)
                      : _toCurrency == 'SOL'
                          ? '${_convertedResult.toStringAsFixed(6)} SOL'
                          : NumberFormat.currency(symbol: '$_toCurrency ', decimalDigits: 2).format(_convertedResult),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppTheme.accentGreen : AppTheme.primaryGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Amount Input
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Input Amount',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
            onChanged: (_) => _calculateCurrency(),
          ),
          const SizedBox(height: 16),

          // From & To Selectors
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _fromCurrency,
                  decoration: const InputDecoration(labelText: 'From Currency'),
                  items: currencyList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _fromCurrency = val);
                      _calculateCurrency();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () {
                  setState(() {
                    final temp = _fromCurrency;
                    _fromCurrency = _toCurrency;
                    _toCurrency = temp;
                  });
                  _calculateCurrency();
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _toCurrency,
                  decoration: const InputDecoration(labelText: 'To Currency'),
                  items: currencyList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _toCurrency = val);
                      _calculateCurrency();
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          const Text(
            'Live Exchange Reference Rates (1 USD Base)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildRateRow('1 USD', '15,800.00 IDR'),
          _buildRateRow('1 USD', '0.92 EUR'),
          _buildRateRow('1 USD', '152.50 JPY'),
          _buildRateRow('1 USD', '0.00688 SOL (~145.34 USD/SOL)'),
        ],
      ),
    );
  }

  Widget _buildRateRow(String from, String to) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(from, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(to, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: Timezone Converter (WIB, WITA, WIT, London GMT)
  // -------------------------------------------------------------
  Widget _buildTimezoneTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wibTime = _currentUtc.add(const Duration(hours: 7));
    final witaTime = _currentUtc.add(const Duration(hours: 8));
    final witTime = _currentUtc.add(const Duration(hours: 9));
    final gmtTime = _currentUtc;

    final timeFmt = DateFormat('HH:mm:ss');
    final dateFmt = DateFormat('EEE, dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Real-Time International Agro Clocks',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _buildClockCard(
            zoneName: 'WIB (Western Indonesia Time)',
            utcOffset: 'UTC+7',
            location: 'Jakarta, Yogyakarta, Sumatra',
            time: timeFmt.format(wibTime),
            date: dateFmt.format(wibTime),
            icon: Icons.wb_sunny_rounded,
            color: Colors.green,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildClockCard(
            zoneName: 'WITA (Central Indonesia Time)',
            utcOffset: 'UTC+8',
            location: 'Bali, Makassar, Kalimantan',
            time: timeFmt.format(witaTime),
            date: dateFmt.format(witaTime),
            icon: Icons.wb_twilight_rounded,
            color: Colors.teal,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildClockCard(
            zoneName: 'WIT (Eastern Indonesia Time)',
            utcOffset: 'UTC+9',
            location: 'Papua, Maluku Agro Zone',
            time: timeFmt.format(witTime),
            date: dateFmt.format(witTime),
            icon: Icons.wb_cloudy_rounded,
            color: Colors.orange,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          _buildClockCard(
            zoneName: 'London GMT / UTC',
            utcOffset: 'UTC+0',
            location: 'London Commodity Exchange (LCE)',
            time: timeFmt.format(gmtTime),
            date: dateFmt.format(gmtTime),
            icon: Icons.public_rounded,
            color: Colors.blue,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildClockCard({
    required String zoneName,
    required String utcOffset,
    required String location,
    required String time,
    required String date,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2621) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(zoneName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        utcOffset,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                  ],
                ),
                Text(location, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: Dual Sensors (Accelerometer + Gyroscope Live Leveler)
  // -------------------------------------------------------------
  Widget _buildSensorsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate Pitch and Roll from Accelerometer
    final pitch = math.atan2(-_accX, math.sqrt(_accY * _accY + _accZ * _accZ)) * 180 / math.pi;
    final roll = math.atan2(_accY, _accZ) * 180 / math.pi;

    // Constrain bubble position
    final bubbleX = (_accX.clamp(-5.0, 5.0) / 5.0) * -80.0;
    final bubbleY = (_accY.clamp(-5.0, 5.0) / 5.0) * 80.0;
    final isBalanced = _accX.abs() < 0.4 && _accY.abs() < 0.4;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Agricultural Soil & Tractor Tilt Leveler',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live Hardware Accelerometer & Gyroscope Feed',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Visual Bubble Leveler
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E2621) : const Color(0xFFE8F5E9),
                    border: Border.all(
                      color: isBalanced ? Colors.green : Colors.amber.shade700,
                      width: 4,
                    ),
                  ),
                ),
                // Center target ring
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isBalanced ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                  ),
                ),
                // Moving Bubble Indicator
                Transform.translate(
                  offset: Offset(bubbleX, bubbleY),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isBalanced ? Colors.green : Colors.amber.shade700,
                      boxShadow: [
                        BoxShadow(
                          color: (isBalanced ? Colors.green : Colors.amber).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isBalanced ? Icons.check : Icons.radio_button_checked,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              isBalanced ? 'LEVEL BALANCED (0° TILT)' : 'TILT DETECTED',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isBalanced ? Colors.green : Colors.amber.shade800,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sensor 1: Accelerometer Values
          _buildSensorDataCard(
            title: '1. Accelerometer (Linear Force m/s²)',
            icon: Icons.swap_vert_circle_outlined,
            color: Colors.green,
            isDark: isDark,
            items: [
              'X (Lateral): ${_accX.toStringAsFixed(2)} m/s²',
              'Y (Longitudinal): ${_accY.toStringAsFixed(2)} m/s²',
              'Z (Vertical): ${_accZ.toStringAsFixed(2)} m/s²',
              'Pitch: ${pitch.toStringAsFixed(1)}° | Roll: ${roll.toStringAsFixed(1)}°',
            ],
          ),
          const SizedBox(height: 14),

          // Sensor 2: Gyroscope Values
          _buildSensorDataCard(
            title: '2. Gyroscope (Angular Rate rad/s)',
            icon: Icons.rotate_right_rounded,
            color: Colors.blueAccent,
            isDark: isDark,
            items: [
              'Rot X: ${_gyroX.toStringAsFixed(3)} rad/s',
              'Rot Y: ${_gyroY.toStringAsFixed(3)} rad/s',
              'Rot Z: ${_gyroZ.toStringAsFixed(3)} rad/s',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorDataCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2621) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Divider(height: 18),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                item,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: LBS / GPS Distance & Geolocation
  // -------------------------------------------------------------
  Widget _buildGpsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'GPS Location & Agro Parcel Distance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Location Based Service (LBS) for farm radius & logistics',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Current Coordinates Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2621) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.my_location_rounded, color: AppTheme.primaryGreen),
                        SizedBox(width: 8),
                        Text('Current Device Location', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_isLoadingGps)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: _fetchGpsLocation,
                      ),
                  ],
                ),
                const Divider(height: 18),
                if (_gpsError != null)
                  Text(
                    'GPS Warning / Note: $_gpsError\n(Check device location permission / desktop mock)',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  )
                else if (_currentPosition != null) ...[
                  Text('Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}'),
                  const SizedBox(height: 4),
                  Text('Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}'),
                  const SizedBox(height: 4),
                  Text('Altitude: ${_currentPosition!.altitude.toStringAsFixed(1)} m ASL'),
                  const SizedBox(height: 4),
                  Text('Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)} m'),
                ] else
                  const Text('Fetching GPS fix...'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Distance to Reference Hub
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E2621), const Color(0xFF1A3326)]
                    : [const Color(0xFFE0F2F1), const Color(0xFFB2DFDB)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.hub_rounded, color: Color(0xFF00796B)),
                    SizedBox(width: 8),
                    Text(
                      'Distance to Central Agro Hub (UPNYK Campus)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Reference Point: Lat -7.779400, Lng 110.416200',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _distanceKm != null ? _distanceKm!.toStringAsFixed(2) : '--',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00796B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Kilometers',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00796B)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchGpsLocation,
            icon: const Icon(Icons.gps_fixed_rounded),
            label: const Text('RE-CALCULATE GPS DISTANCE'),
          ),
        ],
      ),
    );
  }
}
