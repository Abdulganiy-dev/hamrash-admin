import 'package:flutter_test/flutter_test.dart';
import 'package:hamrash_admin/core/constants/nigeria_locations.dart';

void main() {
  test('there are 36 states and the FCT, A-Z', () {
    final states = NigeriaLocations.states;
    expect(states, hasLength(37));
    expect(states.first, 'Abia');
    expect(states.last, 'Zamfara');
    expect(states, contains('Federal Capital Territory'));
    expect(states, orderedEquals([...states]..sort()));
  });

  test('all 774 LGAs are present', () {
    final total = NigeriaLocations.states
        .map((state) => NigeriaLocations.lgasOf(state).length)
        .fold(0, (sum, count) => sum + count);
    expect(total, 774);
  });

  test('no state repeats an LGA', () {
    for (final state in NigeriaLocations.states) {
      final lgas = NigeriaLocations.lgasOf(state);
      expect(lgas, isNotEmpty, reason: '$state has no LGAs');
      expect(
        lgas.toSet(),
        hasLength(lgas.length),
        reason: '$state repeats one',
      );
      expect(lgas, orderedEquals([...lgas]..sort()));
    }
  });

  test('every state/LGA pair is unique', () {
    final pairs = <String>{};
    for (final state in NigeriaLocations.states) {
      for (final lga in NigeriaLocations.lgasOf(state)) {
        expect(pairs.add('$state\u0000$lga'), isTrue, reason: '$state / $lga');
      }
    }
    expect(pairs, hasLength(774));
  });

  test('known LGAs and an unknown state', () {
    expect(NigeriaLocations.lgasOf('Lagos'), contains('Ikeja'));
    expect(NigeriaLocations.lgasOf('Federal Capital Territory'), hasLength(6));
    expect(NigeriaLocations.lgasOf('Atlantis'), isEmpty);
  });
}
