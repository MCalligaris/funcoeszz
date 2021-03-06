# ----------------------------------------------------------------------------
# Resultados da quina, megasena, duplasena, lotomania, lotofácil, federal e timemania.
# Se o 2º argumento for um número, pesquisa o resultado filtrando o concurso.
# Se nenhum argumento for passado, todas as loterias são mostradas.
#
# Uso: zzloteria2 [[quina|megasena|duplasena|lotomania|lotofacil|federal|timemania|loteca] concurso]
# Ex.: zzloteria2
#      zzloteria2 quina megasena
#
# Autor: Itamar <itamarnet (a) yahoo com br>
# Desde: 2009-10-04
# Versão: 4
# Licença: GPL
# Requisitos: zzseq zzsemacento
# ----------------------------------------------------------------------------
zzloteria2 ()
{
	zzzz -h loteria2 "$1" && return

	local dump numero_concurso data resultado acumulado tipo ZZWWWDUMP2
	local resultado_val resultado_num num_con sufixo faixa
	local url='http://www1.caixa.gov.br/loterias/loterias'
	local tipos='quina megasena duplasena lotomania lotofacil federal timemania loteca'

	if type links >/dev/null 2>&1
	then
		ZZWWWDUMP2='links -dump'
	else
		ZZWWWDUMP2=$ZZWWWDUMP
		#echo 'Favor instalar o "links"'
		#echo 'Site da caixa não responde com o "lynx" usado na variável $ZZWWWDUMP'
		#return 1
	fi

	# Caso o segundo argumento seja um numero, filtra pelo concurso equivalente
	zztool testa_numero "$2"
	if ([ $? -eq 0 ])
	then
		num_con="?submeteu=sim&opcao=concurso&txtConcurso=$2"
		tipos="$1"
	else
	# Caso contrario mostra todos os tipos, ou alguns selecionados
		unset num_con
		[ "$1" ] && tipos="$*"
	fi

	# Para cada tipo de loteria...
	for tipo in $tipos
	do

		# Há várias pegadinhas neste código. Alguns detalhes:
		# - A variável $dump é um cache local do resultado
		# - É usado ZZWWWDUMP2+filtros (e não ZZWWWHTML) para forçar a saída em UTF-8
		# - O resultado é deixado como uma única longa linha
		# - O resultado são vários campos separados por pipe |
		# - Cada tipo de loteria traz os dados em posições (e formatos) diferentes :/

		case "$tipo" in
			duplasena)
				sufixo="_pesquisa_new.asp"
			;;
			*)
				sufixo="_pesquisa.asp"
			;;
		esac

		dump=$($ZZWWWDUMP2 "$url/$tipo/${tipo}${sufixo}$num_con" |
				tr -d \\n |
				sed 's/  */ /g ; s/^ //')

		# O número do concurso é sempre o primeiro campo
		numero_concurso=$(echo "$dump" | cut -d '|' -f 1)

		case "$tipo" in
			lotomania)
				# O resultado vem separado em campos distintos. Exemplo:
				# |01|04|06|12|21|25|27|36|42|44|50|51|53|59|68|69|74|78|87|91|91|

				data=$(     echo "$dump" | cut -d '|' -f 42)
				acumulado=$(echo "$dump" | cut -d '|' -f 69,70)
				resultado=$(echo "$dump" | cut -d '|' -f 7-26 |
					sed 's/|/@/10 ; s/|/ - /g' |
					tr @ '\n'
				)
				faixa=$(zzseq -f "\t%d ptos\n" 20 1 16)
				faixa=$(echo "${faixa}\n\t 0 ptos")
				resultado_num=$(echo "$dump" | cut -d '|' -f 28,30,32,34,36,38 | tr '|' '\n')
				resultado_val=$(echo "$dump" | cut -d '|' -f 29,31,33,35,37,39 | tr '|' '\n')
			;;
			lotofacil)
				# O resultado vem separado em campos distintos. Exemplo:
				# |01|04|07|08|09|10|12|14|15|16|21|22|23|24|25|
				resultado=$(echo "$dump" | cut -d '|' -f 4-18 |
					sed 's/|/@/10 ; s/|/@/5 ; s/|/ - /g' |
					tr @ '\n'
				)
				faixa=$(zzseq -f "\t%d ptos\n" 15 1 11)
				resultado_num=$(echo "$dump" | cut -d '|' -f 19,21,23,25,27 | tr '|' '\n')
				resultado_val=$(echo "$dump" | cut -d '|' -f 20,22,24,26,28 | tr '|' '\n')
				dump=$(    echo "$dump" | sed 's/.*Estimativa de Pr//')
				data=$(     echo "$dump" | cut -d '|' -f 6)
				acumulado=$(echo "$dump" | cut -d '|' -f 25,26)
			;;
			megasena)
				# O resultado vem separado por asteriscos. Exemplo:
				# | * 16 * 58 * 43 * 37 * 52 * 59 |

				data=$(     echo "$dump" | cut -d '|' -f 12)
				acumulado=$(echo "$dump" | cut -d '|' -f 22,23)
				resultado=$(echo "$dump" | cut -d '|' -f 21 |
					tr '*' '-'  |
					tr '|' '\n' |
					sed 's/^ - //'
				)
				faixa=$(echo "\tSena|\tQuina|\tQuadra"| tr '|' '\n')
				resultado_num=$(echo "$dump" | cut -d '|' -f 4,6,8 | tr '|' '\n')
				resultado_val=$(echo "$dump" | cut -d '|' -f 5,7,9 | tr '|' '\n')
			;;
			duplasena)
				# O resultado vem separado por asteriscos, tendo dois grupos
				# numéricos: o primeiro e segundo resultado. Exemplo:
				# | * 05 * 07 * 09 * 21 * 38 * 40 | * 05 * 17 * 20 * 22 * 31 * 45 |

				data=$(     echo "$dump" | cut -d '|' -f 18)
				acumulado=$(echo "$dump" | cut -d '|' -f 23,24)
				resultado=$(echo "$dump" | cut -d '|' -f 4,5 |
					tr '*' '-'  |
					tr '|' '\n' |
					sed 's/^ - //'
				)
				faixa=$(echo "\t1ª Sena|\t1ª Quina|\t1ª Quadra||\t2ª Sena|\t2ª Quina|\t2ª Quadra" | tr '|' '\n')
				resultado_num=$(echo "$dump" | awk 'BEGIN {FS="|";OFS="\n"} {print $7,$26,$28,"",$9,$10,$13}')
				resultado_val=$(echo "$dump" | awk 'BEGIN {FS="|";OFS="\n"} {print $8,$27,$29,"",$11,$12,$14}')
			;;
			quina)
				# O resultado vem duplicado em um único campo, sendo a segunda
				# parte o resultado ordenado numericamente. Exemplo:
				# | * 69 * 42 * 13 * 56 * 07 * 07 * 13 * 42 * 56 * 69 |

				data=$(     echo "$dump" | cut -d '|' -f 17)
				acumulado=$(echo "$dump" | cut -d '|' -f 18,19)
				resultado=$(echo "$dump" | cut -d '|' -f 15 |
					sed 's/\* /|/6' |
					tr '*' '-'  |
					tr '|' '\n' |
					sed 's/^ - // ; 1d'
				)
				faixa=$(echo "\tQuina|\tQuadra|\tTerno" | tr '|' '\n')
				resultado_num=$(echo "$dump" | cut -d '|' -f 7,9,11 | tr '|' '\n')
				resultado_val=$(echo "$dump" | cut -d '|' -f 8,10,12 | tr '|' '\n')
			;;
			federal)
				data=$(     echo "$dump" | cut -d '|' -f 17)
				numero_concurso=$(echo "$dump" | cut -d '|' -f 3)
				unset acumulado
				resultado_num=$(echo "$dump" | cut -d '|' -f 7,9,11,13,15 |
					tr '*' '-'  |
					tr '|' '\n' |
					sed 's/^ - //'
				)
				resultado_val=$(echo "$dump" | cut -d '|' -f 8,10,12,14,16 |
					tr '*' '-'  |
					tr '|' '\n' |
					sed 's/^ - //'
				)

				resultado=$(paste <(zzseq -f "%dº Prêmio\n" 1 1 5) <(echo "$resultado_num") <(echo "$resultado_val"))
				unset faixa resultado_num resultado_val
			;;
			timemania)
				data=$(     echo "$dump" | cut -d '|' -f 2)
				acumulado=$(echo "$dump" | cut -d '|' -f 24)
				acumulado=${acumulado}"|"$(echo "$dump" | cut -d '|' -f 23)
				resultado=$(echo "$dump" | cut -d '|' -f 8 |
					tr '*' '-'  |
					tr '|' '\n' |
					sed 's/^ - //'
				)
				resultado=$(echo -e ${resultado}"\nTime: "$(echo "$dump" | cut -d '|' -f 9))
				faixa=$(zzseq -f "\t%d ptos\n" 7 1 3)
				resultado_num=$(echo "$dump" | cut -d '|' -f 10,12,14,16,18 | tr '|' '\n')
				resultado_val=$(echo "$dump" | cut -d '|' -f 11,13,15,17,19 | tr '|' '\n')
			;;
			loteca)
				dump=$(     echo "$dump" | sed 's/[A-Z]|[A-Z]/-/g')
				data=$(     echo "$dump" | awk -F"|" '{print $(NF-4)}' )
				acumulado=$(echo "$dump" | awk -F"|" '{print $(NF-1) "|" $(NF)}' )
				acumulado="${acumulado}_Acumulado para a 1ª faixa "$(echo "$dump" | awk -F"|" '{print $(NF-5)}' )
				acumulado="${acumulado}_"$(echo "$dump" | awk -F"|" '{print $(NF-2)}' )
				acumulado=$(echo "${acumulado}" | sed 's/_/\n   /g;s/ Valor //' )
				resultado=$(printf "$dump" | cut -d '|' -f 4 |
				sed 's/ [0-9] [0-9]* /\n &/g;s/ [0-9]\{2\} [0-9]*/\n&/g' |
				sed '1d' |
				zzsemacento |
				sed 's|\(/[A-Z]\{2\}\) \(JUNIOR\)|-JR\1|g' |
				awk '{
					printf "Jogo %02d ", $1
						Time=""
						for (i = 3; i < NF-1; i++)
							{
							Time = Time " " $i
							if (index($i,"/")>0)
								{
								if (i < NF-2)  printf "%-24s %2s X %-2s", Time, $2, $(NF-1)
								if (i == NF-2) printf "%24s", Time
								Time=""
								}
							}
					if ( length(Time)>0 ) {
						if (split(Time, arr_time) == 2)
							printf " %-23s %2s X %-2s %23s", arr_time[1], $2, $(NF-1), arr_time[2]
						else
							printf "%2s X %-2s %-47s ", $2, $(NF-1), "(" Time " )"
						}
					if ( $2 > $(NF-1) ) printf " %s\n", "- Col.  1 "
					if ( $2 == $(NF-1) ) printf " %s\n", "- Col. Meio"
					if ( $2 < $(NF-1) ) printf " %s\n", "- Col.  2"
					#printf " %-3s\n", $(NF)

					}')
				faixa=$(zzseq -f '\t%d\n' 14 13)
				resultado_num=$(echo "$dump" | cut -d '|' -f 5 | sed 's/ [12].\{1,2\} (1[34] acertos)/\n/g;' | sed '1d' | sed 's/[0-9] /&\t/g')
				unset resultado_val
			;;
		esac

		# Mostra o resultado na tela (caso encontrado algo)
		if [ "$resultado" ]
		then
			zztool eco $tipo:
			echo "$resultado" | sed 's/^/   /'
			echo "   Concurso $numero_concurso ($data)"
			[ "$acumulado" ] && echo "   Acumulado em R$ $acumulado" | sed 's/|/ para /'
			if [ "$faixa" ]
			then
				echo -e "\tFaixa\tQtde.\tPrêmio" | expand -t 5,17,32
				paste <(echo -e "$faixa" | zzsemacento) <(echo -e "$resultado_num") <(echo -e "$resultado_val") | expand -t 5,17,32
			fi
			echo
		fi
	done
}
