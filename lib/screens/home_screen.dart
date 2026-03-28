import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/calculos.dart';
import '../services/tema.dart';
import 'turno_screen.dart';
import 'abastecimento_screen.dart';
import 'manutencao_screen.dart';
import 'alimentacao_screen.dart';
import 'relatorio_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? turnoAtivo;
  Map<String, dynamic>? resumoSemana;
  Map<String, double>? gastosHoje;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    final turno = await buscarTurnoAtivo();
    final hoje = DateTime.now();
    final inicioSemana = hoje.subtract(const Duration(days: 6));
    final resumo = await resumoPeriodo(
      inicioSemana.toIso8601String().split('T')[0],
      hoje.toIso8601String().split('T')[0],
    );
    final gastos = await totalGastosDia(hoje.toIso8601String().split('T')[0]);
    setState(() {
      turnoAtivo = turno;
      resumoSemana = resumo;
      gastosHoje = gastos;
    });
  }

  void _alternarTema(BuildContext context) {
    final atual = temaNotifier.value;
    if (atual == ThemeMode.dark) {
      definirTema(ThemeMode.light);
    } else if (atual == ThemeMode.light) {
      definirTema(ThemeMode.system);
    } else {
      definirTema(ThemeMode.dark);
    }
  }

  String _labelTema() {
    switch (temaNotifier.value) {
      case ThemeMode.light: return '☀️';
      case ThemeMode.dark: return '🌙';
      default: return '⚙️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Cores.bg(context);
    final card = Cores.card(context);
    final borda = Cores.borda(context);
    final amarelo = Cores.amarelo(context);
    final texto = Cores.texto(context);
    final cinza = Cores.cinza(context);
    final verde = Cores.verde(context);

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: carregarDados,
        color: amarelo,
        backgroundColor: card,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // header com botão de tema
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4),
                          children: [
                            TextSpan(text: 'PIT', style: TextStyle(color: texto)),
                            TextSpan(text: 'BOX', style: TextStyle(color: amarelo)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('controle da sua operação',
                        style: TextStyle(fontSize: 12, color: cinza, letterSpacing: 2)),
                    ],
                  ),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: temaNotifier,
                    builder: (context, _, __) => GestureDetector(
                      onTap: () => _alternarTema(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: borda),
                        ),
                        child: Text(_labelTema(), style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // card turno
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const TurnoScreen()));
                  carregarDados();
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: turnoAtivo != null
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF0F1A0A)
                            : const Color(0xFFEEFFEE))
                        : card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: turnoAtivo != null ? verde : borda),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            turnoAtivo != null ? 'TURNO ATIVO' : 'SEM TURNO ATIVO',
                            style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            turnoAtivo != null
                                ? 'desde ${TimeOfDay.fromDateTime(DateTime.parse(turnoAtivo!['inicio_em'])).format(context)}'
                                : 'toque para iniciar',
                            style: TextStyle(fontSize: 18, color: texto, fontWeight: FontWeight.w700),
                          ),
                          if (turnoAtivo?['plataforma'] != null) ...[
                            const SizedBox(height: 4),
                            Text(turnoAtivo!['plataforma'],
                              style: TextStyle(fontSize: 12, color: cinza)),
                          ],
                        ],
                      ),
                      Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: turnoAtivo != null ? verde : cinza,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text('ÚLTIMOS 7 DIAS', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.6,
                children: [
                  _CardMetrica(label: 'ganho bruto', valor: formatarReais((resumoSemana?['ganho_total'] as num?)?.toDouble() ?? 0), cor: amarelo),
                  _CardMetrica(label: 'horas rodadas', valor: formatarHoras((resumoSemana?['horas_total'] as num?)?.toDouble() ?? 0), cor: Cores.texto(context)),
                  _CardMetrica(label: 'km rodados', valor: '${((resumoSemana?['km_total'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} km', cor: Cores.texto(context)),
                  _CardMetrica(label: 'turnos', valor: '${resumoSemana?['total_turnos'] ?? 0}', cor: Cores.texto(context)),
                ],
              ),

              const SizedBox(height: 24),
              Text('GASTOS DE HOJE', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: card, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borda),
                ),
                child: Column(
                  children: [
                    _LinhaGasto(label: 'Combustível', valor: gastosHoje?['combustivel'] ?? 0),
                    _LinhaGasto(label: 'Manutenção', valor: gastosHoje?['manutencao'] ?? 0),
                    _LinhaGasto(label: 'Alimentação', valor: gastosHoje?['alimentacao'] ?? 0),
                    Divider(color: borda),
                    _LinhaGasto(label: 'Total', valor: gastosHoje?['total'] ?? 0, destaque: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('REGISTRAR', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.2,
                children: [
                  _BotaoAcao(label: '⛽ Abastecimento', onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AbastecimentoScreen()));
                    carregarDados();
                  }),
                  _BotaoAcao(label: '🔧 Manutenção', onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const ManutencaoScreen()));
                    carregarDados();
                  }),
                  _BotaoAcao(label: '🍽 Alimentação', onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AlimentacaoScreen()));
                    carregarDados();
                  }),
                  _BotaoAcao(label: '📊 Relatório', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RelatorioScreen()));
                  }),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMetrica extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;

  const _CardMetrica({required this.label, required this.valor, required this.cor});

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
        ],
      ),
    );
  }
}

class _LinhaGasto extends StatelessWidget {
  final String label;
  final double valor;
  final bool destaque;

  const _LinhaGasto({required this.label, required this.valor, this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: 14,
            color: destaque ? Cores.texto(context) : Cores.cinza(context),
            fontWeight: destaque ? FontWeight.w700 : FontWeight.normal,
          )),
          Text(formatarReais(valor), style: TextStyle(
            fontSize: 14,
            color: destaque ? Cores.amarelo(context) : Cores.texto(context),
            fontWeight: destaque ? FontWeight.w700 : FontWeight.normal,
          )),
        ],
      ),
    );
  }
}

class _BotaoAcao extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BotaoAcao({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Cores.card(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Cores.borda(context)),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, color: Cores.texto(context))),
      ),
    );
  }
}