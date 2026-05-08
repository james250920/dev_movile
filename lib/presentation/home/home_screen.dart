import 'package:flutter/material.dart';
import 'package:dev_mobile/presentation/home/rendicion_screen.dart';
import 'package:dev_mobile/presentation/home/tareos_screen.dart';
import 'package:dev_mobile/presentation/home/asistencia_screen.dart';
import 'package:dev_mobile/presentation/login/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 36, color: Colors.blueAccent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Menú',
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('Salir'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              icon: Icons.account_balance,
              title: 'Rendición de cuentas',
              subtitle: 'Ver reportes y justificar movimientos',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RendicionScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.assignment,
              title: 'Sistema de Tareos',
              subtitle: 'Registrar y gestionar tareos diarios',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TareosScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildCard(
              icon: Icons.access_time,
              title: 'Control de asistencia',
              subtitle: 'Marcar asistencia y revisar historiales',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AsistenciaScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
