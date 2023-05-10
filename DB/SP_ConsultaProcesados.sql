USE [DB_RADIAN]
GO
/****** Object:  StoredProcedure [dbo].[SP_ConsultaProcesados]    Script Date: 9/05/2023 4:57:56 p. m. ******/
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
			RADCOM_numero_documento AS Factura,
			RADCOM_pedido AS Pedido,
			'Omitido' AS 'Notificado a',
			'Re-envio previo' AS 'Fecha de re-envio',
			RADCOM_fecha_documento+' '+RADCOM_hora_documento AS 'Fecha de documento'
		INTO #TransaccionN
		FROM RAD_Comercial1
		WHERE 
		CONVERT(DATETIME,RADCOM_fecha_insercion,101) >= CONVERT(VARCHAR(10),GETDATE()-1,101) + ' 23:30:00' AND
		CONVERT(DATETIME,RADCOM_fecha_insercion,101) <= CONVERT(VARCHAR(10),GETDATE(),101) + ' 11:00:00';

		DELETE
		FROM #TransaccionN
		WHERE Factura IN (SELECT Factura
						  FROM #ProcesadosNoche)

		SELECT *
		FROM #ProcesadosNoche
		UNION
		SELECT *
		FROM #TransaccionN
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
		
		DELETE
		FROM #TransaccionDia
		WHERE Factura IN (SELECT Factura
						  FROM #ProcesadosDia)

		SELECT *
		FROM #ProcesadosDia
		UNION
		SELECT *
		FROM #TransaccionDia
		ORDER BY [Fecha de re-envio] ASC;
	END;
END;