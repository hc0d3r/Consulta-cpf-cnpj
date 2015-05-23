<?php

class ConsultaCPF
{
	private $cpf_number;
	private $errno;
	private $xml;

	const PASSWORD = 'Sup3RbP4ssCr1t0grPhABr4sil';
	const URL = 'https://movel01.receita.fazenda.gov.br/servicos-rfb/ConsultaCPF';

	public function SetCPF($cpf)
	{
		if( !$this->check_cpf($cpf) )
		{
			$this->errno = 0;
		}

		else
		{
			$this->cpf_number = $cpf;
		}
	}

	public function consultar()
	{
		if( !isset( $this->cpf_number ) )
		{
			return false;
		}

		$this->xml = $this->consulta_receita();

		if( isset( $this->errno ) )
		{
			return false;
		}


		return true;
	}

	private function consulta_receita(){
		$cpf = $this->cpf_number;
		unset($this->errno);

		$token = hash_hmac('sha1', $cpf, self::PASSWORD);
		$post_data = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\" ?><soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" ><soap:Header><token>${token}</token><aplicativo>Pessoa Física</aplicativo><plataforma>iPhone OS</plataforma><versao>8.3</versao><dispositivo>iPhone</dispositivo><versao_app>3.0</versao_app></soap:Header><soap:Body><soap:obtemSituacaoCadastral xmlns:soap=\"http://soap.ws.cpf.service.mobile.rfb.serpro.gov.br/\"><cpf>${cpf}</cpf></soap:obtemSituacaoCadastral></soap:Body></soap:Envelope>";

		$request = curl_init();

		curl_setopt($request, CURLOPT_URL, self::URL);
		curl_setopt($request, CURLOPT_POSTFIELDS, $post_data);
		curl_setopt($request, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($request, CURLOPT_SSL_VERIFYHOST, false);
		curl_setopt($request, CURLOPT_SSL_VERIFYPEER, false);

		$resp = curl_exec($request);

		if(! preg_match("/<ns3:MensagemRetorno>OK/", $resp) )
		{
			$this->errno = 1;
		}

		return $resp;
	}

	public function GetXml(){
		if( isset($this->xml) )
		{
			return $this->xml;
		}

		else
		{
			return NULL;
		}
	}

	public function error()
	{
		$errors = array('CPF Invalido', 'Consulta Falhou');

		if(! isset($this->errno) )
		{
			return "Sem erros";
		}

		else
		{
			if(count($errors) > $this->errno && $this->errno >= 0)
			{
				return $errors[$this->errno];
			}

			else
			{
				return "Erro desconhecido";
			}
		}

	}

	private function check_cpf($cpf)
	{
		if( ! preg_match("/^\d{11}$/", $cpf) )
		{
			return false;
		}

		return true;
	}

}


/*

:::Exemplo de uso:::

$cpf = new ConsultaCPF();
$cpf->SetCPF("13326724691");

if($cpf->consultar()){
	print $cpf->GetXml()."\n";
} else {
	print "Consulta falhou: \n";
	print $cpf->error()."\n";
}

*/
