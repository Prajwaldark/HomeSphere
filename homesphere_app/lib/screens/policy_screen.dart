import 'package:flutter/material.dart';

enum PolicyType { terms, privacy }

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key, required this.type});

  final PolicyType type;

  bool get _isTerms => type == PolicyType.terms;

  String get _title => _isTerms ? 'Terms of Service' : 'Privacy Policy';

  String get _subtitle => _isTerms
      ? 'How you can use HomeSphere'
      : 'How HomeSphere handles your data';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final sections = _isTerms
        ? <_PolicySection>[
            const _PolicySection(
              title: '1. Use of the app',
              body:
                  'HomeSphere is provided to help you manage subscriptions, appliances, vehicles, and related reminders.',
            ),
            const _PolicySection(
              title: '2. Account responsibility',
              body:
                  'You are responsible for the information tied to your account and for keeping your sign-in details secure.',
            ),
            const _PolicySection(
              title: '3. Service changes',
              body:
                  'We may update or change features over time as the product evolves.',
            ),
          ]
        : <_PolicySection>[
            const _PolicySection(
              title: '1. Data we store',
              body:
                  'We store the data you save in the app, such as your profile details, subscriptions, appliances, and vehicles.',
            ),
            const _PolicySection(
              title: '2. Sign-in providers',
              body:
                  'If you use Google or email sign-in, Firebase Authentication may receive and store the information required to manage your account.',
            ),
            const _PolicySection(
              title: '3. Data use',
              body:
                  'We use your data to provide app functionality, keep your account synced, and improve your experience.',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subtitle,
                    style: TextStyle(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.body,
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This page is intentionally lightweight so you can replace it with your official policy text or external URL later.',
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection({required this.title, required this.body});

  final String title;
  final String body;
}
