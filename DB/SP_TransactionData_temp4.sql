USE [DB_RADIAN]
GO
/****** Object:  StoredProcedure [dbo].[SP_TransactionData_temp4]    Script Date: 19/05/2023 8:48:35 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,Juan Sebastián Montoya Acevedo>
-- Create date: <Create Date,18/04/2023 15:09>
-- Description:	<Description, Procedimiento almacenado para el agrupamiento del Email y Bodegas para el RE ENVIO De correos desde Outlook.>
-- =============================================
ALTER PROCEDURE [dbo].[SP_TransactionData_temp4]
AS
BEGIN
	SET NOCOUNT ON;

	-- SELECCION DE FLUJO NORMAL PARA TRATAMIENTO
		SELECT RADTRAN_Documento, RADTRAN_NumPedido,RADTRAN_Proceso,RADTRAN_Bodega 
		INTO #tblFNormal
		FROM [dbo].[RAD_Transaccional]
		WHERE CONVERT(VARCHAR(10),[RADTRAN_FechaInsercion],101) >= CONVERT(VARCHAR(10),GETDATE(),101)
		GROUP BY RADTRAN_Documento, RADTRAN_NumPedido,RADTRAN_Proceso,RADTRAN_Bodega ;

	-- ASIGNACION DE LOS CORREOS EN EL FLUJO NORMAL
		SELECT NOR.*,BOD.RADBOD_Email 
		INTO #tblFNormalEmail
		FROM #tblFNormal NOR
		LEFT JOIN [dbo].[RAD_Bodegas] BOD
		ON NOR.RADTRAN_Bodega = BOD.RADBOD_Bodega;

	-- SELECCION DE FLUJO ALTERNO PARA TRATAMIENTO
		SELECT * 
		INTO #tblFAlterno
		FROM [dbo].[RAD_TransaccionalAlterna]
		WHERE CONVERT(VARCHAR(10),[RADTRAN_FechaInsercion],101) >= CONVERT(VARCHAR(10),GETDATE(),101);

	-- ASIGNACION DE LOS CORREOS FLUJO ALTERNO
		SELECT ALT.*,BOD.RADBOD_Email
		INTO #tblFAlternoEmail
		FROM #tblFAlterno ALT
		LEFT JOIN [dbo].[RAD_Bodegas] BOD
		ON ALT.RADTRAN_Bodega = BOD.RADBOD_Bodega;
		
	-- CURSOR ENCARGADO DE ENCONTRAR BODEGAS REPEDITAS Y LIMPIA PARA LA AGREGACION DEL FLUJO ALTERNO.
		DECLARE @documento VARCHAR(50), @bodega VARCHAR(MAX) , @repeticiones INT, @contador INT = 0;
		
		DECLARE REP_BODEGAS CURSOR FOR
		SELECT RADTRAN_Documento,RADTRAN_Bodega,COUNT(RADTRAN_Bodega) as Repeticiones
		FROM #tblFAlternoEmail
		GROUP BY RADTRAN_Documento,RADTRAN_Bodega
		HAVING COUNT(RADTRAN_Bodega) > 1
		ORDER BY RADTRAN_Documento ASC;
		
		OPEN REP_BODEGAS;

		FETCH NEXT FROM REP_BODEGAS INTO @documento, @bodega, @repeticiones;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @contador = @repeticiones - 1;
			DELETE TOP(@contador) FROM #tblFAlternoEmail
			WHERE RADTRAN_Documento = @documento AND RADTRAN_Bodega = @bodega;
			FETCH NEXT FROM REP_BODEGAS INTO @documento, @bodega, @repeticiones;
		END;

		CLOSE REP_BODEGAS;
		DEALLOCATE REP_BODEGAS;

	-- AGRUPAMIENTO DE BODEGAS Y EMAILS EN 1 SOLA FILA.
		SELECT RADTRAN_Documento AS documento,STRING_AGG(RADBOD_Email,'') AS email,RADTRAN_NumPedido AS pedido,3 AS proceso,STRING_AGG(RADTRAN_Bodega, ',') AS Bodega 
		INTO #tblFAlternoAGG
		FROM #tblFAlternoEmail 
		GROUP BY RADTRAN_Documento, RADTRAN_NumPedido;
	
	--  TRANSACCIONES DE EXCEPCIONES POR PROCESAR.
		SELECT 
		RADTRAN_Documento AS documento,
		RADTRAN_Email AS email,
		RADTRAN_NumPedido AS pedido,
		RADTRAN_Proceso AS proceso,
		'' AS Bodega
		INTO #tblExcepciones
		FROM [dbo].[RAD_TransaccionalExcepciones]
		WHERE CONVERT(VARCHAR(10),[RADTRAN_FechaInsercion],101) >= CONVERT(VARCHAR(10),GETDATE(),101);
	
	-- TRANSACCIONES POR PROCESAR
		SELECT 
			RADTRAN_Documento AS documento,
			RADBOD_Email AS email,
			RADTRAN_NumPedido AS pedido,
			RADTRAN_Proceso AS proceso,
			RADTRAN_Bodega AS Bodega
		INTO #TransacionesProcesadas
		FROM #tblFNormalEmail
		UNION ALL
		SELECT *
		FROM #tblExcepciones
		UNION ALL
		SELECT *
		FROM #tblFAlternoAGG

		-- TRANSACCIONES QUE NO VA A PROCESAR
		SELECT 
			RADCOM_numero_documento AS documento,
			'notificaciones.fac@sumatec.co' AS email,
			RADCOM_pedido AS pedido,
			'4' AS proceso,
			'' AS Bodega
		INTO #TransacionesNProcesadas
		FROM RAD_Comercial1
		WHERE CONVERT(VARCHAR(10),[RADCOM_fecha_insercion],101) >= CONVERT(VARCHAR(10),GETDATE(),101) 
		AND RADCOM_numero_documento NOT IN (SELECT documento
											FROM #TransacionesProcesadas)
		AND RADCOM_numero_documento NOT IN (SELECT PRO_Documento
											FROM [dbo].[RAD_Procesados]);

	-- SALIDA DEL PROCEDIMIENTO
		SELECT *
		FROM #TransacionesProcesadas
		UNION ALL
		SELECT *
		FROM #TransacionesNProcesadas

END;
