import 'package:flutter/material.dart';

class PinIndicator extends StatelessWidget {
  final int enteredDigits;
  final int totalDigits;
  final bool hasError;

  const PinIndicator({
    super.key,
    required this.enteredDigits,
    this.totalDigits = 4,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = hasError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    final Color inactiveColor = Theme.of(context).colorScheme.outlineVariant;

    return Semantics(
      label: '$enteredDigits de $totalDigits dígitos ingresados',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(totalDigits, (int index) {
          final bool isActive = index < enteredDigits;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: isActive ? 18 : 16,
            height: isActive ? 18 : 16,
            margin: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? activeColor : Colors.transparent,
              border: Border.all(
                color: isActive ? activeColor : inactiveColor,
                width: 2,
              ),
            ),
          );
        }),
      ),
    );
  }
}
