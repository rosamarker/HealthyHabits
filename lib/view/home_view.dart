// lib/view/home_view.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../model/clients.dart';

import '../view/client_card_view.dart';
import '../view/client_list_view.dart';
import '../view/create_client_view.dart';

import '../view_model/client_card_view_model.dart';
import '../view_model/client_list_view_model.dart';
import '../view_model/movesense_view_model.dart';
import '../view_model/recording_view_model.dart';

import '../services/file_client_repository.dart';
import '../services/file_recording_repository.dart';
import '../services/recording_repository.dart';
import '../services/recording_service.dart';

import '../widgets/client_card_widget.dart';
import '../widgets/movesense_block_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ClientListViewModel clientListVM;
  late final MovesenseViewModel movesenseVM;

  late final RecordingRepository recordingRepo;
  late final RecordingService recordingService;
  late final RecordingViewModel recordingVM;

  // Old-calendar behavior: month-only
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    // FIX: ClientListViewModel now requires repo
    clientListVM = ClientListViewModel(repo: FileClientRepository());
    movesenseVM = MovesenseViewModel();

    recordingRepo = FileRecordingRepository();
    recordingService = RecordingService(repo: recordingRepo, movesenseVM: movesenseVM);
    recordingVM = RecordingViewModel(service: recordingService);

    // Load persisted clients
    Future.microtask(() => clientListVM.load());
  }

  @override
  void dispose() {
    recordingVM.dispose();
    movesenseVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthy Habits'),
        actions: [
          IconButton(
            tooltip: 'Clients',
            icon: const Icon(Icons.people),
            onPressed: () => _openClientList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add client',
        onPressed: () => _openCreateClient(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: clientListVM,
          builder: (_, __) {
            final clients = clientListVM.clients;

            // Optional: show a simple loader until first load completes
            if (!clientListVM.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MovesenseBlockWidget(
                    vm: movesenseVM,
                    recordingVM: recordingVM,
                    clients: clients,
                    onLinkToClient: (Client updated) async {
                      await clientListVM.updateClient(updated);
                    },
                  ),

                  const SizedBox(height: 16),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2035, 12, 31),
                        focusedDay: _focusedDay,

                        // Month-only
                        calendarFormat: _calendarFormat,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },
                        onFormatChanged: (_) {},

                        startingDayOfWeek: StartingDayOfWeek.monday,

                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },

                        headerStyle: const HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                        ),

                        // “Old calendar”: selected = green, today = faded green
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(color: Colors.white),
                          todayDecoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: const TextStyle(color: Colors.black),
                          markersAlignment: Alignment.bottomCenter,
                        ),

                        // Mark days with appointments
                        eventLoader: (day) {
                          final d0 = DateTime(day.year, day.month, day.day);
                          return clients.where((c) {
                            if (c.nextAppointment <= 0) return false;
                            final dt = DateTime.fromMillisecondsSinceEpoch(c.nextAppointment * 1000);
                            return dt.year == d0.year && dt.month == d0.month && dt.day == d0.day;
                          }).toList();
                        },

                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (events.isEmpty) return null;
                            final clientEvents = events.cast<Client>();

                            final dots = clientEvents.take(3).map((c) {
                              return Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _statusColor(c.active),
                                ),
                              );
                            }).toList();

                            return Positioned(
                              bottom: 6,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: dots,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Clients listed beneath calendar (appointments on selected day)
                  _AppointmentsForDay(
                    selectedDay: _selectedDay,
                    clients: clients,
                    onClientTap: (c) => _openClientDetail(context, c),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Clients (${clients.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openClientList(context),
                        child: const Text('See all'),
                      ),
                    ],
                  ),

                  if (clients.isEmpty)
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'No clients yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text('Tap “Add client” to create your first client'),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _openCreateClient(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add client'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: clients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return ClientCardWidget(
                          client: client,
                          onTap: () => _openClientDetail(context, client),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openClientList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientListView(
          clientListVM: clientListVM,
          movesenseVM: movesenseVM,
          recordingVM: recordingVM,
        ),
      ),
    );
  }

  Future<void> _openCreateClient(BuildContext context) async {
    // Requires CreateClientPage to return client via: Navigator.pop(context, client);
    final created = await Navigator.push<Client>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateClientPage(
          onCreate: (_) {}, // rely on returned Client (avoids double-add)
        ),
      ),
    );

    if (created != null) {
      final exists = clientListVM.clients.any((c) => c.clientId == created.clientId);
      if (!exists) {
        await clientListVM.addClient(created);
      } else {
        await clientListVM.updateClient(created);
      }
    }
  }

  void _openClientDetail(BuildContext context, Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailPage(
          viewModel: ClientDetailViewModel(client: client),
          clientListVM: clientListVM,
          movesenseVM: movesenseVM,
          recordingVM: recordingVM,
        ),
      ),
    );
  }

  Color _statusColor(int active) {
    switch (active) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _AppointmentsForDay extends StatelessWidget {
  final DateTime selectedDay;
  final List<Client> clients;
  final ValueChanged<Client> onClientTap;

  const _AppointmentsForDay({
    required this.selectedDay,
    required this.clients,
    required this.onClientTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = clients
        .where((c) {
          if (c.nextAppointment <= 0) return false;
          final dt = DateTime.fromMillisecondsSinceEpoch(c.nextAppointment * 1000);
          return dt.year == selectedDay.year &&
              dt.month == selectedDay.month &&
              dt.day == selectedDay.day;
        })
        .toList()
      ..sort((a, b) => a.nextAppointment.compareTo(b.nextAppointment));

    if (items.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No appointments for the selected day'),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Appointments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...items.map((c) {
              final dt = DateTime.fromMillisecondsSinceEpoch(c.nextAppointment * 1000);
              final hh = dt.hour.toString().padLeft(2, '0');
              final mm = dt.minute.toString().padLeft(2, '0');
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(c.name),
                subtitle: Text('$hh:$mm'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onClientTap(c),
              );
            }),
          ],
        ),
      ),
    );
  }
}