USE [DB_RADIAN]
GO
/****** Object:  StoredProcedure [dbo].[SP_ConsultaProcesados]    Script Date: 4/07/2023 4:35:18 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author: <Author,Sebastian Montoya>
-- Create date: <Create Date,03-03-2023>
-- Description: <Description,Procedimiento para crear Reporte Final>
-- =============================================
ALTER PROCEDURE [dbo].[SP_ConsultaProcesados] 
AS
BEGIN
	SET NOCOUNT ON;
	
	--Hora de generación del reporte
	DECLARE @HoraActual TIME;
	SET @HoraActual = GETDATE();

	-- CONDICION SPLIT DIA 12PM-11PM O SPLIT NOCHE 11PM 11:59 AM DEL DIA SIGUIENTE
	IF DATEPART(HOUR, @HoraActual) >= 00 OR DATEPART(HOUR, @HoraActual) < 12
	BEGIN
		--EXTRACCIÓN DE JAIVANA A LAS 11:30PM
		SELECT 
			LTRIM(RTRIM(RADCOM_numero_documento)) AS Factura,
			LTRIM(RTRIM(RADCOM_pedido)) AS Pedido,
			CONVERT(DATETIME, C.RADCOM_fecha_documento + ' ' + C.RADCOM_hora_documento) AS 'Fecha de documento'
		INTO #TransaccionNoche
		FROM RAD_Comercial1 C
		WHERE 
			CONVERT(DATETIME, C.RADCOM_fecha_insercion) >= CONVERT(DATETIME, CONVERT(VARCHAR(10), GETDATE() - 1, 101) + ' 23:30:00');

		--PROCESADAS POR EL ROBOT.
		SELECT 
			PRO_Documento AS Factura,
			PRO_NumPedido AS Pedido,
			PRO_Email AS 'Notificado a',
			PRO_FechaInsercion AS 'Fecha de re-envío',
			TN.[Fecha de documento],
			P.PRO_Proceso AS Proceso
		INTO #ProcesadosNoche
		FROM [dbo].[RAD_Procesados] P
		INNER JOIN #TransaccionNoche TN ON LTRIM(RTRIM(TN.Factura)) = LTRIM(RTRIM(P.PRO_Documento))
		WHERE 
			P.PRO_Documento IS NOT NULL AND
			PRO_FechaInsercion >= CONVERT(DATETIME, CONVERT(VARCHAR(10), GETDATE() - 1, 101) + ' 23:30:00') AND
			PRO_FechaInsercion <= CONVERT(DATETIME, CONVERT(VARCHAR(10), GETDATE(), 101) + ' 11:59:59')
		ORDER BY [Fecha de re-envío] ASC;

		--NO PROCESADAS POR ENVÍO PREVIO
		SELECT
			PRO.PRO_Documento AS Factura,
			PRO.PRO_NumPedido AS Pedido,
			'Re-envío previo' AS 'Notificado a',
			MIN(PRO.PRO_FechaInsercion) AS 'Fecha de re-envío',
			MIN(TN.[Fecha de documento]) AS 'Fecha de documento',
			MIN(PRO.PRO_Proceso) AS Proceso
		INTO #ReEnviados
		FROM RAD_Procesados PRO
		INNER JOIN #TransaccionNoche TN ON LTRIM(RTRIM(TN.Factura)) =  LTRIM(RTRIM(PRO.PRO_Documento))
		WHERE 
			PRO.PRO_Documento IS NOT NULL AND
			PRO_FechaInsercion < CONVERT(DATETIME, CONVERT(VARCHAR(10), GETDATE() - 1, 101) + ' 23:30:00')
		GROUP BY PRO_Documento, PRO_NumPedido;

		--FACTURAS REPETIDAS EN PROCESADAS Y RE ENVIADAS
		DELETE
		FROM #ProcesadosNoche
		WHERE Factura IN (SELECT Factura FROM #ReEnviados); 

		-- GENERAR EL REPORTE
		SELECT *
		INTO #Procesados
		FROM #ReEnviados
		UNION ALL 
		SELECT * 
		FROM #ProcesadosNoche;

		-- NO PROCESADAS POR EL ROBOT
		SELECT 
			Factura,
			Pedido,
			'No procesado' AS 'Notificado a',
			[Fecha de documento] AS 'Fecha de re-envío',
			[Fecha de documento],
			'5' AS Proceso
		INTO #NProcesados
		FROM #TransaccionNoche T
		WHERE Factura NOT IN (SELECT Factura FROM #Procesados WHERE LTRIM(RTRIM(T.Factura)) = LTRIM(RTRIM(Factura)));

		--REPORTE FINAL NOCHE
		SELECT *
		FROM #Procesados
		UNION ALL 
		SELECT * 
		FROM #NProcesados;
	END
	ELSE IF DATEPART(HOUR, @HoraActual) >= 12 
	BEGIN
		--EXTRACCIÓN DEL DÍA EN JAIVANA
		SELECT 
			LTRIM(RTRIM(RADCOM_numero_documento)) AS Factura,
			LTRIM(RTRIM(RADCOM_pedido)) AS Pedido,
			CONVERT(DATETIME, C.RADCOM_fecha_documento + ' ' + C.RADCOM_hora_documento) AS 'Fecha de documento'
		INTO #TransaccionDia
		FROM RAD_Comercial1 C
		WHERE CONVERT(VARCHAR(10),C.RADCOM_fecha_insercion,101) >= CONVERT(VARCHAR(10),GETDATE()+'00:00:00',101);

		--PROCESADOS POR EL ROBOT
		SELECT 
			PRO_Documento AS Factura,
			PRO_NumPedido AS Pedido,
			PRO_Email AS 'Notificado a',
			PRO_FechaInsercion AS 'Fecha de re-envío',
			TD.[Fecha de documento],
			P.PRO_Proceso AS Proceso
		INTO #ProcesadosD
		FROM [dbo].[RAD_Procesados] P
		INNER JOIN #TransaccionDia TD ON TD.Factura = LTRIM(RTRIM(P.PRO_Documento))
		WHERE 
			P.PRO_Documento IS NOT NULL AND
			PRO_FechaInsercion >= CONVERT(DATETIME, CONVERT(VARCHAR(10), GETDATE(), 101) + ' 12:00:00')
		ORDER BY [Fecha de re-envío] ASC;

		-- RE ENVIADOS PREVIAMENTE 
		SELECT
			PRO.PRO_Documento AS Factura,
			PRO.PRO_NumPedido AS Pedido,
			'Re-envío previo' AS 'Notificado a',
			MIN(PRO.PRO_FechaInsercion) AS 'Fecha de re-envío',
			MIN(TN.[Fecha de documento]) AS 'Fecha de documento',
			MIN(PRO.PRO_Proceso) AS Proceso
		INTO #ReEnviadosDA
		FROM RAD_Procesados PRO
		INNER JOIN #TransaccionDia TN ON TN.Factura = LTRIM(RTRIM(PRO.PRO_Documento))
		WHERE 
			PRO.PRO_Documento IS NOT NULL AND
			PRO_FechaInsercion < CONVERT(DATETIME, CONVERT(VARCHAR(10), GETDATE(), 101) + ' 12:00:00')
		GROUP BY PRO_Documento, PRO_NumPedido
		ORDER BY [Fecha de re-envío] ASC;

		-- LIMPIAR DUPLICADOS ENTRE PROCESADOS Y RE ENVIADOS
		DELETE
		FROM #ProcesadosD
		WHERE Factura IN (SELECT Factura FROM #ReEnviadosDA); 

		-- PROCESADOS POR EL ROBOT
		SELECT *
		INTO #ProcesadosDia
		FROM #ReEnviadosDA
		UNION ALL 
		SELECT * 
		FROM #ProcesadosD;

		-- NO PROCESADOS POR EL ROBOT
		SELECT 
			Factura,
			Pedido,
			'No procesado' AS 'Notificado a',
			[Fecha de documento] AS 'Fecha de re-envío',
			[Fecha de documento],
			'5' AS Proceso
		INTO #NProcesadosD
		FROM #TransaccionDia T
		WHERE Factura NOT IN (SELECT Factura FROM #ProcesadosDia WHERE T.Factura = LTRIM(RTRIM(Factura)));

		-- REPORTE FINAL GENERADOR DIA.
		SELECT *
		FROM #ProcesadosDia
		UNION ALL 
		SELECT * 
		FROM #NProcesadosD;
	END;
END;
