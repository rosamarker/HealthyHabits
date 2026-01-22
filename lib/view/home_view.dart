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

import '../services/sembast_client_repository.dart';
import '../services/sembast_recording_repository.dart';
import '../services/recording_service.dart';

import '../widgets/movesense_block_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ClientListViewModel clientListVM;
  late final MovesenseViewModel movesenseVM;

  late final RecordingService recordingService;
  late final RecordingViewModel recordingVM;

  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    clientListVM = ClientListViewModel(repo: SembastClientRepository());
    movesenseVM = MovesenseViewModel();

    recordingService = RecordingService(
      repo: SembastRecordingRepository(),
      movesenseVM: movesenseVM,
    );
    recordingVM = RecordingViewModel(service: recordingService);

    clientListVM.load();
  }

  @override
  void dispose() {
    recordingVM.dispose();
    movesenseVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green;

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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MovesenseBlockWidget(
                    vm: movesenseVM,
                    recordingVM: recordingVM,
                    clients: clients,
                    onLinkToClient: (Client updated) {
                      clientListVM.updateClient(updated);
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
                      child: TableCalendar<Client>(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2035, 12, 31),
                        focusedDay: _focusedDay,

                        // Month only
                        calendarFormat: _calendarFormat,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Month',
                        },

                        startingDayOfWeek: StartingDayOfWeek.monday,
                        headerStyle: const HeaderStyle(
                          titleCentered: true,
                          formatButtonVisible: false,
                        ),

                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) => _focusedDay = focusedDay,

                        // Appointment markers
                        eventLoader: (day) {
                          return clients.where((c) {
                            if (c.nextAppointment <= 0) return false;
                            final dt = DateTime.fromMillisecondsSinceEpoch(
                              c.nextAppointment * 1000,
                            );
                            return dt.year == day.year &&
                                dt.month == day.month &&
                                dt.day == day.day;
                          }).toList();
                        },

                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: green.withAlpha(64), // faded green
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          selectedTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          todayTextStyle: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            if (events.isEmpty) return null;

                            final dots = events.take(3).map((e) {
                              final c = e;
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

                  // Show appointments under the calendar
                  if (!clientListVM.isLoaded)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    _AppointmentsForDay(
                      selectedDay: _selectedDay,
                      clients: clients,
                      onClientTap: (c) => _openClientDetail(context, c),
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
    final created = await Navigator.push<Client>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateClientPage(
          onCreate: (_) {},
        ),
      ),
    );

    if (!mounted) return;

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
    final items = clients.where((c) {
      if (c.nextAppointment <= 0) return false;
      final dt = DateTime.fromMillisecondsSinceEpoch(c.nextAppointment * 1000);
      return dt.year == selectedDay.year &&
          dt.month == selectedDay.month &&
          dt.day == selectedDay.day;
    }).toList()
      ..sort((a, b) => a.nextAppointment.compareTo(b.nextAppointment));

    if (items.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No appointments for this day'),
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