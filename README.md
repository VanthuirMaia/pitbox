# PitBox 🏁

> Construído por um motorista de app que também é engenheiro de IA.

Sou motorista por app e sei na pele o que a categoria enfrenta: movimento imprevisível, corridas baratas, custos invisíveis e zero controle sobre a própria operação. As plataformas ditam tudo, e o motorista não tem dados pra reagir.

O PitBox nasceu disso. Um app para o motorista entender de verdade quanto está ganhando, quanto está gastando, e onde está perdendo dinheiro.

Simples. Offline. No celular que já está na mão.

---

## O que o app faz

- **Ponto de turno** com rastreamento GPS em segundo plano
- **Registro financeiro** de abastecimento, manutenção e alimentação
- **Cálculo de rentabilidade real**: ganho por hora, ganho por km, lucro líquido
- **Relatório por período**: hoje, 7 dias, mês
- **100% offline**: tudo salvo localmente, sem depender de internet durante o turno

---

## A visão maior

O controle financeiro é o gancho. O dado coletivo é o ativo.

Com múltiplos motoristas usando o app, os dados de rota, horário e movimento formam um modelo de recomendação real, sem que ninguém precise reportar nada manualmente. O padrão emerge do comportamento.

A meta é simples: devolver ao motorista a inteligência que as plataformas têm e não compartilham.

---

## Stack

| Camada         | Tecnologia                      |
| -------------- | ------------------------------- |
| Mobile         | Flutter 3.41 (Android first)    |
| Banco local    | SQLite via sqflite              |
| GPS background | geolocator + workmanager        |
| Cálculos       | Dart puro, fórmula de Haversine |
| Backend        | Em breve (FastAPI + PostgreSQL) |

---

## Roadmap

### Fase 1 — MVP local (atual)

- [x] Ponto de turno com GPS em segundo plano
- [x] Registro de abastecimento, manutenção e alimentação
- [x] Relatório de rentabilidade por período
- [x] Ganho real por hora e por km

### Fase 2 — Inteligência individual

- [ ] Gráficos de evolução semanal e mensal
- [ ] Alerta de turno pouco rentável
- [ ] Comparativo entre turnos
- [ ] Exportação de dados (PDF/CSV)

### Fase 3 — Backend e sincronização

- [ ] FastAPI + PostgreSQL
- [ ] Sincronização ao finalizar turno
- [ ] Autenticação simples

### Fase 4 — Dado coletivo

- [ ] Heatmap de zonas quentes por horário
- [ ] Modelo de recomendação baseado em padrões reais
- [ ] Previsão de movimento por região

---

## Construído em público

Este projeto é desenvolvido abertamente como parte da minha jornada de Build in Public.

Acompanhe o processo no LinkedIn: [linkedin.com/in/vanthuirmaia](https://linkedin.com/in/vanthuirmaia)

---

## Status

🟡 Em desenvolvimento ativo. Sendo testado em condições reais pelo próprio criador.

---

_"Nunca perco. Quando não ganho, aprendo."_
