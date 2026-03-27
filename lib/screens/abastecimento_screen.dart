import 'package:flutter/material.dart';
import '../database/queries.dart';

const _bg = Color(0xFF0D0D0D);
const _card = Color(0xFF161616);
const _borda = Color(0xFF222222);
const _amarelo = Color(0xFFE8FF00);
const _branco = Color(0xFFF5F5F5);
const _cinza = Color(0xFF666666);
const _vermelho = Color(0xFFFF4444);

class AbastecimentoScreen extends StatefulWidget {
  const AbastecimentoScreen({super.key});

  @override
  State<AbastecimentoScreen> createState() => _AbastecimentoScreenState();
}

class _AbastecimentoScreenState extends State<AbastecimentoScreen> {
  final litrosCtrl = TextEditingController();
  final valorCtrl = TextEditingController();
  final postoCtrl = TextEditingController();
  String combustivel = 'gasolina';

  final combustiveis = ['gasolina', 'etanol', 'diesel', 'gnv'];

  @override
  void dispose() {
    litrosCtrl.dispose();
    valorCtrl.dispose();
    postoCtrl.dispose();
    super.dispose();
  }

  String get precoPorLitro {
    final l = double.tryParse(litrosCtrl.text.replaceAll(',', '.')) ?? 0;
    final v = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0;
    if (l > 0 && v > 0) return 'R\$ ${(v / l).toStringAsFixed(3)}/litro';
    return '';
  }

  Future<void> handleSalvar() async {
    final l = double.tryParse(litrosCtrl.text.replaceAll(',', '.'));
    final v = double.tryParse(valorCtrl.text.replaceAll(',', '.'));

    if (l == null || v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Litros e valor são obrigatórios'), backgroundColor: _vermelho),
      );
      return;
    }

    final turno = await buscarTurnoAtivo();

    await registrarAbastecimento(
      turnoId: turno?['id'],
      litros: l,
      valorTotal: v,
      posto: postoCtrl.text.isNotEmpty ? postoCtrl.text : null,
      tipoCombustivel: combustivel,
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
            const Text('⛽ ABASTECIMENTO', style: TextStyle(
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
                  _label('Litros abastecidos *'),
                  _input(litrosCtrl, 'ex: 30.5', TextInputType.number,
                    onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  _label('Valor total pago (R\$) *'),
                  _input(valorCtrl, 'ex: 180.00', TextInputType.number,
                    onChanged: (_) => setState(() {})),
                  if (precoPorLitro.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(precoPorLitro, style: const TextStyle(fontSize: 13, color: _amarelo)),
                  ],
                  const SizedBox(height: 16),
                  _label('Tipo de combustível'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: combustiveis.map((c) => GestureDetector(
                      onTap: () => setState(() => combustivel = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: combustivel == c ? const Color(0xFF1A1A00) : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: combustivel == c ? _amarelo : _borda),
                        ),
                        child: Text(c, style: TextStyle(
                          color: combustivel == c ? _amarelo : _cinza, fontSize: 13,
                        )),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  _label('Posto (opcional)'),
                  _input(postoCtrl, 'nome do posto', TextInputType.text),
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

  Widget _input(TextEditingController ctrl, String hint, TextInputType tipo, {Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      onChanged: onChanged,
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