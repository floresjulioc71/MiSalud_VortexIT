import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/navigation_service.dart';
import '../models/family_member.dart';
import '../services/family_storage_service.dart';

class FamilySelectorScreen extends StatefulWidget {
  const FamilySelectorScreen({super.key});

  @override
  State<FamilySelectorScreen> createState() => _FamilySelectorScreenState();
}

class _FamilySelectorScreenState extends State<FamilySelectorScreen> {
  List<FamilyMember> _members = <FamilyMember>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _members = FamilyStorageService.loadMembers();
    });
  }

  Future<void> _selectMember(FamilyMember member) async {
    await FamilyStorageService.setActiveMember(member.id);

    if (!mounted) {
      return;
    }

    await NavigationService.pushReplacementNamed<void, void>(
      AppRoutes.dashboard,
    );
  }

  Future<void> _openFamilyManager() async {
    await NavigationService.pushNamed<void>(AppRoutes.family);

    if (mounted) {
      _reload();
    }
  }

  Future<void> _createMember() async {
    if (_members.length >= FamilyStorageService.maximumMembers) {
      return;
    }

    await _openFamilyManager();
  }

  @override
  Widget build(BuildContext context) {
    final bool canAdd = _members.length < FamilyStorageService.maximumMembers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar integrante'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Administrar grupo familiar',
            onPressed: _openFamilyManager,
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int columns = _columnCount(constraints.maxWidth);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.large),
              children: [
                Text(
                  '¿De quién quieres consultar la información médica?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Cada integrante conserva sus datos de forma independiente.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xLarge),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: AppSpacing.large,
                    mainAxisSpacing: AppSpacing.large,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _members.length + (canAdd ? 1 : 0),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == _members.length) {
                      return _AddMemberCard(onTap: _createMember);
                    }

                    final FamilyMember member = _members[index];

                    return _MemberCard(
                      member: member,
                      onTap: () => _selectMember(member),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static int _columnCount(double width) {
    if (width >= 900) {
      return 4;
    }

    if (width >= 600) {
      return 3;
    }

    return 2;
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback onTap;

  const _MemberCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                child: Icon(Icons.person_outline, size: 46),
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                member.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                member.relationship.trim().isEmpty
                    ? 'Integrante'
                    : member.relationship,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMemberCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMemberCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.primary,
                child: Icon(AppIcons.add, size: 46),
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                'Agregar integrante',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
