# Módulo de Rendiciones de Cuentas

## Descripción General

Módulo móvil para gestión operativa de rendiciones de cuentas, control de gastos, viáticos, sustentos contables y reembolsos.

## Estructura del Proyecto

```
lib/
├── domain/
│   └── models/
│       ├── rendicion.dart              # Modelo principal de rendición
│       ├── comprobante.dart            # Comprobantes (facturas, recibos, etc.)
│       ├── gasto_manual.dart           # Gastos sin comprobante
│       ├── evidencia.dart              # Documentos adjuntos
│       ├── resumen_rendicion.dart      # Resumen financiero
│       ├── observacion_rendicion.dart  # Observaciones y comentarios
│       └── index.dart                  # Exports de todos los modelos
│
├── data/
│   ├── database/
│   │   └── rendiciones_database.dart   # SQLite operations
│   │
│   └── services/
│       └── rendiciones_service.dart    # Lógica de negocio
│
└── presentation/
    └── rendiciones/
        ├── providers.dart              # Riverpod providers y state management
        ├── screens/
        │   ├── listado_rendiciones_screen.dart
        │   ├── crear_rendicion_screen.dart
        │   ├── agregar_gasto_screen.dart
        │   └── detalle_rendicion_screen.dart
        └── widgets/
            └── rendicion_widgets.dart  # Componentes reutilizables
```

## Conceptos Clave

### Rendición
- Unidad de agrupación que contiene múltiples comprobantes y gastos
- Tiene un estado (borrador, enviada, observada, aprobada, rechazada, pagada)
- Se envía completa a aprobación, no por item individual
- Puede estar asociada a un proyecto y/o centro de costo
- Puede marcarse como viático

### Comprobante
- Factura, recibo, boleta o documento fiscal
- Contiene OCR (extracción de datos)
- Incluye foto/imagen del documento
- Información: número, proveedor, monto, fecha, método de pago

### Gasto Manual
- Gasto sin comprobante
- Concepto libre (pasajes, comidas, otros)
- Registra beneficiario
- Método de pago

### Estados de Rendición
- **Borrador**: En edición, no enviada
- **Enviada**: Enviada a aprobación
- **Observada**: Con observaciones que requieren corrección
- **Aprobada**: Aprobada y en proceso de pago
- **Rechazada**: Rechazada por completo
- **Pagada**: Ya pagada y archivada

## Flujo de Uso

1. **Crear Rendición**: Usuario inicia nueva rendición con título, descripción y datos asociados
2. **Agregar Gastos**:
   - Capturar comprobantes vía cámara (con OCR)
   - Registrar gastos manuales sin comprobante
3. **Revisar Resumen**: Ver totales desglosados por concepto y método de pago
4. **Enviar**: Enviar rendición para aprobación
5. **Aprobación**: Administrador revisa y aprueba/observa/rechaza
6. **Correcciones**: Usuario corrige si hay observaciones
7. **Pago**: Sistema marca como pagada

## Features Implementados

✅ Crear/listar/editar rendiciones  
✅ Agregar comprobantes y gastos manuales  
✅ Cálculo automático de totales  
✅ Desglose de gastos por concepto y método de pago  
✅ Filtrado por estado  
✅ Persistencia en SQLite  
✅ Estado management con Riverpod  

## Features Futuros

- [ ] Captura de imágenes y OCR
- [ ] Envío de rendiciones
- [ ] Sistema de aprobación/rechazo
- [ ] Observaciones y comentarios
- [ ] Exportar a PDF
- [ ] Sincronización con servidor
- [ ] Notificaciones de estado

## Dependencias Requeridas

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  sqflite: ^2.2.8
  path: ^1.8.3
  uuid: ^4.0.0
  intl: ^0.19.0
  json_annotation: ^4.8.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

## Uso en main.dart

```dart
// En MaterialApp, agregar a home o routes
import 'package:dev_mobile/presentation/rendiciones/screens/listado_rendiciones_screen.dart';

// Como pantalla principal
home: const ListadoRendicionesScreen(),

// O en navegación
onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ListadoRendicionesScreen(),
  ),
),
```

## Notas de Implementación

### Web vs Mobile
- En web: SQLite lanzará exception, se usa mock data
- En mobile: Se usa SQLite + FFI
- Mock data disponible en `lib/core/mock_data.dart`

### Timeouts
- Queries SQLite: timeout 3s
- Inicio: Future.wait() + timeout 2-3s

### Estado Management
- Se usa Riverpod para state management
- Providers con AsyncValue para operaciones asincrónicas
- AutoDispose para limpiar estado automáticamente

## Endpoints Futuros

Cuando se integre con backend:
- `POST /api/rendiciones` - Crear
- `GET /api/rendiciones` - Listar
- `GET /api/rendiciones/{id}` - Detalle
- `PUT /api/rendiciones/{id}` - Actualizar
- `DELETE /api/rendiciones/{id}` - Eliminar
- `POST /api/rendiciones/{id}/enviar` - Enviar
- `POST /api/rendiciones/{id}/aprobar` - Aprobar
- `POST /api/rendiciones/{id}/rechazar` - Rechazar
