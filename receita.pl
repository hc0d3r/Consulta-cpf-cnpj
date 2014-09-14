#!/usr/bin/perl -w

# Autor: MMxM [ hc0der.blogspot.com ]

use strict;
use LWP;
use Digest::MD5;
use Getopt::Long;
use Encode;
use HTTP::Cookies;
use constant SOUND_SPLIT =>
	'sox /tmp/captcha.wav /tmp/split.wav silence 1 0.1 1% 1 0.4 1% : newfile : restart';

$| = 1;

our($hashs,$xfh);
open(my $fh,'<hash.txt') || die("Arquivo com os hash's nao foi encontrado");
my @tmpz = <$fh>;
$hashs = join '',@tmpz;

sub ajuda {
	print " Opções:\n\n";
	print "  --cpf <numero de cpf>\n";
	print "  --cnpj <numero do cnpj>\n";
	print "  --lista-cpf <arquivo com lista de cpf>\n";
	print "  --lista-cnpj <arquivo com lista de cnpj>\n";
	print "  --captcha <guid do captcha>\n";
	print "  -o <arquivo de saida>\n\n";
	exit;
}

sub solve_captcha {
	my $captcha;
	for(1..6){
		my $file = '/tmp/split00'.$_.'.wav';
		open(my $fh,'<'.$file) || return 0;
		my $checksum = Digest::MD5->new->addfile($fh)->hexdigest;
		if($hashs =~ /$checksum (.*)/){
			$captcha .= $1;
		} else {
			close($fh);
			return 0;
		}
		close($fh);
	}
	return $captcha;
}

sub captcha_download {
	my $ua = new LWP::UserAgent;
	my $audio = $ua->get('http://www.receita.fazenda.gov.br/'.shift)->content;
	open (my $fh, ">/tmp/captcha.wav");
	binmode($fh);
	print $fh $audio;
	close($fh);
	system(SOUND_SPLIT);
}

sub consulta {
	my $tipo = shift;
	my $nn = shift;
	print "[*] Consultando ".($tipo == 1 ? "CPF" : "CNPJ").": $nn\n";

	my $url;
	my $url2;

	if($tipo == 1){
		$url = 'http://www.receita.fazenda.gov.br/aplicacoes/atcta/cpf/ConsultaPublica.asp';
		$url2 = 'http://www.receita.fazenda.gov.br/aplicacoes/atcta/cpf/ConsultaPublicaExibir.asp';
	} else {
		$url = 'http://www.receita.fazenda.gov.br/pessoajuridica/cnpj/cnpjreva/Cnpjreva_Solicitacao2.asp';
		$url2 = 'http://www.receita.fazenda.gov.br/pessoajuridica/cnpj/cnpjreva/valida.asp';
	}

	print "[+] Acessando o site da Receita Federal ...";
	my $ua = new LWP::UserAgent;
	$ua->cookie_jar({});
	$ua->agent('Mozilla/5.0 (Windows NT 6.2; rv:31.0) Gecko/20100101 Firefox/31.0');

	my $req = $ua->get($url);
	my $body = $req->content;

	my $viewstate;

	if($body =~ /id=viewstate name=viewstate value='(.*?)'/){
		$viewstate = $1;
	} else {
		warn "Erro inesperado ...\n";
		return;
	}

	my $captcha;

	if($body =~ /<img border='0' id='imgcaptcha' alt='(.*)' src='(.*?)'>/){
		$captcha = $2;
	} else {
		warn "Erro inesperado ...\n";
		return;
	}

	print "Ok !!!\n";

	$captcha =~ s/&amp;/&/gi;
	$captcha =~ s/type\=rca/type\=cah/gi;

	print "[*] Baixando arquivo de audio ...";
	&captcha_download($captcha);
	print "Ok !!!\n";

	print "[+] Resolvendo Captcha: ";
	my $resposta_captcha = solve_captcha();

	if($resposta_captcha eq '0'){
		warn "Erro ao resolver captcha =/\n";
		return;
	}

	print $resposta_captcha."\n";
	print "[*] Efetuando consulta de situação cadastral ...\n";

	my %parameters;

	$parameters{viewstate} = $viewstate;
	$parameters{captcha} = $resposta_captcha;
	$parameters{captchaAudio} = '';
	

	if($tipo == 1){
		$parameters{Enviar} = 'Consultar';
		$parameters{txtCPF} = $nn;
	} else {
		$parameters{origem} = 'comprovante';
		$parameters{submit1} = 'Consultar';
		$parameters{cnpj} = $nn;
	}

	my $dados = $ua->post($url2, \%parameters)->content;
	if($tipo == 1){
	my $con = encode 'utf8', $dados;
	if($con =~ /CPF incorreto/){
		print "\n[-] CPF Incorreto\n\n";
		return;
	}
	if($con =~ /<span class="clConteudoDados">Nome da Pessoa F(.*)sica: (.*?)<\/span>/){
		print "\nNome da Pessoa Física: ".$2."\n";
		print $xfh "\nCPF $nn\nNome da Pessoa Física: ".$2."\n" if($xfh);
	} else {
		warn "\n[-] Erro inesperado\n\n";
		return;
	}

	if($con =~ /<span class="clConteudoDados">Situa(.*)o Cadastral: (.*?)<\/span>/){
		print "Situação Cadastral: $2\n";
		print $xfh "Situação Cadastral: $2\n" if($xfh);
	}

	if($con =~ /<span class="clConteudoComp">Comprovante emitido (.*)s: (.*?)<\/span>/){
		my $x = $2;
		$x =~ s/<\/?b>//g;
		print "Comprovante emitido às: $x\n";
		print $xfh "Comprovante emitido às: $x\n" if($xfh);
	}

	if($con =~ /<span class="clConteudoComp">C(.*)digo de controle do comprovante: <b>(.*?)<\/b><\/span>/){
		print "Código de controle do comprovante: $2\n\n";
		print $xfh "Código de controle do comprovante: $2\n\n" if($xfh);
	}
	return;
	}

	if($dados =~ /Cnpjreva_Vstatus.asp/){
		my $con = encode 'utf8', $ua->get('http://www.receita.fazenda.gov.br/pessoajuridica/cnpj/cnpjreva/Cnpjreva_Vstatus.asp?origem=comprovante&cnpj='.$nn)->content;
		if($con =~ /Verifique se o mesmo foi digitado corretamente/){
			warn "\n[-] CNPJ Incorreto\n\n";
			return;
		}

		my @lol = $con =~ m/<b>(.*?)<\/b>/g;
		if(scalar(@lol)<10){
			warn "\n[-] Erro inesperado\n\n";
			return;
		}

		my $res;
		$res .= "\nNumero de Inscrição: $lol[2] $lol[3]\n";
		$res .=  "Data de Abertura: $lol[4]\n";
		$res .=  "Nome Empresarial: $lol[5]\n";
		$res .=  "Titulo do Estabelecimento: $lol[6]\n";
		$res .=  "Código e Descrição da Atividade Econômica Principal:\n$lol[7]\n";
		$res .=  "Código e Descrição das Atividades Econômicas Secundárias:\n$lol[8]\n";
		$res .=  "Código e Descrição da Natureza Jurídica: $lol[9]\n";
		$res .=  "Logradouro:\n$lol[10]\n";
		$res .=  "Número: $lol[11]\n";
		$res .=  "CEP: $lol[13]\n";
		$res .=  "Bairro/Distrito: $lol[14]\n";
		$res .=  "Município: $lol[15]\n";
		$res .=  "UF: $lol[16]\n";
		$res .=  "Situação Cadastral: $lol[18]\n";
		$res .=  "Data da situação cadastral: $lol[19]\n\n";
		print $res;
		print $xfh "\nCNPJ: $nn" if $xfh;
		print $xfh $res if $xfh;
	} else {
		warn "\n[-] Erro inesperado\n\n";
		return;
	}
}

