import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

class UserManagementSection extends StatefulWidget {
  const UserManagementSection({
    super.key,
    required this.members,
    required this.isSaving,
    required this.onInvite,
    required this.onUpdate,
    required this.onRemove,
  });

  final List<TeamMember> members;
  final bool isSaving;
  final Future<void> Function({required String email, required String role})
  onInvite;
  final ValueChanged<TeamMember> onUpdate;
  final ValueChanged<String> onRemove;

  @override
  State<UserManagementSection> createState() => _UserManagementSectionState();
}

class _UserManagementSectionState extends State<UserManagementSection> {
  final _searchController = TextEditingController();
  String _roleFilter = 'All Roles';
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _roleFilter = 'All Roles';
    });
  }

  @override
  Widget build(BuildContext context) {
    final membersList = widget.members
        .where((member) => member.status != TeamMemberStatus.pending)
        .toList();
    final invitesList = widget.members
        .where((member) => member.status == TeamMemberStatus.pending)
        .toList();

    final currentList = _selectedTab == 0
        ? (membersList.isEmpty && widget.members.isNotEmpty && invitesList.isEmpty
            ? widget.members
            : membersList)
        : invitesList;

    final query = _searchController.text.trim().toLowerCase();
    final hasActiveFilter = query.isNotEmpty || _roleFilter != 'All Roles';

    final filtered = currentList.where((member) {
      final matchesQuery = query.isEmpty ||
          member.email.toLowerCase().contains(query) ||
          (member.name?.toLowerCase().contains(query) ?? false);
      final matchesRole =
          _roleFilter == 'All Roles' || member.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();

    final tabName = _selectedTab == 0 ? 'members' : 'invites';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Your Team',
          subtitle: 'Manage all members of your team.',
          trailing: AppButton(
            label: 'Invite People',
            expand: false,
            height: 44,
            loading: widget.isSaving,
            onPressed: () => _showInviteDialog(context, widget.onInvite),
          ),
        ),
        const SizedBox(height: 34),
        Row(
          children: [
            _TabLabel(
              label: 'Members',
              count: _selectedTab == 0 && hasActiveFilter
                  ? filtered.length
                  : (membersList.isEmpty && widget.members.isNotEmpty && invitesList.isEmpty
                      ? widget.members.length
                      : membersList.length),
              active: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            const SizedBox(width: 32),
            _TabLabel(
              label: 'Invites',
              count: _selectedTab == 1 && hasActiveFilter
                  ? filtered.length
                  : invitesList.length,
              active: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ProfileCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by name or email',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  splashRadius: 16,
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _roleFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: 'All Roles',
                          child: Text('All Roles'),
                        ),
                        DropdownMenuItem(
                          value: 'Administrator',
                          child: Text('Administrator'),
                        ),
                        DropdownMenuItem(
                          value: 'Manager',
                          child: Text('Manager'),
                        ),
                        DropdownMenuItem(value: 'User', child: Text('User')),
                      ],
                      onChanged: (value) => setState(() {
                        _roleFilter = value ?? 'All Roles';
                      }),
                    ),
                    if (hasActiveFilter) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Clear filters'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 880,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFFAFAFA),
                        ),
                        columns: const [
                          DataColumn(label: Text('Email Address')),
                          DataColumn(label: Text('Role')),
                          DataColumn(label: Text('Date Joined')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filtered.map((member) {
                          return DataRow(
                            cells: [
                              DataCell(_MemberIdentity(email: member.email)),
                              DataCell(Text(member.role)),
                              DataCell(Text(member.dateJoined)),
                              DataCell(
                                ProfileStatusPill(status: member.status.name),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    SquareIconButton(
                                      icon: Icons.edit_outlined,
                                      size: 28,
                                      onTap: () => _showMemberDialog(
                                        context,
                                        member,
                                        widget.onUpdate,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SquareIconButton(
                                      icon: Icons.delete_outline,
                                      size: 28,
                                      onTap: () => _confirmRemove(
                                        context,
                                        member.email,
                                        () async => widget.onRemove(member.id),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 56,
                            horizontal: 24,
                          ),
                          alignment: Alignment.center,
                          child: _UserManagementEmptyState(
                            hasActiveFilter: hasActiveFilter,
                            tabName: tabName,
                            searchQuery: _searchController.text.trim(),
                            roleFilter: _roleFilter,
                            onClearFilters: _clearFilters,
                            onInvite: () =>
                                _showInviteDialog(context, widget.onInvite),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    AppButton.outlined(
                      label: 'Previous',
                      expand: false,
                      height: 36,
                      disabled: true,
                    ),
                    const Spacer(),
                    Text(
                      filtered.isEmpty ? '0 of 0' : '1',
                      style: context.textTheme.bodySmall,
                    ),
                    const Spacer(),
                    AppButton.outlined(
                      label: 'Next',
                      expand: false,
                      height: 36,
                      disabled: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInviteDialog(
    BuildContext context,
    Future<void> Function({required String email, required String role})
    onInvite,
  ) => showInviteMemberDialog(context, onInvite);

  void _showMemberDialog(
    BuildContext context,
    TeamMember member,
    ValueChanged<TeamMember> onUpdate,
  ) => showEditMemberDialog(context, member, onUpdate);

  Future<void> _confirmRemove(
    BuildContext context,
    String email,
    Future<void> Function() onConfirm,
  ) => showProfileConfirmDialog(
    context,
    title: 'Remove team member?',
    message: '$email will lose access to this organization.',
    confirmLabel: 'Remove member',
    onConfirm: onConfirm,
    destructive: true,
  );
}

class _UserManagementEmptyState extends StatelessWidget {
  const _UserManagementEmptyState({
    required this.hasActiveFilter,
    required this.tabName,
    required this.searchQuery,
    required this.roleFilter,
    required this.onClearFilters,
    required this.onInvite,
  });

  final bool hasActiveFilter;
  final String tabName;
  final String searchQuery;
  final String roleFilter;
  final VoidCallback onClearFilters;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.search_off_rounded,
              size: 28,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          hasActiveFilter ? 'No results found' : 'No $tabName yet',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Text(
            _buildSubtitle(),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (hasActiveFilter)
          AppButton.outlined(
            label: 'Clear filters',
            expand: false,
            height: 36,
            onPressed: onClearFilters,
          )
        else
          AppButton(
            label: 'Invite People',
            expand: false,
            height: 36,
            onPressed: onInvite,
          ),
      ],
    );
  }

  String _buildSubtitle() {
    if (hasActiveFilter) {
      if (searchQuery.isNotEmpty && roleFilter != 'All Roles') {
        return 'No $tabName match "$searchQuery" with role "$roleFilter". Try adjusting your search query or reset your filters.';
      } else if (searchQuery.isNotEmpty) {
        return 'No $tabName match "$searchQuery". Try checking for typos or reset your filters.';
      } else {
        return 'No $tabName found with role "$roleFilter". Try selecting another role or reset your filters.';
      }
    }
    return tabName == 'members'
        ? 'Invite people to your team to start collaborating in your organization.'
        : 'You do not have any pending invitations at this time.';
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({
    required this.label,
    required this.count,
    required this.active,
    this.onTap,
  });
  final String label;
  final int count;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? context.colors.sidebar
                      : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFE9E9FF)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: context.textTheme.labelSmall?.copyWith(
                    color: active
                        ? context.colors.sidebar
                        : const Color(0xFF6B7280),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 8),
            Container(height: 2, width: 80, color: context.colors.sidebar),
          ],
        ],
      ),
    );
  }
}

class _MemberIdentity extends StatelessWidget {
  const _MemberIdentity({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFE9FBFA),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.person, size: 18, color: Color(0xFF17C9BD)),
          ),
        ),
        const SizedBox(width: 12),
        Text(email, style: context.textTheme.bodyMedium),
      ],
    );
  }
}
