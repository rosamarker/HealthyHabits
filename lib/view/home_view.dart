// lib/view/home_view.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../model/clients.dart';
import '../view_model/client_list_view_model.dart';
import '../view_model/client_card_view_model.dart';
import '../view_model/home_view_model.dart';
import '../view_model/movesense_view_model.dart';

import '../widgets/client_card_widget.dart';
import '../widgets/movesense_block_widget.dart';

import 'client_card_view.dart';
import 'client_list_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ClientListViewModel clientListVM;
  late final CalendarViewModel calendarVM;

  // IMPORTANT: single instance shared across pages
  late final MovesenseViewModel movesenseVM;

  @override
  void initState() {
    super.initState();

    clientListVM = ClientListViewModel();
    movesenseVM = MovesenseViewModel();

    // Demo data (optional)
    clientListVM.addClient(
      const Client(
        clientId: '1',
        name: 'Anna',
        age: 25,
        gender: 'Female',
        active: 0,
        nextAppointment: 1672531200,
        motivation: 'Motivated',
        exercises: [],
      ),
    );

    calendarVM = CalendarViewModel(initialClients: List.of(clientListVM.clients));
  }

  @override
  void dispose() {
    movesenseVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Healthy Habits')),
      drawer: Drawer(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: clientListVM,
            builder: (_, __) {
              final clients = clientListVM.clients;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.lightGreen),
                    child: Text(
                      'Clients',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  ...clients.map(
                    (client) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(client.name),
                      trailing: Icon(Icons.circle, color: _statusColor(client.active), size: 16),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientDetailPage(
                              viewModel: ClientDetailViewModel(client: client),
                              clientListVM: clientListVM,
                              movesenseVM: movesenseVM,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),

      // SCROLL FIX: Use ONE ListView as the page body
      body: AnimatedBuilder(
        animation: clientListVM,
        builder: (_, __) {
          calendarVM.replaceClients(clientListVM.clients);

          final selected = calendarVM.selectedDay ?? DateTime.now();
          final clientsForDay = calendarVM.getClientsForDay(selected);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Welcome', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientListView(
                              clientListVM: clientListVM,
                              movesenseVM: movesenseVM,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.people),
                      label: const Text('Client list'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.message),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Movesense block on Home + can link to any client
              MovesenseBlockWidget(
                vm: movesenseVM,
                clients: clientListVM.clients,
                onLinkToClient: (updated) => clientListVM.updateClient(updated),
              ),

              const SizedBox(height: 16),

              TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: calendarVM.focusedDay,
                selectedDayPredicate: (day) => isSameDay(calendarVM.selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    calendarVM.selectDay(selectedDay);
                    calendarVM.focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() => calendarVM.focusedDay = focusedDay);
                },
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  todayDecoration: BoxDecoration(color: Colors.green.withOpacity(0.25), shape: BoxShape.circle),
                  todayTextStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Clients', style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),

              if (clientsForDay.isEmpty)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('No clients for the selected day'),
                )
              else
                ...clientsForDay.map(
                  (client) => ClientCardWidget(
                    client: client,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientDetailPage(
                            viewModel: ClientDetailViewModel(client: client),
                            clientListVM: clientListVM,
                            movesenseVM: movesenseVM,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Color _statusColor(int active) {
  switch (active) {
    case 0:
      return Colors.green;
    case 1:
      return Colors.yellow;
    case 2:
      return Colors.red;
    default:
      return Colors.grey;
  }
}