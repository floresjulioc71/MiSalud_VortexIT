import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiSalud VortexIT'),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            onPressed: () {
              _showPendingMessage(context);
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WelcomeCard(colorScheme: colorScheme),
            const SizedBox(height: 24),
            Text(
              'Mi información médica',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: _calculateColumns(context),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _DashboardOption(
                  title: 'Perfil médico',
                  subtitle: 'Datos personales y contacto',
                  icon: Icons.badge_outlined,
                  onTap: () => _showPendingMessage(context),
                ),
                _DashboardOption(
                  title: 'Antecedentes',
                  subtitle: 'Enfermedades y cirugías',
                  icon: Icons.medical_information_outlined,
                  onTap: () => _showPendingMessage(context),
                ),
                _DashboardOption(
                  title: 'Alergias',
                  subtitle: 'Alertas importantes',
                  icon: Icons.warning_amber_rounded,
                  onTap: () => _showPendingMessage(context),
                ),
                _DashboardOption(
                  title: 'Medicamentos',
                  subtitle: 'Tratamientos actuales',
                  icon: Icons.medication_outlined,
                  onTap: () => _showPendingMessage(context),
                ),
                _DashboardOption(
                  title: 'Vacunas',
                  subtitle: 'Registro de inmunizaciones',
                  icon: Icons.vaccines_outlined,
                  onTap: () => _showPendingMessage(context),
                ),
                _DashboardOption(
                  title: 'Estudios',
                  subtitle: 'Informes y documentos',
                  icon: Icons.description_outlined,
                  onTap: () => _showPendingMessage(context),
                ),
                _DashboardOption(
                  title: 'Médicos',
                  subtitle: 'Profesionales tratantes',
                  icon: Icons.medical_services_outlined,
                  onTap: () => _showPendingMessage(context),
                ),
                _DashboardOption(
                  title: 'Controles',
                  subtitle: 'Peso, presión y glucemia',
                  icon: Icons.monitor_heart_outlined,
                  onTap: () => _showPendingMessage(context),
                ),
                _DashboardOption(
                  title: 'Informe PDF',
                  subtitle: 'Resumen médico personal',
                  icon: Icons.picture_as_pdf_outlined,
                  onTap: () => _showPendingMessage(context),
                ),
                _DashboardOption(
                  title: 'Respaldo',
                  subtitle: 'Exportar y restaurar datos',
                  icon: Icons.cloud_sync_outlined,
                  onTap: () => _showPendingMessage(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _PrivacyNotice(colorScheme: colorScheme),
          ],
        ),
      ),
    );
  }

  static int _calculateColumns(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

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
      ..showSnackBar(
        const SnackBar(
          content: Text('Este módulo será incorporado en los próximos builds.'),
        ),
      );
  }
}

class _WelcomeCard extends StatelessWidget {
  final ColorScheme colorScheme;

  const _WelcomeCard({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: const Icon(Icons.health_and_safety_outlined, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu salud, siempre organizada',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registra y consulta tu información médica personal '
                    'de forma clara, privada y segura.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 34, color: colorScheme.primary),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  final ColorScheme colorScheme;

  const _PrivacyNotice({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'La información se almacenará localmente y será protegida '
                'con las medidas de seguridad de la aplicación.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
