// lib/view/client_list_view.dart
import 'package:flutter/material.dart';

import '../model/clients.dart';
import '../view_model/client_list_view_model.dart';
import '../view_model/client_card_view_model.dart';
import '../view_model/home_view_model.dart';
import '../view_model/movement_view_model.dart';
import '../widgets/client_card_widget.dart';
import 'create_client_view.dart';
import 'client_card_view.dart';

class ClientListView extends StatelessWidget {
  final ClientListViewModel clientListVM;
  final CalendarViewModel calendarVM;
  final MovesenseViewModel movesenseVM;

  const ClientListView({
    super.key,
    required this.clientListVM,
    required this.calendarVM,
    required this.movesenseVM,
  });

  DateTime get _selectedDate => calendarVM.selectedDay ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateClientPage(
                onCreate: (Client created) {
                  clientListVM.addClient(created);
                },
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: AnimatedBuilder(
        animation: clientListVM,
        builder: (_, __) {
          final clients = clientListVM.clients;

          if (clients.isEmpty) {
            return const Center(child: Text('No clients yet.'));
          }

          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];

              return Dismissible(
                key: ValueKey(client.clientId),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete client?'),
                          content: Text(
                            'Delete ${client.name}? This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) {
                  clientListVM.removeClient(client.clientId);
                },
                child: Stack(
                  children: [
                    ClientCardWidget(
                      client: client,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientDetailPage(
                              viewModel: ClientDetailViewModel(client: client),
                              selectedDate: _selectedDate,
                              clientListVM: clientListVM,
                              movesenseVM: movesenseVM,
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateClientPage(
                                initialClient: client,
                                onCreate: (Client updatedClient) {
                                  clientListVM.updateClient(updatedClient);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}