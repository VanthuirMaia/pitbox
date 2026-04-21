import 'dart:async';
import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/calculos.dart';
import '../services/tema.dart';

const _plataformas = ['99', 'Uber', 'InDriver', 'Particular', 'Outro'];

class EditarTurnoScreen extends StatefulWidget {
  final Map<String, dynamic> turno;

  const EditarTurnoScreen({super.key, required this.turno});

  @override
  State<EditarTurnoScreen> createState() => _EditarTurnoScreenState();
}

class _EditarTurnoScreenState extends State<EditarTurnoScreen> {
  final kmInicialCtrl = TextEditingController();
  final kmFinalCtrl = TextEditingController();
  final corridasCtrl = TextEditingController();

  late DateTime inicioEm;
  late DateTime fimEm;

  final Map<String, TextEditingController> ganhoCtrl = {};
  final List<String> plataformasSelecionadas = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final t = widget.turno;

    inicioEm = DateTime.parse(t['inicio_em']);
    fimEm = t['fim_em'] != null
        ? DateTime.parse(t['fim_em'])
        : DateTime.now();

    kmInicialCtrl.text = t['km_inicial']?.toString() ?? '';
    kmFinalCtrl.text = t['km_final']?.toString() ?? '';
    corridasCtrl.text = t['total_corridas']?.toString() ?? '';

    // carrega plataformas existentes
    final plataformas = await buscarGanhosPorPlataforma(t['id']);
    setState(() {
      for (final p in plataformas) {
        final nome = p['plataforma'] as String;
        plataformasSelecionadas.add(nome);
        ganhoCtrl[nome] = TextEditingController(text: p['ganho']?.toString() ?? '');
      }
    });
  }

  @override
  void dispose() {
    kmInicialCtrl.dispose();
    kmFinalCtrl.dispose();
    corridasCtrl.dispose();
    for (final c in ganhoCtrl.values) c.dispose();
    super.dispose();
  }

  void togglePlataforma(String p) {
    setState(() {
      if (plataformasSelecionadas.contains(p)) {
        plataformasSelecionadas.remove(p);
        ganhoCtrl[p]?.dispose();
        ganhoCtrl.remove(p);
      } else {
        plataformasSelecionadas.add(p);
        ganhoCtrl[p] = TextEditingController();
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

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final data = isInicio ? inicioEm : fimEm;

    final novaData = await showDatePicker(
      context: context,
      initialDate: data,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (novaData == null) return;

    final novaHora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(data),
    );
    if (novaHora == null) return;

    final novo = DateTime(
      novaData.year, novaData.month, novaData.day,
      novaHora.hour, novaHora.minute,
    );

    setState(() {
      if (isInicio) {
        inicioEm = novo;
      } else {
        fimEm = novo;
      }
    });
  }

  Future<void> handleSalvar() async {
    if (totalGanho <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Informe o ganho de ao menos uma plataforma'),
          backgroundColor: Cores.vermelho(context),
        ),
      );
      return;
    }

    if (fimEm.isBefore(inicioEm)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Horário de fim não pode ser antes do início'),
          backgroundColor: Cores.vermelho(context),
        ),
      );
      return;
    }

    final totalCorridas = plataformasSelecionadas.fold<int>(0, (soma, p) {
      return soma + (int.tryParse(corridasCtrl.text) ?? 0);
    });

    await atualizarTurno(
      widget.turno['id'],
      inicioEm: inicioEm.toIso8601String(),
      fimEm: fimEm.toIso8601String(),
      kmInicial: kmInicialCtrl.text.isNotEmpty
          ? double.tryParse(kmInicialCtrl.text.replaceAll(',', '.'))
          : null,
      kmFinal: kmFinalCtrl.text.isNotEmpty
          ? double.tryParse(kmFinalCtrl.text.replaceAll(',', '.'))
          : null,
      ganhoBruto: totalGanho,
      totalCorridas: totalCorridas,
    );

    // atualiza ganhos por plataforma
    await limparGanhosPorPlataforma(widget.turno['id']);
    for (final p in plataformasSelecionadas) {
      final ganho = double.tryParse(ganhoCtrl[p]?.text.replaceAll(',', '.') ?? '') ?? 0;
      if (ganho > 0) {
        await salvarGanhoPorPlataforma(widget.turno['id'], p, 0, ganho);
      }
    }

    if (mounted) Navigator.pop(context, true);
  }

  String _formatarDataHora(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} às ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final amarelo = Cores.amarelo(context);
    final cinza = Cores.cinza(context);
    final texto = Cores.texto(context);
    final horas = calcularHoras(inicioEm.toIso8601String(), fimEm.toIso8601String());

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
            Text('EDITAR TURNO', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: texto, letterSpacing: 2,
            )),
            const SizedBox(height: 24),

            // horários
            Text('HORÁRIOS', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
            const SizedBox(height: 12),
            _buildCard(context, children: [
              _label(context, 'Início do turno'),
              _botaoHorario(context, _formatarDataHora(inicioEm), () => _selecionarData(context, true)),
              const SizedBox(height: 16),
              _label(context, 'Fim do turno'),
              _botaoHorario(context, _formatarDataHora(fimEm), () => _selecionarData(context, false)),
              const SizedBox(height: 8),
              Text(
                'Duração: ${formatarHoras(horas)}',
                style: TextStyle(fontSize: 13, color: amarelo),
              ),
            ]),

            const SizedBox(height: 16),
            Text('HODÔMETRO', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
            const SizedBox(height: 12),
            _buildCard(context, children: [
              _label(context, 'Km inicial'),
              _input(context, kmInicialCtrl, 'km ao iniciar', TextInputType.number),
              const SizedBox(height: 16),
              _label(context, 'Km final'),
              _input(context, kmFinalCtrl, 'km ao finalizar', TextInputType.number),
            ]),

            const SizedBox(height: 16),
            Text('PLATAFORMAS E GANHOS', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
            const SizedBox(height: 12),

            _buildCard(context, children: [
              _label(context, 'Apps utilizados'),
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

            if (plataformasSelecionadas.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...plataformasSelecionadas.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildCard(context, children: [
                  Text(p, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: amarelo)),
                  const SizedBox(height: 12),
                  _label(context, 'Ganho (R\$)'),
                  _input(context, ganhoCtrl[p]!, 'ex: 45.00', TextInputType.number,
                    onChanged: (_) => setState(() {})),
                ]),
              )),

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

            const SizedBox(height: 16),
            Text('CORRIDAS', style: TextStyle(fontSize: 10, color: cinza, letterSpacing: 2)),
            const SizedBox(height: 12),
            _buildCard(context, children: [
              _label(context, 'Total de corridas'),
              _input(context, corridasCtrl, 'quantidade total', TextInputType.number),
            ]),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: handleSalvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: amarelo,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SALVAR ALTERAÇÕES', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900,
                  color: Color(0xFF0D0D0D), letterSpacing: 2,
                )),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
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

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 12, color: Cores.cinza(context), letterSpacing: 1)),
  );

  Widget _botaoHorario(BuildContext context, String valor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Cores.inputFundo(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Cores.borda(context)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(valor, style: TextStyle(fontSize: 16, color: Cores.inputTexto(context))),
            Icon(Icons.edit, size: 16, color: Cores.cinza(context)),
          ],
        ),
      ),
    );
  }

  Widget _input(BuildContext context, TextEditingController ctrl, String hint, TextInputType tipo, {Function(String)? onChanged}) {
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Cores.borda(context))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Cores.borda(context))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Cores.amarelo(context))),
      ),
    );
  }
}