import 'package:flutter/material.dart';
import '../database/queries.dart';
import '../services/tema.dart';

class AbastecimentoScreen extends StatefulWidget {
  const AbastecimentoScreen({super.key});

  @override
  State<AbastecimentoScreen> createState() => _AbastecimentoScreenState();
}

class _AbastecimentoScreenState extends State<AbastecimentoScreen> {
  final valorCtrl = TextEditingController();
  final precoPorLitroCtrl = TextEditingController();
  final postoCtrl = TextEditingController();
  String combustivel = 'gasolina';

  final combustiveis = ['gasolina', 'etanol', 'diesel', 'gnv'];

  @override
  void dispose() {
    valorCtrl.dispose();
    precoPorLitroCtrl.dispose();
    postoCtrl.dispose();
    super.dispose();
  }

  double get litrosCalculados {
    final v = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0;
    final p = double.tryParse(precoPorLitroCtrl.text.replaceAll(',', '.')) ?? 0;
    if (v > 0 && p > 0) return v / p;
    return 0;
  }

  Future<void> handleSalvar() async {
    final v = double.tryParse(valorCtrl.text.replaceAll(',', '.'));
    final p = double.tryParse(precoPorLitroCtrl.text.replaceAll(',', '.'));

    if (v == null || p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Valor total e preço por litro são obrigatórios'),
          backgroundColor: Cores.vermelho(context)),
      );
      return;
    }

    final litros = v / p;
    final turno = await buscarTurnoAtivo();

    await registrarAbastecimento(
      turnoId: turno?['id'],
      litros: litros,
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
    final litros = litrosCalculados;

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
                  _label(context, 'Valor total pago (R\$) *'),
                  _input(context, valorCtrl, 'ex: 180.00', TextInputType.number,
                    onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  _label(context, 'Preço por litro (R\$) *'),
                  _input(context, precoPorLitroCtrl, 'ex: 6.29', TextInputType.number,
                    onChanged: (_) => setState(() {})),
                  if (litros > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF0F0F00)
                            : const Color(0xFFFFFDE0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: amarelo),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Litros abastecidos', style: TextStyle(fontSize: 13, color: cinza)),
                          Text('${litros.toStringAsFixed(2)}L',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: amarelo)),
                        ],
                      ),
                    ),
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