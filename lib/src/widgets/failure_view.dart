import 'package:flutter/material.dart';

import 'package:project_lab/src/core/errors/failure.dart';

/// Turns a [Failure] into words for the user. No default branch on purpose:
/// a new [Failure] subtype will not compile until it has a message here.
String failureMessage(Failure failure) => switch (failure) {
  OfflineFailure() => 'No connection. Check the network and try again.',
  TimeoutFailure() => 'The server is taking too long to answer.',
  ServerFailure(:final statusCode) => 'The server had a problem ($statusCode).',
  UnexpectedFailure() => 'Something unexpected happened.',
};

class FailureView extends StatelessWidget {
  const FailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.retrying = false,
  });

  final Failure failure;
  final VoidCallback onRetry;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(failureMessage(failure), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: retrying ? null : onRetry,
            child: Text(retrying ? 'Retrying…' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
