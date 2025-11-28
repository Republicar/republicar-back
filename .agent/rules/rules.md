---
trigger: always_on
---

# Regras de Negócio

Este documento detalha as lógicas, restrições e fórmulas matemáticas que regem o comportamento da Plataforma de Gestão de Repúblicas.

---

## 1. Gestão de Atores e Entidades

### RN01 - Unicidade de Cadastro
* **Descrição:** Um endereço de e-mail pode estar associado a apenas **uma** conta de usuário (seja Dono ou Ocupante).
* **Restrição:** O sistema deve validar se o e-mail já existe no banco de dados antes de criar um novo registro.

### RN02 - Vínculo de Ocupantes
* **Descrição:** Um Ocupante só pode estar vinculado a uma República ativa por vez.
* **Comportamento:** Ao ser cadastrado, o Ocupante herda o ID da república do Dono que o cadastrou.

### RN03 - Renda Obrigatória para Modo Proporcional
* **Descrição:** Para habilitar a divisão proporcional, **todos** os ocupantes incluídos no cálculo devem ter uma renda maior ou igual a zero cadastrada.
* **Validação:** Se a renda de um ocupante estiver em branco (null), o sistema deve impedir a geração do relatório do tipo "Proporcional" ou solicitar o preenchimento.

---

## 2. Lógica de Despesas

### RN04 - Imutabilidade de Despesas em Relatórios Fechados
* **Descrição:** Uma despesa que já foi incluída em um Relatório de Despesas finalizado não pode ser editada ou excluída.
* **Exceção:** Se o relatório for excluído ou reaberto (funcionalidade futura), as despesas tornam-se editáveis novamente.

### RN05 - Categorização Obrigatória
* **Descrição:** Toda despesa deve pertencer obrigatoriamente a uma Categoria. A Subcategoria é opcional.

---

## 3. Cálculos de Divisão (Core)

### RN06 - Método de Divisão Igualitária
* **Contexto:** Ocorre quando o usuário seleciona o método "Igualitária" na HU14.
* **Fórmula:** ValorPorPessoa = (TotalDespesas - DespesasExcluidas)/NumeroDeOcupantesAtivos
* **Exceção:** Ocupantes marcados como "Inativos" ou removidos manualmente da lista de divisão (HU16) não entram no denominador da divisão.

### RN07 - Método de Divisão Proporcional à Renda
* **Contexto:** Ocorre quando o usuário seleciona o método "Proporcional" na HU15.
* **Lógica:** O sistema deve calcular o peso financeiro de cada morador em relação à renda total da casa.
* **Passo 1 (Cálculo da Renda Total):** RendaTotal = soma das rendas de todos os ocupante
* **Passo 2 (Cálculo do Fator de Proporção Individual):** Fator[i] = RendaOcupante[i]/RendaTotal
* **Passo 3 (Cálculo da Parte a Pagar):** ValorAPagar[i] = (TotalDespesas - DespesasExcluidas) * Fator[i]

#### **!!! Divisão por Zero**

Se a `RendaTotal` da casa for igual a **0**, o sistema deve bloquear o cálculo proporcional e sugerir o método igualitário, para evitar erro matemático de divisão por zero.

### RN08 - Tratamento de Arredondamento (Problema dos Centavos)
* **Descrição:** Ao dividir valores, frequentemente ocorrem dízimas (ex: 100 / 3 = 33,333...).
* **Regra:** O sistema deve trabalhar com precisão de 2 casas decimais.
* **Algoritmo de Ajuste:**
    1.  Calcular a divisão padrão arredondando para baixo (floor) na segunda casa decimal.
    2.  Somar todas as partes calculadas.
    3.  Calcular a diferença: Diferenca = ValorTotalOriginal - SomaDasPartes.
    4.  Atribuir a diferença (geralmente alguns centavos) a um ocupante aleatório ou ao próprio Dono da República para fechar a conta exata.

---

## 4. Relatórios e Visualização

### RN09 - Escopo do Relatório
* **Descrição:** Um relatório é delimitado por uma data de início e uma data de fim.
* **Comportamento:** O sistema deve buscar todas as despesas cuja `data_despesa` esteja dentro deste intervalo (inclusive).

### RN10 - Visibilidade do Ocupante
* **Descrição:** O Ocupante tem acesso de leitura aos relatórios onde ele consta como pagador.
* **Restrição:** O Ocupante **não** pode editar despesas, nem ver dados sensíveis (como a renda exata) de outros ocupantes, a menos que o Dono habilite a transparência total (configuração futura). No modo proporcional, o Ocupante vê apenas a porcentagem que ele representa, não necessariamente os valores absolutos de salário dos colegas.

---

## 5. Exemplo Prático de Cálculo (Cenário de Teste)

**Cenário:** Conta de Luz de R$ 400,00.
**Ocupantes:**
* Alice (Renda: R$ 3.000)
* Bob (Renda: R$ 1.000)

**Aplicação da RN07 (Proporcional):**

1.  **Renda Total:** $3.000 + $1.000 = $4.000

2.  **Fatores:**
    * Alice: $3.000 / $4.000 = 0,75 (75%)
    * Bob: $1.000 / $4.000 = 0,25 (25%)
3.  **Valores:**
    * Alice Paga: $400 * 0,75 = R$ 300,00
    * Bob Paga: $400 * 0,25 = R$ 100,00