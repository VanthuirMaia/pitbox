import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/tema.dart';

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
        SnackBar(content: const Text('Litros e valor são obrigatórios'),
          backgroundColor: Cores.vermelho(context)),
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
            Text('⛽ ABASTECIMENTO', style: TextStyle(
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
                  _label(context, 'Litros abastecidos *'),
                  _input(context, litrosCtrl, 'ex: 30.5', TextInputType.number,
                    onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  _label(context, 'Valor total pago (R\$) *'),
                  _input(context, valorCtrl, 'ex: 180.00', TextInputType.number,
                    onChanged: (_) => setState(() {})),
                  if (precoPorLitro.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(precoPorLitro, style: TextStyle(fontSize: 13, color: amarelo)),
                  ],
                  const SizedBox(height: 16),
                  _label(context, 'Tipo de combustível'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: combustiveis.map((c) => GestureDetector(
                      onTap: () => setState(() => combustivel = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: combustivel == c
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1A1A00)
                                  : const Color(0xFFFFFDE0))
                              : Cores.inputFundo(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: combustivel == c ? amarelo : Cores.borda(context)),
                        ),
                        child: Text(c, style: TextStyle(
                          color: combustivel == c ? amarelo : cinza, fontSize: 13,
                        )),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  _label(context, 'Posto (opcional)'),
                  _input(context, postoCtrl, 'nome do posto', TextInputType.text),
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
                child: Text('SALVAR', style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0D0D0D)
                      : const Color(0xFF0D0D0D),
                  letterSpacing: 2,
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