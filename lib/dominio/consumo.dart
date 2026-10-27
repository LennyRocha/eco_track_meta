// lib/dominio/consumo.dart
const laboratoriosUtez = ['Lab Química', 'Lab Redes', 'Lab Física'];

class Consumo {
  const Consumo({required this.laboratorio, required this.litros});
  final String laboratorio;
  final double litros;
}

String? validarLitros(double? litros) { ... }   // mensaje de error o null

// lib/datos/consumo_repository.dart


// lib/datos/memoria_consumo_repository.dart

// lib/presentacion/consumos_view_model.dart


// lib/presentacion/vistas.dart — widgets tontos

// lib/variantes/a_change_notifier.dart

// lib/variantes/b_provider.dart