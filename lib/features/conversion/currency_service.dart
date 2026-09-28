class ConversionService {
  // Base currency: USD
  // Rates relative to 1 USD
  static final Map<String, double> defaultRates = {
    'USD': 1.0,
    'IDR': 16250.0,
    'EUR': 0.92,
    'JPY': 155.40,
    'SOL': 0.00714, // ~ $140/SOL
    'SGD': 1.35,
    'GBP': 0.79,
  };

  /// Normalizes input string to handle comma/dot separators
  static double? parseAmount(String input) {
    if (input.trim().isEmpty) return 0.0;
    final normalized = input.replaceAll(',', '.').trim();
    return double.tryParse(normalized);
  }

  /// Converts an amount from source currency to target currency.
  /// Anti-crash defense against NaN/Infinite/Negative numbers.
  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    Map<String, double>? customRates,
  }) {
    if (amount.isNaN || amount.isInfinite || amount < 0) {
      return 0.0;
    }

    final rates = customRates ?? defaultRates;
    final fromRate = rates[fromCurrency.toUpperCase()] ?? 1.0;
    final toRate = rates[toCurrency.toUpperCase()] ?? 1.0;

    if (fromRate <= 0 || toRate <= 0) return 0.0;

    // Convert from -> USD -> to
    final amountInUSD = amount / fromRate;
    final converted = amountInUSD * toRate;

    if (converted.isNaN || converted.isInfinite) return 0.0;
    return converted;
  }

  /// Formats currency with sensible decimal places
  static String formatCurrency(double value, String currency) {
    if (currency.toUpperCase() == 'IDR' || currency.toUpperCase() == 'JPY') {
      return value.toStringAsFixed(0);
    } else if (currency.toUpperCase() == 'SOL') {
      return value.toStringAsFixed(6);
    } else {
      return value.toStringAsFixed(2);
    }
  }
}
