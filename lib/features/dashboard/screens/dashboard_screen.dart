import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(AppIcons.settings),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppConstants.pendingModule)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        children: const [
          _WelcomeCard(),
          SizedBox(height: AppSpacing.xLarge),
          _SectionTitle(),
          SizedBox(height: AppSpacing.large),
          _DashboardGrid(),
          SizedBox(height: AppSpacing.xLarge),
          _PrivacyCard(),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(AppIcons.medicalHistory, size: 34),
            ),
            SizedBox(width: AppSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.welcomeTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppSpacing.small),
                  Text(AppConstants.welcomeMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppConstants.dashboardTitle,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('Perfil médico', AppIcons.profile),
      ('Antecedentes', AppIcons.medicalHistory),
      ('Alergias', AppIcons.allergies),
      ('Medicamentos', AppIcons.medications),
      ('Vacunas', AppIcons.vaccines),
      ('Estudios', AppIcons.studies),
      ('Médicos', AppIcons.doctors),
      ('Controles', AppIcons.controls),
      ('Informe PDF', AppIcons.reports),
      ('Respaldo', AppIcons.backup),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.medium,
        mainAxisSpacing: AppSpacing.medium,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(AppConstants.pendingModule)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.$2, color: AppColors.primary, size: 34),
                  const Spacer(),
                  Text(
                    item.$1,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: const [
            Icon(AppIcons.security),
            SizedBox(width: AppSpacing.medium),
            Expanded(child: Text(AppConstants.privacyNotice)),
          ],
        ),
      ),
    );
  }
}
