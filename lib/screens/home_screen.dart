import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/calculos.dart';
import 'turno_screen.dart';
import 'abastecimento_screen.dart';
import 'manutencao_screen.dart';
import 'alimentacao_screen.dart';
import 'relatorio_screen.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF161616);
const _borda = Color(0xFF222222);
const _amarelo = Color(0xFFE8FF00);
const _branco = Color(0xFFF5F5F5);
const _cinza = Color(0xFF666666);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: carregarDados,
        color: _amarelo,
        backgroundColor: _card,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCardTurno(context),
              const SizedBox(height: 24),
              _buildSecao('ÚLTIMOS 7 DIAS'),
              const SizedBox(height: 12),
              _buildGridMetricas(),
              const SizedBox(height: 24),
              _buildSecao('GASTOS DE HOJE'),
              const SizedBox(height: 12),
              _buildCardGastos(),
              const SizedBox(height: 24),
              _buildSecao('REGISTRAR'),
              const SizedBox(height: 12),
              _buildGridAcoes(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4),
            children: [
              TextSpan(text: 'PIT', style: TextStyle(color: _branco)),
              TextSpan(text: 'BOX', style: TextStyle(color: _amarelo)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'controle da sua operação',
          style: TextStyle(fontSize: 12, color: _cinza, letterSpacing: 2),
        ),
      ],
    );
  }

  Widget _buildCardTurno(BuildContext context) {
    final ativo = turnoAtivo != null;
    final corBorda = ativo ? const Color(0xFF44FF88) : _borda;
    final corFundo = ativo ? const Color(0xFF0F1A0A) : _card;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TurnoScreen()),
        );
        carregarDados();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: corFundo,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: corBorda),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ativo ? 'TURNO ATIVO' : 'SEM TURNO ATIVO',
                  style: const TextStyle(fontSize: 10, color: _cinza, letterSpacing: 2),
                ),
                const SizedBox(height: 4),
                Text(
                  ativo
                      ? 'desde ${TimeOfDay.fromDateTime(DateTime.parse(turnoAtivo!['inicio_em'])).format(context)}'
                      : 'toque para iniciar',
                  style: const TextStyle(fontSize: 18, color: _branco, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: ativo ? const Color(0xFF44FF88) : _cinza,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecao(String label) {
    return Text(label, style: const TextStyle(fontSize: 10, color: _cinza, letterSpacing: 2));
  }

  Widget _buildGridMetricas() {
    final ganho = (resumoSemana?['ganho_total'] as num?)?.toDouble() ?? 0;
    final horas = (resumoSemana?['horas_total'] as num?)?.toDouble() ?? 0;
    final km = (resumoSemana?['km_total'] as num?)?.toDouble() ?? 0;
    final turnos = resumoSemana?['total_turnos'] ?? 0;

    return GridView.count(
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
        _CardMetrica(label: 'turnos', valor: '$turnos'),
      ],
    );
  }

  Widget _buildCardGastos() {
    final c = gastosHoje?['combustivel'] ?? 0;
    final m = gastosHoje?['manutencao'] ?? 0;
    final a = gastosHoje?['alimentacao'] ?? 0;
    final t = gastosHoje?['total'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borda),
      ),
      child: Column(
        children: [
          _LinhaGasto(label: 'Combustível', valor: c),
          _LinhaGasto(label: 'Manutenção', valor: m),
          _LinhaGasto(label: 'Alimentação', valor: a),
          const Divider(color: _borda),
          _LinhaGasto(label: 'Total', valor: t, destaque: true),
        ],
      ),
    );
  }

  Widget _buildGridAcoes(BuildContext context) {
    return GridView.count(
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
    );
  }
}

class _CardMetrica extends StatelessWidget {
  final String label;
  final String valor;
  final Color cor;

  const _CardMetrica({required this.label, required this.valor, this.cor = _branco});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borda),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: _cinza, letterSpacing: 1)),
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
            color: destaque ? _branco : _cinza,
            fontWeight: destaque ? FontWeight.w700 : FontWeight.normal,
          )),
          Text(formatarReais(valor), style: TextStyle(
            fontSize: 14,
            color: destaque ? _amarelo : _branco,
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
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borda),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14, color: _branco)),
      ),
    );
  }
}