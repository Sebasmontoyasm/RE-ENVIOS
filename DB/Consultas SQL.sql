USE [DB_RADIAN];

SELECT *
--DELETE
FROM [dbo].[RAD_Comercial1]
WHERE RADCOM_fecha_insercion LIKE '05/08/2023%';

SELECT *
--DELETE
FROM [dbo].[RAD_Transaccional]
WHERE CONVERT(VARCHAR(10),RADTRAN_FechaInsercion,101) LIKE '05/09/2023%';

SELECT RADTRAN_NumPedido,RADTRAN_Documento, COUNT(RADTRAN_Bodega) AS Bodegas
--DELETE
FROM [dbo].[RAD_TransaccionalAlterna]
WHERE CONVERT(VARCHAR(10),RADTRAN_FechaInsercion,101) LIKE '05/09/2023%'
GROUP BY RADTRAN_NumPedido, RADTRAN_Documento
ORDER BY Bodegas DESC;

SELECT *
--DELETE
FROM [dbo].[RAD_TransaccionalExcepciones]
WHERE CONVERT(VARCHAR(10),RADTRAN_FechaInsercion,101) LIKE '05/09/2023%'

SELECT COM.*
FROM RAD_Comercial1 COM
LEFT JOIN [dbo].[RAD_Procesados] P
ON COM.RADCOM_numero_documento = P.PRO_Documento
WHERE P.PRO_Documento IS NOT NULL AND CONVERT(VARCHAR(10),COM.RADCOM_fecha_insercion,101) >= CONVERT(VARCHAR(10),GETDATE(),101)


SELECT P.*
FROM RAD_Procesados P
LEFT JOIN [dbo].[RAD_Comercial1] COM
ON COM.RADCOM_numero_documento = P.PRO_Documento
WHERE P.PRO_Documento IS NOT NULL AND CONVERT(VARCHAR(10),COM.RADCOM_fecha_insercion,101) >= CONVERT(VARCHAR(10),GETDATE(),101) 

EXECUTE [dbo].[SP_FiltroNumeros];
EXECUTE [dbo].[SP_TransactionData_temp4];
EXECUTE [dbo].[SP_ConsultaProcesados];

