import 'dart:async';
import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/gps.dart';
import '../services/calculos.dart';
import '../services/tema.dart';

const _plataformas = ['99', 'Uber', 'InDriver', 'Particular', 'Outro'];

class TurnoScreen extends StatefulWidget {
  const TurnoScreen({super.key});

  @override
  State<TurnoScreen> createState() => _TurnoScreenState();
}

class _TurnoScreenState extends State<TurnoScreen> {
  Timer? _timer;
  Map<String, dynamic>? turnoAtivo;
  bool rastreando = false;
  final kmInicialCtrl = TextEditingController();
  final kmFinalCtrl = TextEditingController();
  String duracao = '';

  // ganho por plataforma
  final Map<String, TextEditingController> ganhoCtrl = {};
  final Map<String, TextEditingController> corridasCtrl = {};
  final List<String> plataformasSelecionadas = [];

  @override
  void initState() {
    super.initState();
    carregarEstado();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (turnoAtivo != null) atualizarDuracao();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    kmInicialCtrl.dispose();
    kmFinalCtrl.dispose();
    for (final c in ganhoCtrl.values) c.dispose();
    for (final c in corridasCtrl.values) c.dispose();
    super.dispose();
  }

  Future<void> carregarEstado() async {
    final turno = await buscarTurnoAtivo();
    final gps = await estaRastreando();
    setState(() {
      turnoAtivo = turno;
      rastreando = gps;
    });
    atualizarDuracao();
  }

  void atualizarDuracao() {
    if (turnoAtivo == null) return;
    final horas = calcularHoras(turnoAtivo!['inicio_em'], DateTime.now().toIso8601String());
    setState(() => duracao = formatarHoras(horas));
  }

  void togglePlataforma(String p) {
    setState(() {
      if (plataformasSelecionadas.contains(p)) {
        plataformasSelecionadas.remove(p);
        ganhoCtrl[p]?.dispose();
        ganhoCtrl.remove(p);
        corridasCtrl[p]?.dispose();
        corridasCtrl.remove(p);
      } else {
        plataformasSelecionadas.add(p);
        ganhoCtrl[p] = TextEditingController();
        corridasCtrl[p] = TextEditingController();
      }
    });
  }

  double get totalGanho {
    double total = 0;
    for (final p in plataformasSelecionadas) {
      total += double.tryParse(ganhoCtrl[p]?.text.replaceAll(',', '.') ?? '') ?? 0;
    }
    return total;
  }

