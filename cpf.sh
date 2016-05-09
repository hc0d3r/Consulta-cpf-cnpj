#!/bin/bash

PASSWORD='Sup3RbP4ssCr1t0grPhABr4sil'
URL='https://movel01.receita.fazenda.gov.br/servicos-rfb/v2/IRPF/cpf'


OPENSSL=`which openssl`
if [[ -z "$OPENSSL" ]]; then #se vazio
    echo "openssl não encontrado!"
    exit
fi

CURL=`which curl`
if [[ -z "$CURL" ]]; then #se vazio
    echo "curl não encontrado!"
    exit
fi

CPF=$1
if [[ -z "$CPF" ]]; then #se vazio
    echo "CPF não informado"
    exit
fi

CPF=$(echo $CPF | tr -d -c 0123456789) # limpa todos os caracteres que não for número.
if [[ ${#CPF} != 11 ]]; then # verifica o tamanho do CPF
    echo "CPF inválido!"
    exit
fi

NASCIMENTO=$2
if [[ -z "$NASCIMENTO" ]]; then #se vazio
    echo "Data de nascimetno não informada"
    exit
fi

NASCIMENTO=$(echo $NASCIMENTO | tr -d -c 0123456789) #limpa todos os caracteres que não for número.
if [[ ${#NASCIMENTO} != 8 ]]; then #verifica o tamanho da data de nascimento
    echo "Data de nascimento inválida!"
    exit
fi

TOKEN=`echo -n "$CPF$NASCIMENTO" | openssl sha1 -hmac "$PASSWORD" | awk '{print $NF}'`


RETORNO=`curl $URL -s -k -H "token: $TOKEN" -H "plataforma: iPhone OS" -H "dispositivo: iPhone" -H "aplicativo: Pessoa Física" -H "versao: 8.3" -H "versao_app: 4.1" -d "cpf=$CPF&dataNascimento=$NASCIMENTO" 2>&1`

MENSAGEM=`echo $RETORNO | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^mensagemRetorno/ {print $2}' | tr -d '"'`
EXCEPTION=`echo $RETORNO | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^exception/ {print $2}' | tr -d '"'`
if [[ $MENSAGEM != 'OK' ]]; then # verifica o retorno
    echo $MENSAGEM
    echo $EXCEPTION
    exit
fi

NOME=`echo $RETORNO | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^nome/ {print $2}' | tr -d '"'`
SITUACAO=`echo $RETORNO | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^descSituacaoCadastral/ {print $2}' | tr -d '"'`
DATA_INSCRICAO=`echo $RETORNO | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^dataIsncricao/ {print $2}' | tr -d '"'`
DATA_OBITO=`echo $RETORNO | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^anoObito/ {print $2}' | tr -d '"'`
INFO_OBITO=`echo $RETORNO | sed -e 's/[{}]/''/g' | awk -v RS=',"' -F: '/^mensagemObito/ {print $2}' | tr -d '"'`


echo "NOME: $NOME"
echo "SITUAÇÃO: $SITUACAO"
echo "DATA INSCRIÇÃO: $DATA_INSCRICAO"
echo "ÓBITO: $DATA_OBITO - $INFO_OBITO"
