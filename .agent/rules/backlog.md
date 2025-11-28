---
trigger: always_on
---

### Backlog do Produto: Plataforma de Gestão de Repúblicas

Descrição: Documento inicial do backlog do produto, definindo os épicos e as histórias de usuário para o escopo da plataforma, incluindo funcionalidades de gestão, relatórios, dashboard e portal do ocupante.

#### Visão Geral do Produto
Este documento descreve o backlog do produto para a Plataforma de Gestão de Repúblicas. O objetivo principal da plataforma é fornecer uma ferramenta centralizada para que donos de repúblicas possam gerenciar ocupantes, registrar despesas de forma categorizada e gerar relatórios para a divisão de custos, seja de maneira igualitária ou proporcional à renda dos moradores.

A plataforma também visa oferecer transparência aos ocupantes através de um portal de acesso e fornecer ao administrador uma visão clara da saúde financeira da república por meio de um dashboard visual.

#### Personas
As funcionalidades descritas neste backlog foram pensadas para atender às necessidades das seguintes personas:

Dono da República: O administrador principal. É responsável por cadastrar a república, gerenciar ocupantes, lançar despesas e gerar os relatórios de divisão de contas.

Ocupante: O morador da república. Utiliza a plataforma para consultar os relatórios de despesas, visualizar seu histórico e entender o cálculo da sua parte a pagar.

#### Épicos do Produto
Os Épicos representam as grandes funcionalidades ou módulos da plataforma. Eles agrupam um conjunto de histórias de usuário relacionadas.

|ID|Título|Descrição|
|--|------|---------|
|EP01|Gestão da República e Ocupantes|Foca nas funcionalidades centrais de cadastro e gerenciamento das repúblicas e seus moradores.|
|EP02|Gestão de Despesas|Cobre todas as funcionalidades relacionadas ao lançamento e categorização das despesas da república.|
|EP03|Relatórios e Divisão de Contas|É o núcleo da funcionalidade de divisão de custos, permitindo gerar relatórios e calcular a parte de cada um.|
|EP04|Dashboard e Visualização de Dados|Apresenta ao Dono da República um painel visual com os principais indicadores e gráficos financeiros.|
|EP05|Acesso para Ocupantes (Portal do Morador)|Cria uma área de acesso para os moradores consultarem seus débitos, relatórios e histórico de forma transparente.|

4. Histórias de Usuário (Product Backlog)
A seguir, estão detalhadas as histórias de usuário que compõem cada épico. Cada história representa um requisito funcional da perspectiva de uma persona.

|ID|Épico (ID)|História de Usuário (Como um..., eu quero..., para que...)|
|--|----------|----------------------------------------------------------|
|HU01| EP01| Como um Dono da República, eu quero criar uma conta administrativa informando nome, e-mail e senha, para que eu possa ter acesso inicial à plataforma e configurar minha república.|
|HU02| EP01| Como um Dono da República, eu quero fazer login na plataforma usando meu e-mail e senha cadastrados, para que eu possa acessar o painel de gestão da minha república de forma segura.|
|HU03| EP01| Como um Dono da República, eu quero cadastrar minha república na plataforma informando nome, endereço e número de quartos, para que eu possa começar a gerenciá-la.|
|HU04| EP01| Como um Dono da República, eu quero adicionar novos ocupantes à minha república, cadastrando nome, e-mail e renda mensal, para que eu possa controlar quem mora no local e usar a renda para cálculos futuros.|
|HU05| EP01| Como um Dono da República, eu quero visualizar uma lista de todos os meus ocupantes com suas respectivas rendas, para que eu tenha uma visão geral dos moradores e suas capacidades financeiras.|
|HU06| EP01| Como um Dono da República, eu quero editar as informações de um ocupante (como a renda), para que eu possa manter os dados sempre atualizados.|
|HU07| EP01| Como um Dono da República, eu quero remover um ocupante que não mora mais na república, para que eu possa manter a lista de moradores precisa.|
|HU08| EP02| Como um Dono da República, eu quero cadastrar uma nova despesa, informando descrição, valor e data, para que eu possa manter um registro de todos os gastos da casa.|
|HU09| EP02| Como um Dono da República, eu quero criar e gerenciar categorias de despesas (ex: Contas Fixas, Alimentação), para que eu possa organizar melhor os gastos.|
|HU10| EP02| Como um Dono da República, eu quero criar e gerenciar subcategorias associadas a uma categoria principal, para que eu possa ter um nível de detalhe ainda maior.|
|HU11| EP02| Como um Dono da República, eu quero associar cada despesa a uma categoria e subcategoria no momento do cadastro, para que eu possa facilitar a análise e a geração de relatórios.|
|HU12| EP02| Como um Dono da República, eu quero visualizar um histórico de todas as despesas lançadas, com filtros por data e categoria, para que eu possa consultar os gastos passados facilmente.|
|HU13| EP03| Como um Dono da República, eu quero gerar um relatório de despesas para um período específico, para que eu possa consolidar todos os gastos e iniciar o processo de divisão.|
|HU14| EP03| Como um Dono da República, eu quero escolher o método de divisão das despesas como "Igualitária" ao gerar um relatório, para que o valor total seja dividido igualmente entre todos os ocupantes.|
|HU15| EP03| Como um Dono da República, eu quero escolher o método de divisão das despesas como "Proporcional à Renda" ao gerar um relatório, para que o custo seja distribuído de forma justa com base na renda de cada um.|
|HU16| EP03| Como um Dono da República, eu quero excluir despesas específicas do cálculo de divisão no relatório, para que gastos pessoais ou que não devem ser divididos não entrem na conta.|
|HU17| EP03| Como um Dono da República, eu quero exportar ou compartilhar o relatório final (em PDF ou um link), para que eu possa enviá-lo facilmente aos ocupantes.|
|HU18| EP04| Como um Dono da República, eu quero visualizar um dashboard principal com o resumo do mês atual (total de despesas, valor médio por ocupante), para que eu tenha uma visão rápida da situação financeira.|
|HU19| EP04| Como um Dono da República, eu quero ver um gráfico de pizza no dashboard que mostra a distribuição das despesas por categoria no mês, para que eu possa identificar rapidamente para onde o dinheiro está indo.|
|HU20| EP04| Como um Dono da República, eu quero ver um gráfico de barras no dashboard comparando o total de despesas dos últimos 6 meses, para que eu possa analisar tendências de gastos.|
|HU21| EP05| Como um Dono da República, eu quero poder enviar um convite por e-mail para um ocupante se cadastrar na plataforma, para que ele possa ter seu próprio acesso.|
|HU22| EP05| Como um Ocupante, eu quero poder me cadastrar e fazer login na plataforma usando meu e-mail e senha, para que eu possa acessar as informações da república.|
|HU23| EP05| Como um Ocupante, eu quero visualizar o último relatório de despesas e o valor exato que eu devo pagar, para que eu tenha clareza sobre minhas obrigações.|
|HU24| EP05| Como um Ocupante, eu quero acessar um histórico de todos os relatórios passados, para que eu possa consultar meus pagamentos e despesas anteriores.|