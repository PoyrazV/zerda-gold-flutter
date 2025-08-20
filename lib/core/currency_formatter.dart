import 'package:intl/intl.dart';

/// Turkish Currency Formatting Utility
/// 
/// This class provides consistent currency formatting throughout the ZerdaGold application
/// using Turkish number format conventions:
/// - Thousands separator: . (dot)
/// - Decimal separator: , (comma)
/// - Example: 1.240.00,75 TRY instead of 1,240.00
class CurrencyFormatter {
  static final NumberFormat _turkishFormatter = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '',
    decimalDigits: 2,
  );

  static final NumberFormat _turkishFormatterWithoutDecimals = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '',
    decimalDigits: 0,
  );

  static final NumberFormat _turkishFormatter4Decimals = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '',
    decimalDigits: 4,
  );

  static final NumberFormat _turkishPercentageFormatter = NumberFormat.decimalPattern('tr_TR');

  /// Formats currency with Turkish Lira symbol and 2 decimal places
  /// Example: 1.240,50 → ₺1.240,50
  static String formatTRY(double amount, {int? decimalPlaces}) {
    if (decimalPlaces != null) {
      final formatter = NumberFormat.currency(
        locale: 'tr_TR',
        symbol: '',
        decimalDigits: decimalPlaces,
      );
      return '₺${formatter.format(amount)}';
    }
    return '₺${_turkishFormatter.format(amount)}';
  }

  /// Formats currency with US Dollar symbol and appropriate decimal places
  /// Example: 1,240.50 → \$1.240,50 (using Turkish separators)
  static String formatUSD(double amount, {int decimalPlaces = 4}) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '',
      decimalDigits: decimalPlaces,
    );
    return '\$${formatter.format(amount)}';
  }

  /// Formats currency with Euro symbol and appropriate decimal places
  /// Example: 1,240.50 → €1.240,50 (using Turkish separators)
  static String formatEUR(double amount, {int decimalPlaces = 4}) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '',
      decimalDigits: decimalPlaces,
    );
    return '€${formatter.format(amount)}';
  }

  /// Formats currency with custom symbol and decimal places
  /// Example: formatWithSymbol(1240.50, '£', 2) → £1.240,50
  static String formatWithSymbol(double amount, String symbol, {int decimalPlaces = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '',
      decimalDigits: decimalPlaces,
    );
    return '$symbol${formatter.format(amount)}';
  }

  /// Formats percentage with Turkish decimal separator
  /// Example: 12.34 → %12,34
  static String formatPercentage(double percentage, {int decimalPlaces = 2}) {
    final formatter = NumberFormat.decimalPattern('tr_TR');
    formatter.minimumFractionDigits = decimalPlaces;
    formatter.maximumFractionDigits = decimalPlaces;
    return '%${formatter.format(percentage)}';
  }

  /// Formats percentage with + or - prefix for gains/losses
  /// Example: 12.34 → +%12,34, -5.67 → -%5,67
  static String formatPercentageChange(double percentage, {int decimalPlaces = 2}) {
    final formatter = NumberFormat.decimalPattern('tr_TR');
    formatter.minimumFractionDigits = decimalPlaces;
    formatter.maximumFractionDigits = decimalPlaces;
    final isPositive = percentage >= 0;
    return '${isPositive ? '+' : ''}${formatter.format(percentage)}%';
  }

  /// Formats plain number with Turkish separators (no currency symbol)
  /// Example: 1240.50 → 1.240,50
  static String formatNumber(double amount, {int decimalPlaces = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '',
      decimalDigits: decimalPlaces,
    );
    return formatter.format(amount);
  }

  /// Formats exchange rate with appropriate decimal places
  /// For values >= 1000: 2 decimal places, otherwise 4 decimal places
  /// Example: 1041.8027 → 1.041,80, 34.1234 → 34,1234
  static String formatExchangeRate(double rate) {
    if (rate >= 1000) {
      return _turkishFormatter.format(rate); // 2 decimal places for thousands
    } else {
      return _turkishFormatter4Decimals.format(rate); // 4 decimal places for smaller values
    }
  }

  /// Formats currency based on currency code
  /// Supports: TRY, USD, EUR, GBP, CHF, CAD, AUD, JPY
  static String formatCurrency(double amount, String currencyCode, {int? decimalPlaces}) {
    switch (currencyCode.toUpperCase()) {
      case 'TRY':
      case 'TL':
        return formatTRY(amount, decimalPlaces: decimalPlaces);
      case 'USD':
        return formatUSD(amount, decimalPlaces: decimalPlaces ?? 4);
      case 'EUR':
        return formatEUR(amount, decimalPlaces: decimalPlaces ?? 4);
      case 'GBP':
        return formatWithSymbol(amount, '£', decimalPlaces: decimalPlaces ?? 4);
      case 'CHF':
        return formatWithSymbol(amount, 'CHF ', decimalPlaces: decimalPlaces ?? 4);
      case 'CAD':
        return formatWithSymbol(amount, 'C\$', decimalPlaces: decimalPlaces ?? 4);
      case 'AUD':
        return formatWithSymbol(amount, 'A\$', decimalPlaces: decimalPlaces ?? 4);
      case 'JPY':
        return formatWithSymbol(amount, '¥', decimalPlaces: decimalPlaces ?? 0);
      default:
        return formatWithSymbol(amount, currencyCode + ' ', decimalPlaces: decimalPlaces ?? 2);
    }
  }

  /// Legacy support for existing replaceAll('.', ',') patterns
  /// This method helps transition existing code to proper formatting
  static String legacyFormat(double amount, {int decimalPlaces = 2}) {
    return amount.toStringAsFixed(decimalPlaces).replaceAll('.', ',');
  }

  /// Formats price for display in tables and lists
  /// Uses appropriate decimal places based on the magnitude of the price
  static String formatDisplayPrice(double price) {
    if (price >= 10000) {
      return formatNumber(price, decimalPlaces: 0); // No decimals for high values
    } else if (price >= 1000) {
      return formatNumber(price, decimalPlaces: 1); // One decimal for thousands
    } else if (price >= 100) {
      return formatNumber(price, decimalPlaces: 2); // Two decimals for hundreds
    } else {
      return formatNumber(price, decimalPlaces: 4); // Four decimals for smaller values
    }
  }

  /// Formats price with smart decimal places based on integer part digits
  /// If integer part has 3 or 4 digits (100-9999), show 2 decimal places
  /// Otherwise use default 4 decimal places
  /// Example: 123.1040 → 123,10, 1234.1040 → 1.234,10, 12.1040 → 12,1040
  static String formatSmartPrice(double price, {int defaultDecimalPlaces = 4}) {
    int integerPart = price.truncate();
    int integerDigits = integerPart.toString().length;
    
    if (integerDigits == 3 || integerDigits == 4) {
      // 3 or 4 digits in integer part (100-9999): use 2 decimal places
      return formatNumber(price, decimalPlaces: 2);
    } else {
      // Otherwise use default decimal places
      return formatNumber(price, decimalPlaces: defaultDecimalPlaces);
    }
  }
}