import 'dart:math';

// ganho real por hora descontando custos
double calcularGanhoRealPorHora({
  required double ganhoBruto,
  required double custosCombustivel,
  required double custosAlimentacao,
  required double horasTrabalhadas,
}) {
  if (horasTrabalhadas <= 0) return 0;
  final lucro = ganhoBruto - custosCombustivel - custosAlimentacao;
  return lucro / horasTrabalhadas;
}

// custo por km rodado
double calcularCustoPorKm({
  required double custosCombustivel,
  required double custosManutencao,
  required double kmRodados,
}) {
  if (kmRodados <= 0) return 0;
  return (custosCombustivel + custosManutencao) / kmRodados;
}

// horas entre dois timestamps ISO
double calcularHoras(String inicioIso, String fimIso) {
  final inicio = DateTime.parse(inicioIso);
  final fim = DateTime.parse(fimIso);
  return fim.difference(inicio).inMinutes / 60;
}

// km rodados entre hodômetro inicial e final
double calcularKmRodados(double kmInicial, double kmFinal) {
  if (kmFinal <= kmInicial) return 0;
  return kmFinal - kmInicial;
}

// distância total da rota pelos pontos GPS usando Haversine
double calcularDistanciaRota(List<Map<String, dynamic>> pontos) {
  if (pontos.length < 2) return 0;

  double total = 0;
  for (int i = 1; i < pontos.length; i++) {
    total += _haversine(
      pontos[i - 1]['latitude'],
      pontos[i - 1]['longitude'],
      pontos[i]['latitude'],
      pontos[i]['longitude'],
    );
  }
  return total;
}

double _haversine(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double graus) => graus * pi / 180;

// formata valor em R$
String formatarReais(double valor) {
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}

// formata horas decimais em "Xh Ym"
String formatarHoras(double horas) {
  final h = horas.floor();
  final m = ((horas - h) * 60).round();
  return '${h}h ${m}m';
}