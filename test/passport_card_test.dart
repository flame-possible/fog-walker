import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fog_walker/models/user_profile.dart';
import 'package:fog_walker/widgets/passport_card.dart';

void main() {
  testWidgets('PassportCard displays effective profile name', (tester) async {
    final profile = UserProfile.initial()..displayName = 'Yang Walker';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PassportCard(profile: profile)),
      ),
    );

    expect(find.text('Yang Walker'), findsOneWidget);
  });
}
