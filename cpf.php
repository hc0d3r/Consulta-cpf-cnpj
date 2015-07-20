<?php

class ConsultaCPF
{
	private $cpf_number;
	private $data_nasc;
	private $errno;
	private $json;

	const PASSWORD = 'Sup3RbP4ssCr1t0grPhABr4sil';
	const URL = 'https://movel01.receita.fazenda.gov.br/servicos-rfb/v2/IRPF/cpf';

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

	public function SetNasc($data){
		$this->data_nasc = $data;
	}

	public function consultar()
	{
		if( !isset( $this->cpf_number ) )
		{
			return false;
		}

		$this->json = $this->consulta_receita();

		if( isset( $this->errno ) )
		{
			return false;
		}


		return true;
	}

	private function consulta_receita(){
		$cpf = $this->cpf_number;
		$data_nasc = $this->data_nasc;
		$token = hash_hmac('sha1', $cpf.$data_nasc, self::PASSWORD);

		$headers = array(
			"token: ${token}",
			"plataforma: iPhone OS",
			"dispositivo: iPhone",
			"aplicativo: Pessoa Física",
			"versao: 8.3",
			"versao_app: 4.1"
		);

		unset($this->errno);

		$post_data = "cpf=${cpf}&dataNascimento=${data_nasc}";

		$request = curl_init();

		curl_setopt($request, CURLOPT_URL, self::URL);
		curl_setopt($request, CURLOPT_POSTFIELDS, $post_data);
		curl_setopt($request, CURLOPT_RETURNTRANSFER, true);
		curl_setopt($request, CURLOPT_SSL_VERIFYHOST, false);
		curl_setopt($request, CURLOPT_SSL_VERIFYPEER, false);
		curl_setopt($request, CURLOPT_HTTPHEADER, $headers);

		$resp = curl_exec($request);

		if( preg_match("/Tente novamente mais tarde/", $resp) )
		{
			$this->errno = 1;
		}

		return $resp;
	}

	public function GetJson(){
		if( isset($this->json) )
		{
			return $this->json;
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
$cpf->SetNasc("14121947"); // dia mes ano

if($cpf->consultar()){
	print $cpf->Getjson()."\n";
} else {
	print "Consulta falhou: \n";
	print $cpf->error()."\n";
}
*/

