/*
  Script para campos customizados do Redmine

  1. Esse arquivo deve ser colocado no diretório public/javascripts

  2. Deve ser adicionado a linha abaixo no final do arquivo app/views/issues/_form.html.erb
     <%= javascript_include_tag 'custom_fields' %>

  3. Os valores das variáveis devem ser modificados de acordo com os 'ids' dos campos
     personalizados no Redmine instalado
*/

var campoAfetaReceita     = '#issue_custom_field_values_4';
var campoCriticidade      = '#issue_custom_field_values_5';
var campoComplexidade     = '#issue_custom_field_values_6';
var campoGrauDeSeveridade = '#issue_custom_field_values_7';
var campoTempoEstimado    = '#issue_estimated_hours';
var campoEstado           = '#issue_status_id';
var campoDataDeFim        = '#issue_due_date';

$(document).ready(function() {
  $(campoCriticidade).keyup(function(e) {
    e.preventDefault();
    defineGrauDeSeveridade();
  });

  $(campoCriticidade).click(function(e) {
    e.preventDefault();
    defineGrauDeSeveridade();
  });

  $(campoComplexidade).keyup(function(e) {
    e.preventDefault();
    defineGrauDeSeveridade();
  });

  $(campoComplexidade).click(function(e) {
    e.preventDefault();
    defineGrauDeSeveridade();
  });

  $(campoAfetaReceita).click(function(e) {
    defineAltoGrauDeSeveridade($(this));
  });

  $(campoEstado).keyup(function(e) {
    e.preventDefault();
    dataFinalDaTarefa();
  });

  $(campoEstado).click(function(e) {
    e.preventDefault();
    dataFinalDaTarefa();
  });
});

/*
                  Complexidade
Criticidade | Baixa | Média | Alta
Baixa       |   1   |   2   |  3
Média       |   2   |   3   |  4
Alta        |   3   |   4   |  5
*/
var defineGrauDeSeveridade = function() {
  valorCriticidade  = $(campoCriticidade).val();
  valorComplexidade = $(campoComplexidade).val();

  grauDeSeveridade = {
    'BaixaBaixa': 1,
    'BaixaMédia': 2,
    'BaixaAlta': 3,
    'MédiaBaixa': 2,
    'MédiaMédia': 3,
    'MédiaAlta': 4,
    'AltaBaixa': 3,
    'AltaMédia': 4,
    'AltaAlta': 5
  }

  $(campoGrauDeSeveridade).val( grauDeSeveridade[ valorCriticidade + valorComplexidade ] );

  defineTempoEstimado();
}

var defineAltoGrauDeSeveridade = function(checkbox) {
  if ((checkbox).is(':checked')) {
    $(campoCriticidade).val('Alta');
    $(campoComplexidade).val('Alta');
    $(campoGrauDeSeveridade).val(5);
    defineTempoEstimado();
  }
}

var defineTempoEstimado = function() {
  tempoEstimadoEmHoras = { 1: 30, 2: 24, 3: 18, 4: 12, 5: 6 }

  $(campoTempoEstimado).val( tempoEstimadoEmHoras[ $(campoGrauDeSeveridade).val() ] );
}

var dataFinalDaTarefa = function() {
  nomeEstado = $(campoEstado + ' option:selected').text();

  if ($(campoDataDeFim).val() == '') {
    if (nomeEstado == 'Fechado' || nomeEstado == 'Fechada') {
      $(campoDataDeFim).val(obterDataAtual());
    }
  }
}

var obterDataAtual = function() {
  hoje = new Date(Date.now()).toLocaleString();

  return hoje.substring(6, 10) + '-' + hoje.substring(3, 5) + '-' + hoje.substring(0, 2);
}