my($cpf,$cnpj,$lista_cpf,$lista_cnpj,$captcha_url,$help,$output);

print "\n[*] Receita Federal Captcha bypass";
print "\n[+] Autor: MMXM [ hc0der.blogspot.com ]\n\n";

GetOptions(
	'cpf=s' => \$cpf,
	'cnpj=s' => \$cnpj,
	'lista-cpf=s' => \$lista_cpf,
	'lista-cnpj=s' => \$lista_cnpj,
	'captcha=s' => \$captcha_url,
	'o=s' => \$output,
	'h' => \$help,
);


&ajuda if($help);
die("Use o parametro -h para obter ajuda\n\n") if(!$cpf && !$cnpj && !$lista_cpf && !$lista_cnpj && !$captcha_url);

if($output){
	if(!open($xfh,'>>'.$output)){
		warn "[-] Erro ao abrir arquivo '$output', os resultados não serão salvos\n";
	}
}

if($cpf){
	if($cpf =~ /(\d+){11}/){
		&consulta(1,$cpf);
	} else {
		warn "[-] Numero de CPF Invalido ...\n\n";
	}

}

if($cnpj){
	if($cnpj =~ /(\d+){14}/){
		&consulta(2,$cnpj);
	} else {
		warn "[-] Numero de CNPJ Invalido ...\n\n";
	}
}

if($lista_cpf){
	if(open(my $fh,'<'.$lista_cpf)){
		while(<$fh>){
			chomp;
			next if($_ =~ /^$/);
			if($_ =~ /^(\d+){11}$/){
				&consulta(1,$_);
			} else {
				warn "[-] Numero de CPF Invalido ...\n\n";
			}
		}
	} else {
		warn "[-] Erro ao abrir o arquivo $lista_cpf '$!'\n";
	}
}

if($lista_cnpj){
	if(open(my $fh,'<'.$lista_cnpj)){
		while(<$fh>){
			chomp;
			next if($_ =~ /^$/);
			if($_ =~ /^(\d+){14}$/){
				&consulta(2,$_);
			} else {
				warn "[-] Numero de CNPJ Invalido ...\n\n";
			}
		}
	} else {
		warn "[-] Erro ao abrir o arquivo $lista_cnpj '$!'\n";
	}
}

if($captcha_url){
	print "\n[+] Resolvendo captcha '$captcha_url'\n";
	print "[*] Baixando ...\n";
	my $r = 'scripts/captcha/Telerik.Web.UI.WebResource.axd?type=cah&guid='.$captcha_url;
	&captcha_download($r);
	my $goku = solve_captcha();
	if($goku eq '0'){
		print "[-] Erro ao solucionar captcha =/\n\n";
	} else {
		print "[+] Captcha solucionado: $goku\n\n";
	}
}

for(1..7){
	unlink '/tmp/split00'.$_.'.wav';
}
unlink '/tmp/captcha.wav';

close $xfh if $xfh;
