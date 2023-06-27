USE [DB_RADIAN]
GO
/****** Object:  StoredProcedure [dbo].[SP_FiltroNumeros]    Script Date: 27/06/2023 2:17:18 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sebastian Montoya
-- Create date: 28/03/2023
-- Description:	Procedimiento almacenado que se encarga de generar el filtro de números y la primera regla del proceso de excepciones
-- =============================================
ALTER PROCEDURE [dbo].[SP_FiltroNumeros]
-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- EXTRACCIÓN DEL DIA DE INSERCIÓN DE DATA.
		SELECT * INTO #TransaccionDia
		FROM RAD_Comercial1 
		WHERE CONVERT(VARCHAR(10),[RADCOM_fecha_insercion],101) >= CONVERT(VARCHAR(10),GETDATE(),101);

	-- MEMORIA DEL ROBOT PARA PROCESADOS
		SELECT T.*
		INTO #TranNProcesadas
		FROM #TransaccionDia T
		LEFT JOIN [dbo].[RAD_Procesados] P
		ON LTRIM(RTRIM(T.RADCOM_numero_documento)) = LTRIM(RTRIM(P.PRO_Documento))
		WHERE P.PRO_Documento IS NULL
		ORDER BY T.RADCOM_numero_documento ASC;

	-- FILTRO FLUJO NORMAL
		SELECT RADCOM_pedido,RTRIM(LTRIM(RADCOM_numero_documento)) AS RADCOM_numero_documento,RADCOM_nit_documento,RADCOM_Proceso 
		INTO #tblFNormal
		FROM #TranNProcesadas
		WHERE ISNUMERIC(RADCOM_pedido) = 1 and LEN(RADCOM_pedido) = 6;

	-- FILTRO FLUJO ALTERNO
		SELECT RADCOM_pedido,RTRIM(LTRIM(RADCOM_numero_documento)) AS RADCOM_numero_documento,RADCOM_nit_documento,RADCOM_Proceso 
		INTO #tblFAlterno
		FROM #TranNProcesadas
		WHERE ISNUMERIC(RADCOM_pedido) <> 1 OR LEN(RADCOM_pedido) <> 6 OR RADCOM_pedido = '';

	-- FILTRO PARA ENCONTRAR LOS QUE SI TIENEN 6 DIGITOS CON CARACTERES Y RETIRAR LOS CARACTERES NO DIGITOS 
		SELECT *, REPLACE(SUBSTRING(RADCOM_pedido, PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9]%', RADCOM_pedido), 6), '[^0-9]', '') AS pedido 
		INTO #tblFiltro6dig
		FROM #tblFAlterno
		WHERE RADCOM_pedido <> '' 
		AND PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9][0-9]%',RADCOM_pedido) = 0;

	-- FILTRO PARA QUITAR LOS CARACTERES ESPECIALES Y MENORES A 6 DIGITOS
		SELECT * 
		INTO #tblSEspeciales
		FROM #tblFiltro6dig
		WHERE (NOT RADCOM_pedido LIKE '%[^a-zA-Z0-9 ]%' OR RADCOM_pedido LIKE '%[!@#$%^&*()]%') AND LEN(pedido) = 6;

	-- FILAS RESCADATAS PARA NO HACER EL FLUJO ALTERNO
		INSERT INTO #tblFNormal (RADCOM_pedido,RADCOM_numero_documento,RADCOM_nit_documento,RADCOM_Proceso)
		SELECT pedido,RADCOM_numero_documento,RADCOM_nit_documento,RADCOM_Proceso
		FROM #tblSEspeciales

	-- RETIRO DEL FLUJO ALTERNO LOS CARACTERES ESPECIALES
		DELETE FROM #tblFAlterno
		WHERE RADCOM_numero_documento IN (SELECT RADCOM_numero_documento FROM #tblSEspeciales);

	-- FLUJO DE EXCEPCIONES
		SELECT * 
		INTO #tblExcepciones
		FROM #tblFAlterno
		WHERE RADCOM_nit_documento IN (SELECT EXC_Nit FROM RAD_Excepciones);

	-- RETIRO DEL FLUJO ALTERNO LAS EXCEPCIONES
		DELETE FROM #tblFAlterno
		WHERE RADCOM_numero_documento IN (SELECT RADCOM_numero_documento FROM #tblExcepciones);

	-- ACTUALIZAR ID DEL PROCESO A 3 (FLUJO ALTERNO)
		UPDATE #tblFAlterno
		SET RADCOM_Proceso = 3
		WHERE RADCOM_Proceso = 1; 
	
	-- LIMPIEZA FLUJO EXCEPCIONES
		DELETE FROM [dbo].[RAD_TransaccionalExcepciones]
		WHERE CONVERT(VARCHAR(10),[RADTRAN_FechaInsercion],101) >= CONVERT(VARCHAR(10),GETDATE(),101);

	-- INSERSION DE FLUJO EXCEPCIONES
		INSERT INTO RAD_TransaccionalExcepciones (RADTRAN_NumPedido,RADTRAN_Email,RADTRAN_FechaInsercion,RADTRAN_Documento,RADTRAN_Proceso,RADTRAN_Nit)
		SELECT tblEXC.RADCOM_pedido,EXC.EXC_Email,GETDATE() as FechaInsercion,tblEXC.RADCOM_numero_documento,2 as Proceso,EXC.EXC_Nit
		FROM #tblExcepciones tblEXC
		INNER JOIN RAD_Excepciones EXC 
		ON tblEXC.RADCOM_nit_documento = EXC.EXC_Nit;

	--SALIDA DEL PROCEDIMIENTO
		SELECT *
		FROM #tblFNormal
		UNION ALL
		SELECT *
		FROM #tblFAlterno
END;
