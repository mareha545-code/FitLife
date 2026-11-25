import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'database_helper.dart';

const Color verde = Color(0xFF123D32);
const Color verdeClaro = Color(0xFF1D7054);

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> entrenamientos = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarHistorial();
  }

  Future<void> cargarHistorial() async {
    try {
      final datos =
      await DatabaseHelper.obtenerEntrenamientos();

      if (!mounted) return;

      setState(() {
        entrenamientos = datos;
        cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => cargando = false);
    }
  }

  String formatoDuracion(int segundos) {
    final minutos = segundos ~/ 60;
    final resto = segundos % 60;

    return '${minutos} min ${resto} s';
  }

  Future<void> eliminar(int id) async {
    await DatabaseHelper.eliminarEntrenamiento(id);
    await cargarHistorial();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entrenamiento eliminado'),
      ),
    );
  }

  void confirmarEliminacion(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar entrenamiento'),
        content: const Text(
          '¿Deseas eliminar este entrenamiento del historial?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              eliminar(id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void abrirRecorrido(Map<String, dynamic> item) {
    try {
      final lista = jsonDecode(item['ruta'] as String) as List;

      final puntos = lista.map((p) {
        return LatLng(
          (p['lat'] as num).toDouble(),
          (p['lng'] as num).toDouble(),
        );
      }).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SavedRoutePage(
            points: puntos,
            fecha: item['fecha'].toString(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el recorrido'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi historial',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: verde,
        foregroundColor: Colors.white,
      ),

      body: cargando
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : entrenamientos.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 75,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Text(
              'Aún no tienes entrenamientos',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Tus actividades aparecerán aquí.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: cargarHistorial,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entrenamientos.length,
          itemBuilder: (context, index) {
            final item = entrenamientos[index];

            final id = item['id'] as int;
            final pasos = item['pasos'] as int;
            final duracion =
            item['duracion'] as int;
            final distancia =
            (item['distancia'] as num).toDouble();

            return Card(
              margin: const EdgeInsets.only(
                bottom: 15,
              ),
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(18),
              ),
              child: InkWell(
                borderRadius:
                BorderRadius.circular(18),
                onTap: () => abrirRecorrido(item),
                child: Padding(
                  padding: const EdgeInsets.all(17),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: verdeClaro,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['fecha'].toString(),
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar',
                            onPressed: () =>
                                confirmarEliminacion(id),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),

                      const Divider(),

                      Row(
                        children: [
                          Expanded(
                            child: dato(
                              Icons.directions_walk,
                              'Pasos',
                              '$pasos',
                            ),
                          ),
                          Expanded(
                            child: dato(
                              Icons.route,
                              'Distancia',
                              '${(distancia / 1000).toStringAsFixed(2)} km',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      dato(
                        Icons.timer,
                        'Duración',
                        formatoDuracion(duracion),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F2EC),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.map,
                              color: verde,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Consultar recorrido',
                              style: TextStyle(
                                color: verde,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: verde,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget dato(
      IconData icono,
      String titulo,
      String valor,
      ) {
    return Row(
      children: [
        Icon(icono, color: verdeClaro, size: 21),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                valor,
                style: const TextStyle(
                  color: verde,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================================
// MAPA DEL RECORRIDO GUARDADO
// ===================================

class SavedRoutePage extends StatelessWidget {
  final List<LatLng> points;
  final String fecha;

  const SavedRoutePage({
    super.key,
    required this.points,
    required this.fecha,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi recorrido'),
        backgroundColor: verde,
        foregroundColor: Colors.white,
      ),

      body: points.isEmpty
          ? const Center(
        child: Text(
          'No existen coordenadas guardadas.',
        ),
      )
          : FlutterMap(
        options: MapOptions(
          initialCenter: points.first,
          initialZoom: 15,
        ),

        children: [
          TileLayer(
            urlTemplate:
            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.fitlife',
          ),

          if (points.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  color: verdeClaro,
                  strokeWidth: 5,
                ),
              ],
            ),

          MarkerLayer(
            markers: [
              Marker(
                point: points.first,
                width: 45,
                height: 45,
                child: const Icon(
                  Icons.play_circle,
                  color: Colors.green,
                  size: 38,
                ),
              ),
              if (points.length > 1)
                Marker(
                  point: points.last,
                  width: 45,
                  height: 45,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
