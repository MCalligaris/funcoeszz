# ----------------------------------------------------------------------------
# http://www.dict.org
# Busca definições em inglês de palavras da língua inglesa em DICT.org.
# Uso: zzenglish palavra-em-inglês
# Ex.: zzenglish momentum
#
# Autor: Luciano ES
# Desde: 2008-09-07
# Versão: 3
# Licença: GPL
# ----------------------------------------------------------------------------
zzenglish ()
{
	zzzz -h english "$1" && return

	[ "$1" ] || { zztool uso english; return 1; }

	local url="http://www.dict.org/bin/Dict/"
	local query="Form=Dict1&Query=$1&Strategy=*&Database=*&submit=Submit query"
	local cinza verde amarelo fecha
	
	if [ $ZZCOR -eq 1 ]
	then
		cinza='\033[0;34m'
		verde='\033[0;32;1m'
		amarelo='\033[0;33;1m'
		fecha='\033[m'
	else
		cinza="''"
		verde="''"
		amarelo="''"
		fecha="''"
	fi

	echo "$query" |
		$ZZWWWPOST "$url" |
		sed "
			# pega o trecho da página que nos interessa
			/[0-9]\{1,\} definitions\{0,1\} found/,/_______________/!d
			s/____*//

			# protege os colchetes dos sinônimos contra o cinza escuro
			s/\[syn:/@SINONIMO@/g

			# aplica cinza escuro em todos os colchetes (menos sinônimos)
			s/\[/$(printf ${cinza})[/g

			# aplica verde nos colchetes dos sinônimos
			s/@SINONIMO@/$(printf ${verde})[syn:/g

			# \"fecha\" as cores de todos os sinônimos
			s/\]/]$(printf ${fecha})/g

			# pinta a pronúncia de amarelo - pode estar delimitada por \\ ou //
			s/\(\\\\[^\\]\{1,\}\\\\\)/$(printf ${amarelo})\\1\\$(printf ${fecha})/g
			s|\(/[^/]\+/\)|$(printf ${amarelo})\1$(printf ${fecha})|g

			# cabeçalho para tornar a separação entre várias consultas mais visível no terminal
			/[0-9]\{1,\} definitions\{0,1\} found/ {
				H
				s/.*/==================== DICT.ORG ====================/
				p
				x
			}"
}
