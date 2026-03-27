import 'dart:async';
import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/gps.dart';
import '../services/calculos.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF161616);
const _borda = Color(0xFF222222);
const _amarelo = Color(0xFFE8FF00);
const _branco = Color(0xFFF5F5F5);
const _cinza = Color(0xFF666666);
const _verde = Color(0xFF44FF88);
const _vermelho = Color(0xFFFF4444);

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
  final ganhoBrutoCtrl = TextEditingController();
  String duracao = '';

  @override
  void initState() {
    super.initState();
    carregarEstado();
    // atualiza duração a cada 30 segundos
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (turnoAtivo != null) atualizarDuracao();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    kmInicialCtrl.dispose();
    kmFinalCtrl.dispose();
    ganhoBrutoCtrl.dispose();
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

  Future<void> handleIniciar() async {
    final km = kmInicialCtrl.text.isNotEmpty
        ? double.tryParse(kmInicialCtrl.text.replaceAll(',', '.'))
        : null;

    final id = await iniciarTurno(kmInicial: km);
    final sucesso = await iniciarRastreamento(id);

    if (!sucesso && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS em segundo plano não autorizado. Verifique as permissões.'),
          backgroundColor: _vermelho,
        ),
      );
    }

    await carregarEstado();
  }

  Future<void> handleFinalizar() async {
    if (turnoAtivo == null) return;

    if (ganhoBrutoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o ganho do turno'), backgroundColor: _vermelho),
      );
      return;
    }

    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text('Finalizar turno?', style: TextStyle(color: _branco)),
        content: const Text('Confirma o encerramento?', style: TextStyle(color: _cinza)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar', style: TextStyle(color: _vermelho)),
          ),
        ],
      ),
    );

    if (confirma != true) return;

    final km = kmFinalCtrl.text.isNotEmpty
        ? double.tryParse(kmFinalCtrl.text.replaceAll(',', '.'))
        : null;
    final ganho = double.tryParse(ganhoBrutoCtrl.text.replaceAll(',', '.')) ?? 0;

    await finalizarTurno(turnoAtivo!['id'], kmFinal: km, ganhoBruto: ganho);
    await pararRastreamento();

    setState(() {
      turnoAtivo = null;
      rastreando = false;
      duracao = '';
    });

    kmInicialCtrl.clear();
    kmFinalCtrl.clear();
    ganhoBrutoCtrl.clear();

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            const Text('TURNO', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: _branco, letterSpacing: 4,
            )),
            const SizedBox(height: 24),
            turnoAtivo == null ? _buildIniciar() : _buildFinalizar(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIniciar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NOVO TURNO', style: TextStyle(fontSize: 10, color: _cinza, letterSpacing: 2)),
        const SizedBox(height: 12),
        _buildCard(children: [
          _buildLabel('Hodômetro atual (opcional)'),
          _buildInput(kmInicialCtrl, 'km atual do carro', TextInputType.number),
        ]),
        const SizedBox(height: 16),
        _buildBotao('INICIAR TURNO', _amarelo, const Color(0xFF0D0D0D), handleIniciar),
      ],
    );
  }

  Widget _buildFinalizar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _verde),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TURNO EM ANDAMENTO', style: TextStyle(fontSize: 10, color: _verde, letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(
                'iniciado às ${TimeOfDay.fromDateTime(DateTime.parse(turnoAtivo!['inicio_em'])).format(context)}',
                style: const TextStyle(fontSize: 14, color: _cinza),
              ),
              const SizedBox(height: 8),
              Text(duracao.isEmpty ? '—' : duracao, style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.w900, color: _branco,
              )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: rastreando ? _verde : _cinza,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rastreando ? 'GPS registrando rota' : 'GPS inativo',
                    style: TextStyle(fontSize: 13, color: rastreando ? _verde : _cinza),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('FINALIZAR TURNO', style: TextStyle(fontSize: 10, color: _cinza, letterSpacing: 2)),
        const SizedBox(height: 12),
        _buildCard(children: [
          _buildLabel('Ganho bruto do turno (R\$) *'),
          _buildInput(ganhoBrutoCtrl, 'quanto você recebeu', TextInputType.number),
          const SizedBox(height: 16),
          _buildLabel('Hodômetro final (opcional)'),
          _buildInput(kmFinalCtrl, 'km do carro agora', TextInputType.number),
        ]),
        const SizedBox(height: 16),
        _buildBotao('FINALIZAR TURNO', _vermelho, _branco, handleFinalizar),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borda),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _cinza, letterSpacing: 1)),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, TextInputType tipo) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      style: const TextStyle(color: _branco, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _cinza),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _amarelo),
        ),
      ),
    );
  }

  Widget _buildBotao(String label, Color cor, Color corTexto, VoidCallback onTap) {
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