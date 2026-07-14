import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/navigation_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_DashboardItem> items = <_DashboardItem>[
      const _DashboardItem(
        title: 'Perfil médico',
        subtitle: 'Datos personales y contacto',
        icon: AppIcons.profile,
        routeName: AppRoutes.profile,
      ),
      const _DashboardItem(
        title: 'Antecedentes',
        subtitle: 'Diagnósticos y condiciones',
        icon: AppIcons.medicalHistory,
        routeName: AppRoutes.medicalHistory,
      ),
      const _DashboardItem(
        title: 'Alergias',
        subtitle: 'Alertas importantes',
        icon: AppIcons.allergies,
        routeName: AppRoutes.allergies,
      ),
      const _DashboardItem(
        title: 'Medicamentos',
        subtitle: 'Tratamientos actuales',
        icon: AppIcons.medications,
        routeName: AppRoutes.medications,
      ),
      const _DashboardItem(
        title: 'Vacunas',
        subtitle: 'Registro de inmunizaciones',
        icon: AppIcons.vaccines,
      ),
      const _DashboardItem(
        title: 'Estudios',
        subtitle: 'Informes y documentos',
        icon: AppIcons.studies,
      ),
      const _DashboardItem(
        title: 'Médicos',
        subtitle: 'Profesionales tratantes',
        icon: AppIcons.doctors,
      ),
      const _DashboardItem(
        title: 'Controles',
        subtitle: 'Peso, presión y glucemia',
        icon: AppIcons.controls,
      ),
      const _DashboardItem(
        title: 'Informe PDF',
        subtitle: 'Resumen médico personal',
        icon: AppIcons.reports,
      ),
      const _DashboardItem(
        title: 'Respaldo',
        subtitle: 'Exportar y restaurar datos',
        icon: AppIcons.backup,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(AppIcons.settings),
            onPressed: () => _showPendingMessage(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        children: [
          const _WelcomeCard(),
          const SizedBox(height: AppSpacing.xLarge),
          Text(
            AppConstants.dashboardTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.large),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columnCount(constraints.maxWidth),
                  crossAxisSpacing: AppSpacing.medium,
                  mainAxisSpacing: AppSpacing.medium,
                  childAspectRatio: 1.2,
                ),
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  return _DashboardCard(item: items[index]);
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.xLarge),
          const _PrivacyCard(),
        ],
      ),
    );
  }

  static int _columnCount(double width) {
    if (width >= 1000) {
      return 4;
    }
    if (width >= 650) {
      return 3;
    }
    return 2;
  }

  static void _showPendingMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppConstants.pendingModule)));
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
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Icon(AppIcons.medicalHistory, size: 34),
            ),
            const SizedBox(width: AppSpacing.large),
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
                  const SizedBox(height: AppSpacing.small),
                  const Text(AppConstants.welcomeMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;

  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (item.routeName != null) {
            NavigationService.pushNamed<void>(item.routeName!);
            return;
          }
          DashboardScreen._showPendingMessage(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: AppColors.primary, size: 34),
              const Spacer(),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? routeName;

  const _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.routeName,
  });
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: [
            Icon(AppIcons.security),
            SizedBox(width: AppSpacing.medium),
            Expanded(child: Text(AppConstants.privacyNotice)),
          ],
        ),
      ),
    );
  }
}
