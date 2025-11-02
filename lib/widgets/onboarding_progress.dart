import 'package:flutter/material.dart';
import '../core/services/mock_onboarding_service.dart';
import '../core/utils/constants.dart';

class OnboardingProgress extends StatelessWidget {
  final MockOnboardingService _onboardingService = MockOnboardingService();

  OnboardingProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _onboardingService.getOnboardingProgress(),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            minHeight: 4,
          ),

          const SizedBox(height: 8),

          // Step indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_onboardingService.getCurrentStepNumber()} of 4',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _onboardingService.getCurrentStepTitle(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
