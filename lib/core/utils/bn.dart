const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

/// Converts Latin digits to Bengali digits (e.g. 114 -> ১১৪).
String bn(Object value) => value
    .toString()
    .split('')
    .map((c) {
      final d = int.tryParse(c);
      return d == null ? c : _bnDigits[d];
    })
    .join();
