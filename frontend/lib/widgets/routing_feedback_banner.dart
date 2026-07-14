import 'package:flutter/material.dart';

import '../models/routing_decision.dart';

class RoutingFeedbackBanner extends StatelessWidget {
  final RoutingDecision? decision;
  final String destinationName;

  const RoutingFeedbackBanner({
    super.key,
    required this.decision,
    required this.destinationName,
  });

  @override
  Widget build(BuildContext context) {
    final currentDecision = decision;

    if (currentDecision == null) {
      return const SizedBox.shrink();
    }

    final confidencePercent =
        (currentDecision.confidence * 100).round();

    return Card(
      color: Theme.of(context)
          .colorScheme
          .secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.route_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Routed to $destinationName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: $confidencePercent%',
                  ),
                  const SizedBox(height: 4),
                  Text(currentDecision.reason),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}