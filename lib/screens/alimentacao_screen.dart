import 'package:flutter/material.dart';
import '../database/queries.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF161616);
const _borda = Color(0xFF222222);
const _amarelo = Color(0xFFE8FF00);
const _branco = Color(0xFFF5F5F5);
const _cinza = Color(0xFF666666);
const _vermelho = Color(0xFFFF4444);

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
        const SnackBar(content: Text('Informe o valor'), backgroundColor: _vermelho),
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
            const Text('🍽 ALIMENTAÇÃO', style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.w900, color: _branco, letterSpacing: 2,
            )),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _borda),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Valor (R\$) *'),
                  _input(valorCtrl, 'ex: 18.00', TextInputType.number),
                  const SizedBox(height: 16),
                  _label('Descrição (opcional)'),
                  _input(descricaoCtrl, 'ex: almoço, lanche, água...', TextInputType.text),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: handleSalvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _amarelo,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SALVAR', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0D0D0D), letterSpacing: 2,
                )),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 12, color: _cinza, letterSpacing: 1)),
  );

  Widget _input(TextEditingController ctrl, String hint, TextInputType tipo) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      style: const TextStyle(color: _branco, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: _cinza),
        filled: true, fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _borda)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _borda)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _amarelo)),
      ),
    );
  }
}