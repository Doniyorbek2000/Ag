import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adm_ai/screens/legal_screen.dart';
import 'package:adm_ai/theme/app_theme.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(theme: AppTheme.darkTheme, home: child);

  testWidgets('privacy policy screen shows its title and section headings',
      (tester) async {
    await tester.pumpWidget(
        wrap(const LegalScreen(document: LegalDocument.privacyPolicy)));

    expect(find.text('Maxfiylik siyosati'), findsWidgets);
    expect(find.textContaining('Qanday ma\'lumotlar yig\'iladi'), findsOneWidget);
  });

  testWidgets('terms of use screen shows its title and section headings',
      (tester) async {
    await tester.pumpWidget(
        wrap(const LegalScreen(document: LegalDocument.termsOfUse)));

    expect(find.text('Foydalanish shartlari'), findsWidgets);
    expect(find.textContaining('Xizmat tavsifi'), findsOneWidget);
  });
}
