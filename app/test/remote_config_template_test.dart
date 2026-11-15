import 'dart:convert';
import 'dart:io';

import 'package:flow_sort/services/remote_config_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The server template published to Firebase must carry the same keys and
/// values as the app's built-in defaults, so a fresh install and a fetched
/// config behave the same until someone tunes a value on purpose.
void main() {
  test('firebase/remoteconfig.template.json matches the app defaults', () {
    final json =
        jsonDecode(
              File('../firebase/remoteconfig.template.json').readAsStringSync(),
            )
            as Map<String, Object?>;
    final server = <String, String>{};
    for (final group
        in (json['parameterGroups']! as Map<String, Object?>).values) {
      final params =
          (group! as Map<String, Object?>)['parameters']!
              as Map<String, Object?>;
      for (final MapEntry(:key, :value) in params.entries) {
        final dv = (value! as Map<String, Object?>)['defaultValue']!;
        server[key] = (dv as Map<String, Object?>)['value']! as String;
      }
    }
    expect(server, remoteConfigDefaults);
  });
}
