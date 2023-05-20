USE [DB_RADIAN]
GO
/****** Object:  StoredProcedure [dbo].[SP_ConsultaProcesados]    Script Date: 19/05/2023 8:46:19 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[SP_ConsultaProcesados] 
	-- Add the parameters for the stored procedure here

AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @HoraActual TIME;
	SET @HoraActual = GETDATE();

	IF DATEPART(HOUR, @HoraActual) < 12 OR (DATEPART(HOUR, @HoraActual) = 23 AND DATEPART(MINUTE, @HoraActual) <= 30)
	BEGIN
		SELECT 
			PRO_Documento AS Factura,
			PRO_NumPedido AS Pedido,
			PRO_Email AS 'Notificado a',
			CONVERT(VARCHAR,PRO_FechaInsercion,120) AS 'Fecha de re-envio',
			C.RADCOM_fecha_documento+' '+C.RADCOM_hora_documento AS 'Fecha de documento'
		INTO #ProcesadosNoche
		FROM [dbo].[RAD_Procesados] P
		INNER JOIN RAD_Comercial1 C
		ON C.RADCOM_numero_documento = P.PRO_Documento
		WHERE P.PRO_Documento IS NOT NULL AND
		[PRO_FechaInsercion] >= CONVERT(VARCHAR(10),GETDATE()-1,101) + ' 23:30:00' AND
		[PRO_FechaInsercion] <= CONVERT(VARCHAR(10),GETDATE(),101) + ' 11:00:00'
		ORDER BY [Fecha de re-envio] ASC;

		SELECT
			PRO.PRO_Documento AS Factura,
			PRO.PRO_NumPedido AS Pedido,
			PRO.PRO_FechaInsercion,
			C.RADCOM_fecha_documento+' '+C.RADCOM_hora_documento AS 'Fecha de documento'
		INTO #ProcesadosAnterior2
		FROM RAD_Procesados PRO
		INNER JOIN RAD_Comercial1 C
		ON C.RADCOM_numero_documento = PRO.PRO_Documento
		WHERE PRO.PRO_Documento IS NOT NULL AND
		CONVERT(DATETIME,RADCOM_fecha_insercion,101) >= CONVERT(VARCHAR(10),GETDATE()-1,101) + ' 23:30:00' AND
		CONVERT(DATETIME,RADCOM_fecha_insercion,101) <= CONVERT(VARCHAR(10),GETDATE(),101) + ' 11:00:00';
		
		SELECT 
			Factura,
			Pedido,
			'Re-envio previo' AS 'Notificado a',
			MIN(PRO_FechaInsercion) AS 'Fecha de re-envio',
			MIN([Fecha de documento]) AS 'Fecha de documento'
		INTO #NProcesados2
		FROM #ProcesadosAnterior2
		GROUP BY Factura, Pedido;

		DELETE
		FROM #ProcesadosAnterior2
		WHERE Factura IN (SELECT Factura
						  FROM #ProcesadosNoche);
						  
		SELECT 
			Factura,
			Pedido,
			[Notificado a],
			MIN([Fecha de re-envio]) AS 'Fecha de re-envio',
			[Fecha de documento]
		FROM #ProcesadosNoche
		GROUP BY Factura, Pedido, [Notificado a], [Fecha de documento]
		UNION
		SELECT *
		FROM #NProcesados2
		ORDER BY [Fecha de re-envio] ASC;
	END
	ELSE
	BEGIN
		SELECT 
			PRO_Documento AS Factura,
			PRO_NumPedido AS Pedido,
			PRO_Email AS 'Notificado a',
			CONVERT(VARCHAR,PRO_FechaInsercion,120) AS 'Fecha de re-envio',
			C.RADCOM_fecha_documento+' '+C.RADCOM_hora_documento AS 'Fecha de documento'
		INTO #ProcesadosDia
		FROM [dbo].[RAD_Procesados] P
		INNER JOIN RAD_Comercial1 C
		ON C.RADCOM_numero_documento = P.PRO_Documento
		WHERE P.PRO_Documento IS NOT NULL AND [PRO_FechaInsercion] >= CONVERT(VARCHAR(10),GETDATE(),101) + ' 12:00:00'
		ORDER BY [Fecha de re-envio] ASC;

		SELECT 
			RADCOM_numero_documento AS Factura,
			RADCOM_pedido AS Pedido,
			'Omitido' AS 'Notificado a',
			'Re-envio previo' AS 'Fecha de re-envio',
			RADCOM_fecha_documento+' '+RADCOM_hora_documento AS 'Fecha de documento'
		INTO #TransaccionDia
		FROM RAD_Comercial1
		WHERE 
		CONVERT(DATETIME,RADCOM_fecha_insercion,101) >= CONVERT(VARCHAR(10),GETDATE(),101) + ' 12:00:00';
		
		SELECT
			PRO.PRO_Documento AS Factura,
			PRO.PRO_NumPedido AS Pedido,
			PRO.PRO_FechaInsercion,
			C.RADCOM_fecha_documento+' '+C.RADCOM_hora_documento AS 'Fecha de documento'
		INTO #ProcesadosAnterior
		FROM RAD_Procesados PRO
		INNER JOIN RAD_Comercial1 C
		ON C.RADCOM_numero_documento = PRO.PRO_Documento
		WHERE PRO.PRO_Documento IS NOT NULL AND CONVERT(DATETIME,RADCOM_fecha_insercion,101) >= CONVERT(VARCHAR(10),GETDATE(),101) + ' 12:00:00';
		
		DELETE
		FROM #ProcesadosAnterior
		WHERE Factura IN (SELECT Factura
						  FROM #ProcesadosDia);

		SELECT 
			Factura,
			Pedido,
			'Re-envio previo' AS 'Notificado a',
			MIN(PRO_FechaInsercion) AS 'Fecha de re-envio',
			MIN([Fecha de documento]) AS 'Fecha de documento'
		INTO #NProcesados
		FROM #ProcesadosAnterior
		GROUP BY Factura, Pedido;

		SELECT 
			Factura,
			Pedido,
			[Notificado a],
			MIN([Fecha de re-envio]) AS 'Fecha de re-envio',
			[Fecha de documento]
		FROM #ProcesadosDia
		GROUP BY Factura, Pedido, [Notificado a], [Fecha de documento]
		UNION
		SELECT *
		FROM #NProcesados
		ORDER BY [Fecha de re-envio] ASC;
	END;
END;