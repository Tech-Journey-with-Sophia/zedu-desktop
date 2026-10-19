import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

void main() {
  final sampleMembers = [
    const TeamMember(
      id: 'member-1',
      email: 'admin@zedu.app',
      role: 'Administrator',
      dateJoined: 'May 3, 2026',
      status: TeamMemberStatus.active,
      name: 'Admin User',
    ),
    const TeamMember(
      id: 'member-2',
      email: 'dev@zedu.app',
      role: 'User',
      dateJoined: 'May 4, 2026',
      status: TeamMemberStatus.active,
      name: 'Developer',
    ),
  ];

  Widget buildSection({List<TeamMember>? members}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: UserManagementSection(
            members: members ?? sampleMembers,
            isSaving: false,
            onInvite: ({required String email, required String role}) async {},
            onUpdate: (_) {},
            onRemove: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders team members table with headers and member rows', (
    tester,
  ) async {
    await tester.pumpWidget(buildSection());
    await tester.pump();

    expect(find.text('Your Team'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('admin@zedu.app'), findsOneWidget);
    expect(find.text('dev@zedu.app'), findsOneWidget);
    expect(find.text('No results found'), findsNothing);
  });

  testWidgets(
    'shows empty state with clear filters button when search returns zero results and preserves table header',
    (tester) async {
      await tester.pumpWidget(buildSection());
      await tester.pump();

      // Enter search term with zero matches
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pump();

      // Verify table headers still exist (no layout collapse)
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Role'), findsWidgets);
      expect(find.text('Date Joined'), findsOneWidget);

      // Verify empty state is displayed
      expect(find.text('No results found'), findsOneWidget);
      expect(
        find.textContaining('No members match "nonexistent"'),
        findsOneWidget,
      );
      expect(find.text('Clear filters'), findsWidgets);
      expect(find.text('admin@zedu.app'), findsNothing);

      // Tap Clear filters button in empty state
      final clearButtonFinder = find.widgetWithText(AppButton, 'Clear filters');
      expect(clearButtonFinder, findsOneWidget);
      await tester.tap(clearButtonFinder);
      await tester.pump();

      // Verify list is restored
      expect(find.text('admin@zedu.app'), findsOneWidget);
      expect(find.text('dev@zedu.app'), findsOneWidget);
      expect(find.text('No results found'), findsNothing);
    },
  );

  testWidgets('shows empty state when role filter returns zero results', (
    tester,
  ) async {
    await tester.pumpWidget(buildSection());
    await tester.pump();

    // Select 'Manager' role which has 0 members in sample
    await tester.tap(find.text('All Roles'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manager').last);
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsOneWidget);
    expect(
      find.textContaining('No members found with role "Manager"'),
      findsOneWidget,
    );

    // Tap Reset / Clear filters
    final clearButtonFinder = find.widgetWithText(AppButton, 'Clear filters');
    await tester.tap(clearButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('admin@zedu.app'), findsOneWidget);
    expect(find.text('No results found'), findsNothing);
  });

  testWidgets('clears search using suffix icon button in text field', (
    tester,
  ) async {
    await tester.pumpWidget(buildSection());
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'nonexistent');
    await tester.pump();

    expect(find.text('No results found'), findsOneWidget);

    final clearIconFinder = find.byTooltip('Clear search');
    expect(clearIconFinder, findsOneWidget);
    await tester.tap(clearIconFinder);
    await tester.pump();

    expect(find.text('admin@zedu.app'), findsOneWidget);
    expect(find.text('No results found'), findsNothing);
  });
}
