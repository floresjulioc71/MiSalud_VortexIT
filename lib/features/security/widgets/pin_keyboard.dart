import 'package:flutter/material.dart';

class PinKeyboard extends StatelessWidget {
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final bool enabled;

  const PinKeyboard({
    super.key,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.enabled = true,
  });

  static const List<List<String?>> _keys = <List<String?>>[
    <String?>['1', '2', '3'],
    <String?>['4', '5', '6'],
    <String?>['7', '8', '9'],
    <String?>[null, '0', 'backspace'],
  ];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _keys.map((List<String?> row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((String? key) {
                if (key == null) {
                  return const SizedBox(width: 72, height: 72);
                }

                if (key == 'backspace') {
                  return _KeyboardButton(
                    semanticLabel: 'Borrar último dígito',
                    enabled: enabled,
                    onPressed: onBackspacePressed,
                    child: const Icon(Icons.backspace_outlined, size: 27),
                  );
                }

                return _KeyboardButton(
                  semanticLabel: 'Dígito $key',
                  enabled: enabled,
                  onPressed: () => onDigitPressed(key),
                  child: Text(
                    key,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyboardButton extends StatelessWidget {
  final Widget child;
  final String semanticLabel;
  final VoidCallback onPressed;
  final bool enabled;

  const _KeyboardButton({
    required this.child,
    required this.semanticLabel,
    required this.onPressed,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            customBorder: const CircleBorder(),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
