// GUÍA DE INTEGRACIÓN - Módulo de Rendiciones de Cuentas

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dev_mobile/presentation/rendiciones/screens/listado_rendiciones_screen.dart';

// ============================================
// 1. ACTUALIZAR main.dart
// ============================================
/*

// En la función main(), verificar que la app sea un ProviderScope
void main() {
  // ... inicializaciones de BD ...
  runApp(
    const ProviderScope(  // IMPORTANTE: Envolver en ProviderScope
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dev Mobile App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(), // Nueva pantalla de navegación
    );
  }
}

*/

// ============================================
// 2. CREAR PANTALLA DE NAVEGACIÓN PRINCIPAL
// ============================================
/*

// En lib/presentation/main_navigation_screen.dart

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(), // O la pantalla que tenías
    const ListadoRendicionesScreen(),
    const PerfilScreen(), // u otra pantalla
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Rendiciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

*/

// ============================================
// 3. ACCESO DIRECTO EN DRAWER O MENÚ
// ============================================
/*

// En tu Drawer o menú lateral:

ListTile(
  leading: const Icon(Icons.receipt),
  title: const Text('Rendiciones de Cuentas'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ListadoRendicionesScreen(),
      ),
    );
  },
),

*/

// ============================================
// 4. ACTUALIZAR pubspec.yaml
// ============================================
/*

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  sqflite: ^2.2.8
  sqflite_common_ffi: ^2.2.8+4
  sqflite_common_ffi_web: ^0.4.0+1
  path: ^1.8.3
  uuid: ^4.0.0
  intl: ^0.19.0
  json_annotation: ^4.8.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  json_serializable: ^6.7.0

Luego ejecutar:
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

*/

// ============================================
// 5. ACTUALIZAR MOCK DATA (lib/core/mock_data.dart)
// ============================================
/*

import 'package:dev_mobile/domain/models/rendicion.dart';
import 'package:dev_mobile/domain/models/comprobante.dart';
import 'package:dev_mobile/domain/models/gasto_manual.dart';

final mockRendiciones = [
  Rendicion(
    id: 'rend_1',
    userId: 'user_123',
    fechaCreacion: DateTime(2024, 5, 1),
    titulo: 'Rendición Mayo 2024',
    descripcion: 'Gastos de operación en campo',
    estado: RendicionStatus.aprobada,
    totalGastos: 1500.50,
    proyectoId: 'PROJ-001',
    centroCosto: 'CC-001',
    fechaEnvio: DateTime(2024, 5, 3),
    fechaAprobacion: DateTime(2024, 5, 5),
  ),
  // Más rendiciones...
];

final mockComprobantes = [
  Comprobante(
    id: 'comp_1',
    rendicionId: 'rend_1',
    tipo: TipoComprobante.factura,
    numero: 'F001-000123',
    fecha: DateTime(2024, 5, 1),
    proveedor: 'Restaurant XYZ',
    descripcion: 'Almuerzos equipo',
    monto: 250.00,
    metodoPago: TipoPago.efectivo,
    fechaCreacion: DateTime(2024, 5, 1),
  ),
  // Más comprobantes...
];

final mockGastosManuales = [
  GastoManual(
    id: 'gasto_1',
    rendicionId: 'rend_1',
    fecha: DateTime(2024, 5, 2),
    concepto: 'Pasajes',
    descripcion: 'Transporte en taxi',
    monto: 50.00,
    metodoPago: 'efectivo',
    beneficiario: 'Chofer Luis',
    fechaCreacion: DateTime(2024, 5, 2),
  ),
  // Más gastos...
];

*/

// ============================================
// 6. ESTRUCTURA DE ARCHIVOS ESPERADA
// ============================================
/*

lib/
├── domain/
│   └── models/
│       ├── rendicion.dart
│       ├── comprobante.dart
│       ├── gasto_manual.dart
│       ├── evidencia.dart
│       ├── resumen_rendicion.dart
│       ├── observacion_rendicion.dart
│       └── index.dart
│
├── data/
│   ├── database/
│   │   └── rendiciones_database.dart
│   └── services/
│       └── rendiciones_service.dart
│
├── presentation/
│   ├── rendiciones/
│   │   ├── providers.dart
│   │   ├── screens/
│   │   │   ├── listado_rendiciones_screen.dart
│   │   │   ├── crear_rendicion_screen.dart
│   │   │   ├── agregar_gasto_screen.dart
│   │   │   └── detalle_rendicion_screen.dart
│   │   └── widgets/
│   │       └── rendicion_widgets.dart
│   └── ...
│
├── main.dart
└── ...

*/

// ============================================
// 7. VARIABLES DE AMBIENTE (opcional)
// ============================================
/*

Si se requiere configuración por entorno, crear:

lib/.env.dev
lib/.env.prod

Usar paquete dotenv:
  flutter_dotenv: ^5.1.0

En main.dart:
  await dotenv.load(fileName: ".env.${kDebugMode ? 'dev' : 'prod'}");

*/

// ============================================
// NOTAS IMPORTANTES
// ============================================

/* 

1. RIVERPOD SETUP:
   - La app debe estar envuelta en ProviderScope
   - Todos los providers se definen en presentation/rendiciones/providers.dart
   - Use ref.watch() y ref.read() correctamente

2. SQLITE:
   - Usar kIsWeb para detectar plataforma
   - Mock data como fallback en web
   - Timeouts: 3s para queries

3. ESTADO MANAGEMENT:
   - Usar Riverpod para todo estado global
   - AutoDispose para limpiar automáticamente
   - AsyncValue para operaciones async

4. NAVEGACIÓN:
   - Usar Navigator.push() para ir a detalle
   - Usar ref.refresh() para actualizar datos

5. ESTILOS:
   - Seguir Material Design 3
   - Usar Material 3 con useMaterial3: true

6. TESTING:
   - Crear tests para providers
   - Crear tests para service
   - Crear tests para widgets

7. RENDIMIENTO:
   - Las imágenes se guardan en filesystem
   - OCR será implementado con Google ML Kit
   - Sincronización futura con servidor

*/

void main() {
  // Ejemplo de implementación
}
