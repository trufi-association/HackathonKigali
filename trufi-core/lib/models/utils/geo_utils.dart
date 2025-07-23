import 'package:intl/intl.dart';

NumberFormat formatTwoDecimals({String? localeName}) {
  return NumberFormat('#.00', localeName ?? 'en');
}

NumberFormat formatOneDecimals({String? localeName}) {
  return NumberFormat('#.0', localeName ?? 'en');
}

NumberFormat formatZeroDecimals({String? localeName}) {
  return NumberFormat('#', localeName ?? 'en');
}
