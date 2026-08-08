/// Computes age in whole years as of [now], from a date of birth.
///
/// Pure function so it is directly unit-testable without a clock or widget.
/// The caller decides what to do with the result; this never persists or
/// reads the date of birth anywhere.
int calculateAge(DateTime dateOfBirth, DateTime now) {
  var age = now.year - dateOfBirth.year;
  final hadBirthdayThisYear = now.month > dateOfBirth.month ||
      (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
  if (!hadBirthdayThisYear) age -= 1;
  return age;
}

const int kMinimumAge = 17;
