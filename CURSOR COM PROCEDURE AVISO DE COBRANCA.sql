/*Rferreira contato: ferreiraphf@yahoo.com.br

*no caso abaixo estamso trabalhando com sistema ERP Protheus e sua tabela da TOTVS
* comando para criar procedure  CREATE PROCEDURE Envio_CobrancaAvencer
* comando para alterar procedure  ALTER PROCEDURE Envio_CobrancaAvencer
* comando para execultar procedure EXEC Envio_CobrancaAvencer
* Utilizado os comando abaixo completos execução total
* apenas feito separação para sabermos quais momentos 
* de execução estão sendo realizaod cada linha
*/

/*#################################################
 * Declaração das variaveis que recebe as 
 *  informações
#################################################*/
  
	  
DECLARE	@profile_name sysname, --FileName (nome de configuração do e-mail dataemail exemplo = ContaGmail)
        @recipients   varchar(max), -- emails que seram enviados conforme select
        @subject      nvarchar(255), -- Assunto do e-mail
        @body         nvarchar(max), -- Corpo do e-mail 
        @body_format  varchar(max), -- Formato do Texto se é TEXT OU HTML
        @copy_recipients varchar(max) = NULL,
		@blind_copy_recipients varchar(max) =NULL, 
		@E1_FILIAL VARCHAR(2), @E1_PREFIXO VARCHAR(5),@E1_NUM VARCHAR(9),
		@E1_TIPO VARCHAR(4),@E1_CLIENTE VARCHAR(6),@E1_VALOR VARCHAR(60),@E1_EMISSAO VARCHAR(12), 
		@E1_VENCREA VARCHAR(12),@A1_EMAIL VARCHAR(90),@A1_NOME VARCHAR(90)

/*#################################################
 Cursor para percorrer os nomes dos objetos 
#################################################*/
DECLARE cursor_receber CURSOR FOR  --declarando nome do cursor pode dar o nome que desejar
		SELECT E1_FILIAL, E1_PREFIXO, 
			   E1_NUM, E1_TIPO, 
			   E1_CLIENTE,  
			   SUM(E1_VALOR) AS E1_VALOR,convert(varchar,CONVERT(date,E1_EMISSAO,110),103) as E1_EMISSAO,      
			   convert(varchar,CONVERT(date,E1_VENCREA,110),103) as E1_VENCREA,A1_EMAIL,RTRIM(LTRIM(A1_NOME)) AS A1_NOME
			 FROM SE1020 SE1
			 INNER JOIN SA1020 SA1 ON SA1.A1_COD = E1_CLIENTE AND SA1.D_E_L_E_T_<>'*'
		WHERE SE1.D_E_L_E_T_<>'*'
		AND E1_VENCREA =CONVERT(varchar(8),GETDATE()+4,112)
    GROUP BY E1_FILIAL, E1_PREFIXO,E1_NUM, E1_TIPO,E1_CLIENTE,E1_EMISSAO,E1_VENCREA,A1_EMAIL,A1_NOME
		
/*#################################################
* Abrindo Cursor para leitura
#################################################*/
OPEN cursor_receber

/*#################################################
* Lendo a próxima linha
* Breve emplicação caso este vendo depois do INTO 
*  temos 2 variaveis que ja foram declaradas 
*  enteiromentes la em cima, se observar o SELECT 
*  temos destacado 2 campos na mesma sequencia que 
*  abaixo estamos abrindo o cursor assim fazendo 
*  uma consulta rapida das informações  
* para pular linha no sql basta colocar CHAR(10)
#################################################*/
FETCH NEXT FROM cursor_receber INTO @E1_FILIAL,@E1_PREFIXO,@E1_NUM,@E1_TIPO,@E1_CLIENTE,@E1_VALOR,@E1_EMISSAO,@E1_VENCREA,@A1_EMAIL,@A1_NOME

/*#################################################
* Percorrendo linhas do cursor (enquanto houverem)
#################################################*/
WHILE @@FETCH_STATUS = 0
BEGIN

	SELECT @profile_name ='ContaGmail'
    SELECT @recipients = @A1_EMAIL 
    SELECT @subject ='Comunicado de vencimento'  
	SELECT @body = 'Prezado(a) Senhor(a)' +CHAR(10)+  + CHAR(10) +
  'Vimos pela presente informar a V.Sa. que se encontra a vencer , junto à empresa' + CHAR(10) +
  @A1_NOME  + ' '+ 'representado por  '  + @E1_NUM + '  no valor de  R$' +@E1_VALOR + CHAR(10) +
  'referente à vendas de mercadorias, cujo vencimento será  em  ' + @E1_VENCREA + '. ' + CHAR(10) +
  + CHAR(10) +
  'Caso necessite do boleto para pagamento, solicite respondendo este e-mail.' + CHAR(10) +
  'At.' + CHAR(10) +
  'Depto Financeiro' 
       
  SELECT @body_format ='TEXT'

    EXEC msdb.dbo.sp_send_dbmail @profile_name,@recipients,@copy_recipients,@blind_copy_recipients,@subject ,@body,@body_format;

    -- Lendo a próxima linha
    FETCH NEXT FROM cursor_receber INTO @E1_FILIAL,@E1_PREFIXO,@E1_NUM,@E1_TIPO,@E1_CLIENTE,@E1_VALOR,@E1_EMISSAO,@E1_VENCREA,@A1_EMAIL,@A1_NOME 
END

-- Fechando Cursor para leitura
CLOSE cursor_receber

-- Desalocando o cursor
DEALLOCATE cursor_receber

