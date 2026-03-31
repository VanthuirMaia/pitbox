import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/calculos.dart';
import '../services/tema.dart';

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
    final t = await listarTurnos(limite: 30);
    setState(() {
      resumo = r;
      turnos = t;
    });
  }

  String get ganhoRealPorHora {
    final horas = (resumo?['horas_total'] as num?)?.toDouble() ?? 0;
    final ganho = (resumo?['ganho_total'] as num?)?.toDouble() ?? 0;
    if (horas < 0.25) return '—';
    final custoEstimado = ganho * 0.30;
    final porHora = calcularGanhoRealPorHora(
      ganhoBruto: ganho,
      custosCombustivel: custoEstimado * 0.7,
      custosAlimentacao: custoEstimado * 0.3,
      horasTrabalhadas: horas,
    );
    return '${formatarReais(porHora)}/h';
  }

  String get ganhoPorKm {
    final km = (resumo?['km_total'] as num?)?.toDouble() ?? 0;
    final ganho = (resumo?['ganho_total'] as num?)?.toDouble() ?? 0;
    if (km <= 0) return '—';
    return '${formatarReais(ganho / km)}/km';
  }

  Future<void> confirmarExclusao(Map<String, dynamic> turno) async {
    final data = DateTime.parse(turno['inicio_em']);
    final dataStr = '${_diaSemana(data.weekday)}, ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';

    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Cores.card(context),
        title: Text('Excluir turno?', style: TextStyle(color: Cores.texto(context))),
        content: Text(
          'Turno de $dataStr — ${formatarReais((turno['ganho_bruto'] as num?)?.toDouble() ?? 0)}\n\nEssa ação não pode ser desfeita.',
          style: TextStyle(color: Cores.cinza(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Excluir', style: TextStyle(color: Cores.vermelho(context))),
          ),
        ],
      ),
    );

    if (confirma != true) return;
    await excluirTurno(turno['id']);
    carregarDados();
  }

  @override
  Widget build(BuildContext context) {
    final ganho = (resumo?['ganho_total'] as num?)?.toDouble() ?? 0;
    final horas = (resumo?['horas_total'] as num?)?.toDouble() ?? 0;
    final km = (resumo?['km_total'] as num?)?.toDouble() ?? 0;
    final totalTurnos = resumo?['total_turnos'] ?? 0;
    final amarelo = Cores.amarelo(context);
    final cinza = Cores.cinza(context);
    final texto = Cores.texto(context);

    return Scaffold(
      backgroundColor: Cores.bg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 56),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Text('← voltar', style: TextStyle(fontSize: 14, color: cinza)),
            ),
            const SizedBox(height: 12),
            Text('📊 RELATÓRIO', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: texto, letterSpacing: 2,
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
                        color: ativo
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF1A1A00)
                                : const Color(0xFFFFFDE0))
                            : Cores.card(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ativo ? amarelo : Cores.borda(context)),
                      ),
                      alignment: Alignment.center,
                      child: Text(label, style: TextStyle(
                        color: ativo ? amarelo : cinza,
                        fontWeight: ativo ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 13,
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // grid métricas
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                _CardMetrica(label: 'ganho bruto', valor: formatarReais(ganho), cor: amarelo),
                _CardMetrica(label: 'horas rodadas', valor: formatarHoras(horas), cor: texto),
                _CardMetrica(label: 'km rodados', valor: '${km.toStringAsFixed(0)} km', cor: texto),
                _CardMetrica(label: 'turnos', valor: '$totalTurnos', cor: texto),
              ],
            ),
            const SizedBox(height: 8),

            // rentabilidade
            const SizedBox(height: 16),
            Text('RENTABILIDADE', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _CardMetrica(label: 'ganho real/hora', valor: ganhoRealPorHora, cor: amarelo, obs: '~30% custos')),
                const SizedBox(width: 8),
                Expanded(child: _CardMetrica(label: 'ganho por km', valor: ganhoPorKm, cor: amarelo)),
              ],
            ),

            if (km <= 0 || horas < 0.25) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1500)
                      : const Color(0xFFFFFAE0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF888800)),
                ),
                child: const Text(
                  'Registre o hodômetro ao iniciar e finalizar turnos para cálculos mais precisos.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888800)),
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text('ÚLTIMOS TURNOS', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('Toque longo para excluir', style: TextStyle(fontSize: 11, color: cinza)),
            const SizedBox(height: 12),

            if (turnos.isEmpty)
              Text('nenhum turno finalizado ainda', style: TextStyle(fontSize: 14, color: cinza))
            else
              ...turnos.map((t) => _TurnoItem(
                turno: t,
                onLongPress: () => confirmarExclusao(t),
              )),

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

  const _CardMetrica({required this.label, required this.valor, required this.cor, this.obs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Cores.borda(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Cores.cinza(context), letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(valor, style: TextStyle(fontSize: 20, color: cor, fontWeight: FontWeight.w800)),
          if (obs != null) ...[
            const SizedBox(height: 4),
            Text(obs!, style: TextStyle(fontSize: 10, color: Cores.cinza(context))),
          ],
        ],
      ),
    );
  }
}

class _TurnoItem extends StatelessWidget {
  final Map<String, dynamic> turno;
  final VoidCallback onLongPress;

  const _TurnoItem({required this.turno, required this.onLongPress});

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

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Cores.card(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Cores.borda(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data, style: TextStyle(fontSize: 14, color: Cores.texto(context))),
                const SizedBox(height: 2),
                Text(formatarHoras(horas), style: TextStyle(fontSize: 12, color: Cores.cinza(context))),
                if (kmRodados != null && kmRodados > 0) ...[
                  const SizedBox(height: 2),
                  Text('${kmRodados.toStringAsFixed(0)} km',
                    style: TextStyle(fontSize: 12, color: Cores.cinza(context))),
                ],
                if (turno['plataforma'] != null) ...[
                  const SizedBox(height: 2),
                  Text(turno['plataforma'],
                    style: TextStyle(fontSize: 11, color: Cores.cinza(context))),
                ],
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatarReais(ganho), style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Cores.amarelo(context))),
                if (kmRodados != null && kmRodados > 0)
                  Text('${formatarReais(ganho / kmRodados)}/km',
                    style: TextStyle(fontSize: 12, color: Cores.cinza(context))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _diaSemana(int dia) {
  const dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
  return dias[dia - 1];
}