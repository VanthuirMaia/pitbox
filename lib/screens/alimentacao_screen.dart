import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/tema.dart';

class AlimentacaoScreen extends StatefulWidget {
  const AlimentacaoScreen({super.key});

  @override
  State<AlimentacaoScreen> createState() => _AlimentacaoScreenState();
}

class _AlimentacaoScreenState extends State<AlimentacaoScreen> {
  final valorCtrl = TextEditingController();
  final descricaoCtrl = TextEditingController();

  @override
  void dispose() {
    valorCtrl.dispose();
    descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> handleSalvar() async {
    final v = double.tryParse(valorCtrl.text.replaceAll(',', '.'));

    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Informe o valor'),
          backgroundColor: Cores.vermelho(context)),
      );
      return;
    }

    final turno = await buscarTurnoAtivo();
    await registrarAlimentacao(
      turnoId: turno?['id'],
      descricao: descricaoCtrl.text.isNotEmpty ? descricaoCtrl.text : null,
      valor: v,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
            Text('🍽 ALIMENTAÇÃO', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: texto, letterSpacing: 2,
            )),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Cores.card(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Cores.borda(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(context, 'Valor (R\$) *'),
                  _input(context, valorCtrl, 'ex: 18.00', TextInputType.number),
                  const SizedBox(height: 16),
                  _label(context, 'Descrição (opcional)'),
                  _input(context, descricaoCtrl, 'ex: almoço, lanche, água...', TextInputType.text),
                ],
              ),
            ),
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
                child: const Text('SALVAR', style: TextStyle(
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

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 12, color: Cores.cinza(context), letterSpacing: 1)),
  );

  Widget _input(BuildContext context, TextEditingController ctrl, String hint, TextInputType tipo) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
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