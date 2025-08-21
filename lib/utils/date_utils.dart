import 'package:intl/intl.dart';

class AppDateUtils {
  static String ymd(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);
}
