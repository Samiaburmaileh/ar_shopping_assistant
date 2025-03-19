// lib/widgets/ar_controls.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ArControls extends StatelessWidget {
  final Function(double) onRotate;
  final Function(double) onScale;
  final Function() onReset;
  final Function() onRemove;

  const ArControls({
    Key? key,
    required this.onRotate,
    required this.onScale,
    required this.onReset,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRotationControls(),
              _buildScaleControls(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildResetButton(),
              _buildRemoveButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRotationControls() {
    return Row(
      children: [
        Text(
          'Rotate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.rotate_left),
          onPressed: () => onRotate(-0.1),
          tooltip: 'Rotate Left',
        ),
        IconButton(
          icon: const Icon(Icons.rotate_right),
          onPressed: () => onRotate(0.1),
          tooltip: 'Rotate Right',
        ),
      ],
    );
  }

  Widget _buildScaleControls() {
    return Row(
      children: [
        Text(
          'Scale',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () => onScale(0.9),
          tooltip: 'Make Smaller',
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => onScale(1.1),
          tooltip: 'Make Larger',
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return ElevatedButton.icon(
      onPressed: onReset,
      icon: const Icon(Icons.restore),
      label: const Text('Reset'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Widget _buildRemoveButton() {
    return ElevatedButton.icon(
      onPressed: onRemove,
      icon: const Icon(Icons.delete),
      label: const Text('Remove'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
      ),
    );
  }
}