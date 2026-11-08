import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/utils/phone_format.dart';

void main() {
  test('shows a Nigerian mobile number as 4-3-4', () {
    expect(PhoneFormat.nationalDisplay('+2348035550142'), '0803 555 0142');
    expect(PhoneFormat.nationalDisplay('2348035550142'), '0803 555 0142');
    expect(PhoneFormat.nationalDisplay('08035550142'), '0803 555 0142');
    expect(PhoneFormat.nationalDisplay('+234 803 555 0142'), '0803 555 0142');
  });

  test('leaves anything that is not a Nigerian mobile number alone', () {
    expect(PhoneFormat.nationalDisplay('+44 20 7946 0958'), '+44 20 7946 0958');
    expect(PhoneFormat.nationalDisplay('not a number'), 'not a number');
    expect(PhoneFormat.nationalDisplay(null), '');
  });

  test('form fields keep the ten digits after +234 and store the prefix', () {
    expect(PhoneFormat.digitsAfterPrefix('0803 555 0142'), '8035550142');
    expect(PhoneFormat.digitsAfterPrefix('2348035550142'), '8035550142');
    expect(PhoneFormat.stored('0803 555 0142'), '+2348035550142');
    expect(PhoneFormat.stored('+2348035550142'), '+2348035550142');
    expect(PhoneFormat.stored(''), isNull);
    expect(PhoneFormat.problem('803'), isNotNull);
    expect(PhoneFormat.problem('8035550142'), isNull);
  });
}
