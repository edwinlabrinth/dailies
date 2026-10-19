/// Compact XP / HP numbers: 842 stays `842`, 2800 becomes `2.8k`.
String formatXp(int value) {
  final abs = value.abs();
  if (abs < 1000) return '$value';
  final thousands = value / 1000;
  final digits = thousands.abs() >= 100 ? 0 : 1;
  var text = thousands.toStringAsFixed(digits);
  if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
  return '${text}k';
}
