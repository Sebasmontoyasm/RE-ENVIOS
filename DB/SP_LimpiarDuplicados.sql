USE [DB_RADIAN]
GO
/****** Object:  StoredProcedure [dbo].[SP_LimpiarDuplicados]    Script Date: 10/05/2023 2:52:43 a. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,Juan Sebastián Montoya Acevedo>
-- Create date: <Create Date,19/05/2023 04:00>
-- Description:	<Description, Limpia los duplicados en caso de que se ejecute varias veces en el mismo dia (Guardara la ultima ejecucion)>
-- =============================================
ALTER PROCEDURE [dbo].[SP_LimpiarDuplicados]
AS
BEGIN
	SET NOCOUNT ON;

	-- LIMPIEZA DE EJECUCIONES MANUALES O REPETITIVAS PARA DUPLICIDAD DE DATOS
		DELETE
		FROM [dbo].[RAD_Comercial1]
		WHERE RADCOM_fecha_insercion >= CONVERT(VARCHAR(10),GETDATE(),101);

		DELETE FROM [dbo].[RAD_Transaccional]
		WHERE CONVERT(VARCHAR(10),[RADTRAN_FechaInsercion],101) >= CONVERT(VARCHAR(10),GETDATE(),101);

		DELETE FROM [dbo].[RAD_TransaccionalAlterna]
		WHERE CONVERT(VARCHAR(10),[RADTRAN_FechaInsercion],101) >= CONVERT(VARCHAR(10),GETDATE(),101);

		DELETE FROM [dbo].[RAD_TransaccionalExcepciones]
		WHERE CONVERT(VARCHAR(10),[RADTRAN_FechaInsercion],101) >= CONVERT(VARCHAR(10),GETDATE(),101);
END;