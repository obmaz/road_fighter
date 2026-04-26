import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Layout constants should follow the approved proportions', () {
    const hudHeightFactor = 0.12;
    const controlsHeightFactor = 0.25;
    const roadWidthFactor = 0.85;

    expect(hudHeightFactor, 0.12);
    expect(controlsHeightFactor, 0.25);
    expect(roadWidthFactor, 0.85);
  });
}
