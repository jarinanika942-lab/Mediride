import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final db = Supabase.instance.client;
  int selected = 0;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> profiles = [];
  List<Map<String, dynamic>> applications = [];
  List<Map<String, dynamic>> ambulances = [];
  List<Map<String, dynamic>> bookings = [];

  final titles = const [
    'Dashboard',
    'Driver Applications',
    'Manage Patients',
    'Manage Drivers',
    'Manage Ambulances',
    'Manage Bookings',
    'Settings',
  ];

  List<Map<String, dynamic>> get patients =>
      profiles.where((p) => p['role'] == 'patient').toList();
  List<Map<String, dynamic>> get drivers =>
      profiles.where((p) => p['role'] == 'driver').toList();

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await Future.wait([
        db.from('profiles').select('id,name,email,phone,role,created_at'),
        db.from('driver_applications').select(
              'id,user_id,license_number,nid_number,vehicle_number,ambulance_type,status,created_at',
            ),
        db.from('ambulances').select(
              'id,driver_id,type,vehicle_number,price,status',
            ),
        db.from('bookings').select(),
      ]);
      profiles = List<Map<String, dynamic>>.from(result[0]);
      applications = List<Map<String, dynamic>>.from(result[1]);
      ambulances = List<Map<String, dynamic>>.from(result[2]);
      bookings = List<Map<String, dynamic>>.from(result[3]);

      for (final a in applications) {
        final matches = profiles.where(
          (p) => p['id'].toString() == a['user_id'].toString(),
        );
        if (matches.isNotEmpty) a['profile'] = matches.first;
      }
      for (final b in bookings) {
        final matches = profiles.where(
          (p) => p['id'].toString() == b['user_id'].toString(),
        );
        if (matches.isNotEmpty) b['patient_profile'] = matches.first;
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => loading = false);
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> logout() async => db.auth.signOut();

  Future<void> reviewApplication(
    Map<String, dynamic> application,
    String status,
  ) async {
    try {
      await db
          .from('driver_applications')
          .update({'status': status}).eq('id', application['id']);
      if (status == 'approved') {
        await db
            .from('profiles')
            .update({'role': 'driver'}).eq('id', application['user_id']);
      }
      message('Application $status.');
      await refreshData();
    } catch (e) {
      message('Update failed: $e');
    }
  }

  Future<void> saveAmbulance({
    int? id,
    required String vehicle,
    required String type,
    required String price,
    required String status,
    required String driverId,
  }) async {
    try {
      final data = {
        'vehicle_number': vehicle.trim(),
        'type': type,
        'price': double.tryParse(price) ?? 0,
        'status': status,
        'driver_id': driverId.trim().isEmpty ? null : driverId.trim(),
      };
      if (id == null) {
        await db.from('ambulances').insert(data);
      } else {
        await db.from('ambulances').update(data).eq('id', id);
      }
      message('Ambulance saved.');
      await refreshData();
    } catch (e) {
      message('Could not save ambulance: $e');
    }
  }

  Future<void> removeAmbulance(dynamic id) async {
    try {
      await db.from('ambulances').delete().eq('id', id);
      message('Ambulance deleted.');
      await refreshData();
    } catch (e) {
      message('Delete failed: $e');
    }
  }

  Future<void> changeBookingStatus(dynamic id, String status) async {
    try {
      await db.from('bookings').update({'status': status}).eq('id', id);
      message('Booking updated.');
      await refreshData();
    } catch (e) {
      message('Booking update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 850;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF14213D),
        elevation: 0,
        title: Text(titles[selected],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: refreshData, icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide ? null : Drawer(child: sidebar()),
      body: Row(
        children: [
          if (wide) SizedBox(width: 250, child: sidebar()),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? errorView()
                    : page(),
          ),
        ],
      ),
    );
  }

  Widget sidebar() {
    final items = [
      (Icons.dashboard_rounded, 'Dashboard'),
      (Icons.assignment_ind_rounded, 'Driver Applications'),
      (Icons.people_alt_rounded, 'Manage Patients'),
      (Icons.badge_rounded, 'Manage Drivers'),
      (Icons.local_shipping_rounded, 'Manage Ambulances'),
      (Icons.calendar_month_rounded, 'Manage Bookings'),
      (Icons.settings_rounded, 'Settings'),
    ];
    return Container(
      color: const Color(0xFF14213D),
      child: Column(
        children: [
          const SizedBox(height: 28),
          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_hospital, color: Colors.white, size: 32),
            SizedBox(width: 10),
            Text('MediRide',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold)),
          ]),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Text('ADMIN PANEL',
                style: TextStyle(color: Colors.white60, letterSpacing: 2)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: ListTile(
                  selected: selected == i,
                  selectedTileColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  leading: Icon(items[i].$1, color: Colors.white),
                  title: Text(items[i].$2,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                  onTap: () {
                    setState(() => selected = i);
                    if (MediaQuery.of(context).size.width < 850) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: logout,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget page() {
    switch (selected) {
      case 0:
        return dashboard();
      case 1:
        return applicationsPage();
      case 2:
        return profilesPage('Patients', patients);
      case 3:
        return profilesPage('Drivers', drivers);
      case 4:
        return ambulancesPage();
      case 5:
        return bookingsPage();
      case 6:
        return settingsPage();
      default:
        return dashboard();
    }
  }

  Widget errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 45),
            const SizedBox(height: 12),
            const Text('Could not load dashboard data.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            const SizedBox(height: 8),
            SelectableText(error ?? 'Unknown error',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again')),
          ]),
        ),
      );

  Widget dashboard() {
    final pending = applications
        .where((a) => a['status'].toString().toLowerCase() == 'pending')
        .toList();
    final recent = [...bookings]..sort((a, b) => (b['created_at'] ?? '')
        .toString()
        .compareTo((a['created_at'] ?? '').toString()));
    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('Welcome back, Admin!',
            style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF14213D))),
        const SizedBox(height: 5),
        const Text('Here is what is happening with MediRide.',
            style: TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 22),
        LayoutBuilder(builder: (context, c) {
          final columns = c.maxWidth > 900
              ? 4
              : c.maxWidth > 520
                  ? 2
                  : 1;
          final stats = [
            (
              'Total Patients',
              patients.length,
              Icons.people_alt,
              const Color(0xFF2563EB)
            ),
            (
              'Total Drivers',
              drivers.length,
              Icons.badge,
              const Color(0xFF059669)
            ),
            (
              'Total Ambulances',
              ambulances.length,
              Icons.local_shipping,
              const Color(0xFFD97706)
            ),
            (
              'Total Bookings',
              bookings.length,
              Icons.calendar_month,
              const Color(0xFF7C3AED)
            ),
          ];
          return GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 3.2 : 1.65,
            children:
                stats.map((s) => statCard(s.$1, s.$2, s.$3, s.$4)).toList(),
          );
        }),
        const SizedBox(height: 24),
        sectionTitle(
            'Pending Driver Applications', () => setState(() => selected = 1)),
        const SizedBox(height: 10),
        if (pending.isEmpty)
          emptyCard('There are no pending driver applications.')
        else
          ...pending.take(5).map((a) {
            final p = a['profile'] as Map<String, dynamic>?;
            return Card(
              color: Colors.white,
              elevation: 0,
              child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.person, color: Color(0xFF2563EB))),
                title: Text(p?['name']?.toString() ?? 'Driver applicant'),
                subtitle: Text(
                    '${a['vehicle_number'] ?? 'No vehicle'} • ${a['ambulance_type'] ?? 'N/A'}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => setState(() => selected = 1),
              ),
            );
          }),
        const SizedBox(height: 24),
        sectionTitle('Recent Bookings', () => setState(() => selected = 5)),
        const SizedBox(height: 10),
        bookingTable(recent.take(6).toList()),
      ]),
    );
  }

  Widget statCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.035),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 25),
        ),
        const SizedBox(width: 14),
        Expanded(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14213D))),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ],
        )),
      ]),
    );
  }

  Widget sectionTitle(String title, VoidCallback onTap) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF14213D))),
          TextButton(onPressed: onTap, child: const Text('View all')),
        ],
      );

  Widget emptyCard(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(color: Colors.blueGrey)),
      );

  Widget pageList(String title, String subtitle, List<Widget> children,
          {Widget? action}) =>
      ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14213D))),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.blueGrey)),
                ])),
            if (action != null) action,
          ]),
          const SizedBox(height: 20),
          ...children,
        ],
      );

  Widget applicationsPage() => pageList(
        'Driver Applications',
        'Review and approve driver registration requests.',
        applications.isEmpty
            ? [emptyCard('No driver applications found.')]
            : applications.map((a) {
                final p = a['profile'] as Map<String, dynamic>?;
                final status = a['status']?.toString() ?? 'pending';
                final pending = status.toLowerCase() == 'pending';
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const CircleAvatar(child: Icon(Icons.person)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    p?['name']?.toString() ??
                                        'Unknown applicant',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(p?['email']?.toString() ?? ''),
                              ],
                            )),
                            statusChip(status),
                          ]),
                          const Divider(height: 24),
                          detail('Phone', p?['phone']),
                          detail('License', a['license_number']),
                          detail('NID', a['nid_number']),
                          detail('Vehicle', a['vehicle_number']),
                          detail('Ambulance type', a['ambulance_type']),
                          if (pending) ...[
                            const SizedBox(height: 12),
                            Wrap(spacing: 10, children: [
                              ElevatedButton.icon(
                                onPressed: () =>
                                    reviewApplication(a, 'approved'),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    foregroundColor: Colors.white),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    reviewApplication(a, 'rejected'),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red),
                              ),
                            ]),
                          ],
                        ]),
                  ),
                );
              }).toList(),
      );

  Widget profilesPage(String title, List<Map<String, dynamic>> rows) =>
      pageList('Manage $title', '$title registered in MediRide.', [
        if (rows.isEmpty)
          emptyCard('No $title found.')
        else
          dataCard(SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Email')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Created')),
              ],
              rows: rows
                  .map((p) => DataRow(cells: [
                        DataCell(Text(p['name']?.toString() ?? '')),
                        DataCell(Text(p['email']?.toString() ?? '')),
                        DataCell(Text(p['phone']?.toString() ?? '')),
                        DataCell(Text(dateText(p['created_at']))),
                      ]))
                  .toList(),
            ),
          )),
      ]);

  Widget ambulancesPage() => pageList(
        'Manage Ambulances',
        'Add ambulances and assign them to approved drivers.',
        [
          if (ambulances.isEmpty)
            emptyCard('No ambulances added yet.')
          else
            dataCard(SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Vehicle')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Driver UUID')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: ambulances
                    .map((a) => DataRow(cells: [
                          DataCell(Text(a['vehicle_number']?.toString() ?? '')),
                          DataCell(Text(a['type']?.toString() ?? '')),
                          DataCell(Text(a['price']?.toString() ?? '0')),
                          DataCell(statusChip(a['status']?.toString() ?? '')),
                          DataCell(
                              Text(a['driver_id']?.toString() ?? 'Unassigned')),
                          DataCell(Row(children: [
                            IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => ambulanceDialog(a)),
                            IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => confirmDelete(a['id'])),
                          ])),
                        ]))
                    .toList(),
              ),
            )),
        ],
        action: ElevatedButton.icon(
          onPressed: () => ambulanceDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add Ambulance'),
        ),
      );

  void ambulanceDialog([Map<String, dynamic>? item]) {
    final vehicle =
        TextEditingController(text: item?['vehicle_number']?.toString() ?? '');
    final price = TextEditingController(text: item?['price']?.toString() ?? '');
    final driver =
        TextEditingController(text: item?['driver_id']?.toString() ?? '');
    String type = item?['type']?.toString() ?? 'Basic';
    String status = item?['status']?.toString() ?? 'available';
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(item == null ? 'Add Ambulance' : 'Edit Ambulance'),
          content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: vehicle,
                      decoration:
                          const InputDecoration(labelText: 'Vehicle Number')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: ['Basic', 'CCU', 'ICU']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialog(() => type = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: price,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Price')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: ['available', 'busy', 'offline']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialog(() => status = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: driver,
                      decoration: const InputDecoration(
                          labelText: 'Driver UUID (optional)')),
                ]),
              )),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (vehicle.text.trim().isEmpty) {
                  message('Vehicle number is required.');
                  return;
                }
                Navigator.pop(dialogContext);
                saveAmbulance(
                  id: item == null ? null : item['id'] as int,
                  vehicle: vehicle.text,
                  type: type,
                  price: price.text,
                  status: status,
                  driverId: driver.text,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirmDelete(dynamic id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ambulance?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (yes == true) await removeAmbulance(id);
  }

  Widget bookingsPage() {
    final sorted = [...bookings]..sort((a, b) => (b['created_at'] ?? '')
        .toString()
        .compareTo((a['created_at'] ?? '').toString()));
    return pageList('Manage Bookings', 'View bookings and update their status.',
        [bookingTable(sorted)]);
  }

  Widget bookingTable(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return emptyCard('No bookings available.');
    return dataCard(SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Patient')),
          DataColumn(label: Text('Emergency')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Fare')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Update')),
        ],
        rows: rows.map((b) {
          final patient = b['patient_name'] ??
              (b['patient_profile'] as Map?)?['name'] ??
              'Patient';
          return DataRow(cells: [
            DataCell(Text(b['id']?.toString() ?? '')),
            DataCell(Text(patient.toString())),
            DataCell(Text(b['emergency_type']?.toString() ?? '')),
            DataCell(Text(
                b['booking_date']?.toString() ?? dateText(b['created_at']))),
            DataCell(Text(b['fare']?.toString() ?? 'N/A')),
            DataCell(statusChip(b['status']?.toString() ?? '')),
            DataCell(PopupMenuButton<String>(
              onSelected: (v) => changeBookingStatus(b['id'], v),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'pending', child: Text('Pending')),
                PopupMenuItem(value: 'accepted', child: Text('Accepted')),
                PopupMenuItem(value: 'completed', child: Text('Completed')),
                PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              child: const Icon(Icons.more_horiz),
            )),
          ]);
        }).toList(),
      ),
    ));
  }

  Widget settingsPage() {
    final user = db.auth.currentUser;
    return pageList('Settings', 'Administrator account information.', [
      dataCard(ListTile(
        leading: const CircleAvatar(child: Icon(Icons.admin_panel_settings)),
        title: const Text('MediRide Admin'),
        subtitle: Text(user?.email ?? 'No email'),
      )),
      const SizedBox(height: 12),
      dataCard(const ListTile(
        leading: Icon(Icons.lock_outline),
        title: Text('Change password'),
        subtitle: Text('Use the password reset option from the login screen.'),
      )),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        onPressed: logout,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, foregroundColor: Colors.white),
      ),
    ]);
  }

  Widget dataCard(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: child,
      );

  Widget detail(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 125,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.blueGrey, fontWeight: FontWeight.w600))),
          Expanded(child: Text(value?.toString() ?? 'Not provided')),
        ]),
      );

  Widget statusChip(String status) {
    final s = status.toLowerCase();
    final color = ['approved', 'available', 'completed', 'accepted'].contains(s)
        ? const Color(0xFF059669)
        : ['rejected', 'cancelled', 'offline'].contains(s)
            ? Colors.red
            : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(.10),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  String dateText(dynamic value) {
    if (value == null) return 'N/A';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
} 
