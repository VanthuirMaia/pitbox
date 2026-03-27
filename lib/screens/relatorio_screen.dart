import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/calculos.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF161616);
const _borda = Color(0xFF222222);
const _amarelo = Color(0xFFE8FF00);
const _branco = Color(0xFFF5F5F5);
const _cinza = Color(0xFF666666);

class RelatorioScreen extends StatefulWidget {
  const RelatorioScreen({super.key});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  String periodo = 'semana';
  Map<String, dynamic>? resumo;
  List<Map<String, dynamic>> turnos = [];

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Map<String, String> get datas {
    final hoje = DateTime.now();
    final fim = hoje.toIso8601String().split('T')[0];
    if (periodo == 'hoje') return {'inicio': fim, 'fim': fim};
    if (periodo == 'semana') {
      final ini = hoje.subtract(const Duration(days: 6));
      return {'inicio': ini.toIso8601String().split('T')[0], 'fim': fim};
    }
    final ini = DateTime(hoje.year, hoje.month, 1);
    return {'inicio': ini.toIso8601String().split('T')[0], 'fim': fim};
  }

  Future<void> carregarDados() async {
    final r = await resumoPeriodo(datas['inicio']!, datas['fim']!);
    final t = await listarTurnos(limite: 10);
    setState(() {
      resumo = r;
      turnos = t;
    });
  }

  // ganho real por hora, só calcula se turno teve mais de 15 minutos
  String get ganhoRealPorHora {
    final horas = (resumo?['horas_total'] as num?)?.toDouble() ?? 0;
    final ganho = (resumo?['ganho_total'] as num?)?.toDouble() ?? 0;
    if (horas < 0.25) return '—'; // menos de 15 minutos, não calcula
    final custoEstimado = ganho * 0.30;
    final porHora = calcularGanhoRealPorHora(
      ganhoBruto: ganho,
      custosCombustivel: custoEstimado * 0.7,
      custosAlimentacao: custoEstimado * 0.3,
      horasTrabalhadas: horas,
    );
    return '${formatarReais(porHora)}/h';
  }

  // ganho por km
  String get ganhoPorKm {
    final km = (resumo?['km_total'] as num?)?.toDouble() ?? 0;
    final ganho = (resumo?['ganho_total'] as num?)?.toDouble() ?? 0;
    if (km <= 0) return '—';
    return '${formatarReais(ganho / km)}/km';
  }

  @override
  Widget build(BuildContext context) {
    final ganho = (resumo?['ganho_total'] as num?)?.toDouble() ?? 0;
    final horas = (resumo?['horas_total'] as num?)?.toDouble() ?? 0;
    final km = (resumo?['km_total'] as num?)?.toDouble() ?? 0;
    final totalTurnos = resumo?['total_turnos'] ?? 0;

    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 56),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('← voltar', style: TextStyle(fontSize: 14, color: _cinza)),
            ),
            const SizedBox(height: 12),
            const Text('📊 RELATÓRIO', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: _branco, letterSpacing: 2,
            )),
            const SizedBox(height: 24),

            // seletor de período
            Row(
              children: ['hoje', 'semana', 'mes'].map((p) {
                final ativo = periodo == p;
                final label = p == 'mes' ? 'Mês' : p == 'semana' ? '7 dias' : 'Hoje';
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => periodo = p);
                      carregarDados();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: ativo ? const Color(0xFF1A1A00) : _card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ativo ? _amarelo : _borda),
                      ),
                      alignment: Alignment.center,
                      child: Text(label, style: TextStyle(
                        color: ativo ? _amarelo : _cinza,
                        fontWeight: ativo ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 13,
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // grid métricas principais
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                _CardMetrica(label: 'ganho bruto', valor: formatarReais(ganho), cor: _amarelo),
                _CardMetrica(label: 'horas rodadas', valor: formatarHoras(horas)),
                _CardMetrica(label: 'km rodados', valor: '${km.toStringAsFixed(0)} km'),
                _CardMetrica(label: 'turnos', valor: '$totalTurnos'),
              ],
            ),
            const SizedBox(height: 8),

            // métricas de rentabilidade
            const SizedBox(height: 16),
            const Text('RENTABILIDADE', style: TextStyle(fontSize: 10, color: _cinza, letterSpacing: 2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CardMetrica(
                    label: 'ganho real/hora',
                    valor: ganhoRealPorHora,
                    cor: _amarelo,
                    obs: '~30% custos',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CardMetrica(
                    label: 'ganho por km',
                    valor: ganhoPorKm,
                    cor: _amarelo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // aviso se dados insuficientes
            if (km <= 0 || horas < 0.25)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1500),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF444400)),
                ),
                child: const Text(
                  'Registre o hodômetro ao iniciar e finalizar turnos para cálculos mais precisos.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFAAAA00)),
                ),
              ),

            const SizedBox(height: 24),

            // histórico de turnos
            const Text('ÚLTIMOS TURNOS',
              style: TextStyle(fontSize: 10, color: _cinza, letterSpacing: 2)),
            const SizedBox(height: 12),

            if (turnos.isEmpty)
              const Text('nenhum turno finalizado ainda',
                style: TextStyle(fontSize: 14, color: _cinza))
            else
              ...turnos.map((t) => _TurnoItem(turno: t)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CardMetrica extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;
  final String? obs;

  const _CardMetrica({required this.label, required this.valor, this.cor = _branco, this.obs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: _cinza, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(valor, style: TextStyle(fontSize: 20, color: cor, fontWeight: FontWeight.w800)),
          if (obs != null) ...[
            const SizedBox(height: 4),
            Text(obs!, style: const TextStyle(fontSize: 10, color: _cinza)),
          ]
        ],
      ),
    );
  }
}

class _TurnoItem extends StatelessWidget {
  final Map<String, dynamic> turno;

  const _TurnoItem({required this.turno});

  @override
  Widget build(BuildContext context) {
    final inicio = DateTime.parse(turno['inicio_em']);
    final horas = turno['fim_em'] != null
        ? calcularHoras(turno['inicio_em'], turno['fim_em'])
        : 0.0;
    final kmInicial = (turno['km_inicial'] as num?)?.toDouble();
    final kmFinal = (turno['km_final'] as num?)?.toDouble();
    final kmRodados = kmInicial != null && kmFinal != null
        ? calcularKmRodados(kmInicial, kmFinal)
        : null;
    final ganho = (turno['ganho_bruto'] as num?)?.toDouble() ?? 0;
    final data = '${_diaSemana(inicio.weekday)}, ${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borda),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data, style: const TextStyle(fontSize: 14, color: _branco)),
              const SizedBox(height: 2),
              Text(formatarHoras(horas), style: const TextStyle(fontSize: 12, color: _cinza)),
              if (kmRodados != null && kmRodados > 0) ...[
                const SizedBox(height: 2),
                Text('${kmRodados.toStringAsFixed(0)} km',
                  style: const TextStyle(fontSize: 12, color: _cinza)),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatarReais(ganho),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _amarelo)),
              if (kmRodados != null && kmRodados > 0)
                Text(formatarReais(ganho / kmRodados) + '/km',
                  style: const TextStyle(fontSize: 12, color: _cinza)),
            ],
          ),
        ],
      ),
    );
  }

  String _diaSemana(int dia) {
    const dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    return dias[dia - 1];
  }
}