import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../model/clients.dart';
import '../view_model/client_list_view_model.dart';
import '../view_model/client_card_view_model.dart';
import '../view_model/home_view_model.dart';
import '../widgets/client_card_widget.dart';
import 'client_card_view.dart';
import 'client_list_view.dart';

/// Landing page: calendar + quick access to clients.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ClientListViewModel clientListVM;
  late final CalendarViewModel calendarVM;

  @override
  void initState() {
    super.initState();

    clientListVM = ClientListViewModel();

    // Seed with a few demo clients so the UI has something to render.
    clientListVM.addClient(
      const Client(
        clientId: '1',
        name: 'Anna',
        age: 25,
        gender: 'Female',
        active: 0,
        nextAppointment: 1672531200,
        motivation: 'Motivated',
        exercises: [
          Exercise(
            exerciseId: 'e1',
            name: 'Squats',
            description: 'Bodyweight squats',
            sets: 3,
            reps: 12,
            time: 0,
            isCountable: true,
          ),
          Exercise(
            exerciseId: 'e2',
            name: 'Plank',
            description: 'Core stability hold',
            sets: 3,
            reps: 0,
            time: 30,
            isCountable: false,
          ),
        ],
      ),
    );
    clientListVM.addClient(
      const Client(
        clientId: '2',
        name: 'Mark',
        age: 30,
        gender: 'Male',
        active: 1,
        nextAppointment: 1672531200,
        motivation: 'Needs support',
        exercises: [],
      ),
    );
    clientListVM.addClient(
      const Client(
        clientId: '3',
        name: 'Sophia',
        age: 28,
        gender: 'Female',
        active: 2,
        nextAppointment: 1672531200,
        motivation: 'Struggling',
        exercises: [],
      ),
    );

    calendarVM = CalendarViewModel(initialClients: List.of(clientListVM.clients));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HealthyHabits')),
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
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 97, 164, 97),
                    ),
                    child: Text(
                      'Clients',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  ...clients.map(
                    (client) => ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(client.name),
                      trailing: Icon(
                        Icons.circle,
                        color: _statusColor(client.active),
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientDetailPage(
                              viewModel: ClientDetailViewModel(client: client),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Welcome',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientListView(clientListVM: clientListVM),
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
                    onPressed: () {
                      // Intentionally left as a placeholder.
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: calendarVM.focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(calendarVM.selectedDay ?? DateTime.now(), day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  calendarVM.selectDay(selectedDay);
                  calendarVM.focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() => calendarVM.focusedDay = focusedDay);
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),

            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Clients',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),

            AnimatedBuilder(
              animation: clientListVM,
              builder: (_, __) {
                // Keep calendar view model in sync with the list view model.
                calendarVM.replaceClients(clientListVM.clients);
                final list = calendarVM.getClientsForDay(
                  calendarVM.selectedDay ?? DateTime.now(),
                );

                if (list.isEmpty) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('No clients for the selected day.'),
                  );
                }

                return Column(
                  children: list
                      .map(
                        (client) => ClientCardWidget(
                          client: client,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClientDetailPage(
                                  viewModel: ClientDetailViewModel(client: client),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
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