  Future<void> handleIniciar() async {
    final km = kmInicialCtrl.text.isNotEmpty
        ? double.tryParse(kmInicialCtrl.text.replaceAll(',', '.'))
        : null;

    final id = await iniciarTurno(kmInicial: km);
    final sucesso = await iniciarRastreamento(id);

    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('GPS em segundo plano não autorizado.'),
          backgroundColor: Cores.vermelho(context),
        ),
      );
    }

    await carregarEstado();
  }

  Future<void> handleFinalizar() async {
    if (turnoAtivo == null) return;

    if (plataformasSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione ao menos uma plataforma'),
          backgroundColor: Cores.vermelho(context),
        ),
      );
      return;
    }

    if (totalGanho <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Informe o ganho de ao menos uma plataforma'),
          backgroundColor: Cores.vermelho(context),
        ),
      );
      return;
    }

    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Cores.card(context),
        title: Text('Finalizar turno?', style: TextStyle(color: Cores.texto(context))),
        content: Text(
          'Ganho total: ${formatarReais(totalGanho)}',
          style: TextStyle(color: Cores.cinza(context)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Finalizar', style: TextStyle(color: Cores.vermelho(context))),
          ),
        ],
      ),
    );

    if (confirma != true) return;

    final km = kmFinalCtrl.text.isNotEmpty
        ? double.tryParse(kmFinalCtrl.text.replaceAll(',', '.'))
        : null;

    final totalCorridas = plataformasSelecionadas.fold<int>(0, (soma, p) {
      return soma + (int.tryParse(corridasCtrl[p]?.text ?? '') ?? 0);
    });

    await finalizarTurno(
      turnoAtivo!['id'],
      kmFinal: km,
      ganhoBruto: totalGanho,
      totalCorridas: totalCorridas,
    );

    // salva ganho por plataforma
    for (final p in plataformasSelecionadas) {
      final ganho = double.tryParse(ganhoCtrl[p]?.text.replaceAll(',', '.') ?? '') ?? 0;
      final corridas = int.tryParse(corridasCtrl[p]?.text ?? '') ?? 0;
      if (ganho > 0) {
        await salvarGanhoPorPlataforma(turnoAtivo!['id'], p, corridas, ganho);
      }
    }

    await pararRastreamento();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bg = Cores.bg(context);
    final cinza = Cores.cinza(context);
    final texto = Cores.texto(context);

    return Scaffold(
      backgroundColor: bg,
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
            Text('TURNO', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: texto, letterSpacing: 4,
            )),
            const SizedBox(height: 24),
            turnoAtivo == null ? _buildIniciar(context) : _buildFinalizar(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIniciar(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NOVO TURNO', style: TextStyle(fontSize: 10, color: Cores.cinza(context), letterSpacing: 2)),
        const SizedBox(height: 12),
        _buildCard(context, children: [
          _buildLabel(context, 'Hodômetro atual (opcional)'),
          _buildInput(context, kmInicialCtrl, 'km atual do carro', TextInputType.number),
        ]),
        const SizedBox(height: 16),
        _buildBotao(context, 'INICIAR TURNO', Cores.amarelo(context), const Color(0xFF0D0D0D), handleIniciar),
      ],
    );
  }

  Widget _buildFinalizar(BuildContext context) {
    final verde = Cores.verde(context);
    final cinza = Cores.cinza(context);
    final texto = Cores.texto(context);
    final amarelo = Cores.amarelo(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // card turno ativo
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F1A0A)
                : const Color(0xFFEEFFEE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: verde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TURNO EM ANDAMENTO', style: TextStyle(fontSize: 10, color: verde, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(
                'iniciado às ${TimeOfDay.fromDateTime(DateTime.parse(turnoAtivo!['inicio_em'])).format(context)}',
                style: TextStyle(fontSize: 14, color: cinza),
              ),
              const SizedBox(height: 8),
              Text(duracao.isEmpty ? '—' : duracao, style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.w900, color: texto,
              )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: rastreando ? verde : cinza,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rastreando ? 'GPS registrando rota' : 'GPS inativo',
                    style: TextStyle(fontSize: 13, color: rastreando ? verde : cinza),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        Text('FINALIZAR TURNO', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
        const SizedBox(height: 12),

        // seleção de plataformas
        _buildCard(context, children: [
          _buildLabel(context, 'Quais apps você usou?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _plataformas.map((p) {
              final selecionado = plataformasSelecionadas.contains(p);
              return GestureDetector(
                onTap: () => togglePlataforma(p),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1A1A00)
                            : const Color(0xFFFFFDE0))
                        : Cores.inputFundo(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selecionado ? amarelo : Cores.borda(context)),
                  ),
                  child: Text(p, style: TextStyle(
                    color: selecionado ? amarelo : cinza, fontSize: 13,
                  )),
                ),
              );
            }).toList(),
          ),
        ]),

        // inputs por plataforma
        if (plataformasSelecionadas.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...plataformasSelecionadas.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCard(context, children: [
              Text(p, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: amarelo,
              )),
              const SizedBox(height: 12),
              _buildLabel(context, 'Ganho (R\$) *'),
              _buildInput(context, ganhoCtrl[p]!, 'ex: 45.00', TextInputType.number,
                onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              _buildLabel(context, 'Corridas'),
              _buildInput(context, corridasCtrl[p]!, 'quantidade de corridas', TextInputType.number),
            ]),
          )),

          // total calculado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0F0F00)
                  : const Color(0xFFFFFDE0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: amarelo),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL DO TURNO', style: TextStyle(fontSize: 12, color: cinza, letterSpacing: 1)),
                Text(formatarReais(totalGanho), style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, color: amarelo,
                )),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),
        _buildCard(context, children: [
          _buildLabel(context, 'Hodômetro final (opcional)'),
          _buildInput(context, kmFinalCtrl, 'km do carro agora', TextInputType.number),
        ]),

        const SizedBox(height: 16),
        _buildBotao(context, 'FINALIZAR TURNO', Cores.vermelho(context), Colors.white, handleFinalizar),
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Cores.card(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Cores.borda(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 12, color: Cores.cinza(context), letterSpacing: 1)),
    );
  }

  Widget _buildInput(BuildContext context, TextEditingController ctrl, String hint, TextInputType tipo, {Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      onChanged: onChanged,
      style: TextStyle(color: Cores.inputTexto(context), fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Cores.cinza(context)),
        filled: true,
        fillColor: Cores.inputFundo(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Cores.borda(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Cores.borda(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Cores.amarelo(context)),
        ),
      ),
    );
  }

  Widget _buildBotao(BuildContext context, String label, Color cor, Color corTexto, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w900,
          color: corTexto, letterSpacing: 2,
        )),
      ),
    );
  }
}