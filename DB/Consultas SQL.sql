USE [DB_RADIAN]

SELECT *
--DELETE
FROM [dbo].[RAD_Comercial1]
WHERE RADCOM_fecha_insercion LIKE '05/19/2023%' AND RADCOM_numero_documento LIKE '%MNZA4468%';

SELECT  CONVERT(VARCHAR(10),PRO_FechaInsercion,101)
FROM RAD_Procesados ;

SELECT * 
--DELETE
FROM RAD_Procesados 
WHERE PRO_FechaInsercion >=  '2023-05-18 12:00:00.000'

SELECT *
--DELETE
FROM [dbo].[RAD_Transaccional]
WHERE CONVERT(VARCHAR(10),RADTRAN_FechaInsercion,101) LIKE '05/19/2023%'      
GROUP BY RADTRAN_Documento

SELECT *
--DELETE
FROM [dbo].[RAD_TransaccionalAlterna]
WHERE CONVERT(VARCHAR(10),RADTRAN_FechaInsercion,101) LIKE '%05/19/2023%'

SELECT *
--DELETE
FROM [dbo].[RAD_TransaccionalExcepciones]
WHERE CONVERT(VARCHAR(10),RADTRAN_FechaInsercion,101) LIKE '05/11/2023 12:%';

SELECT COM.*
FROM RAD_Comercial1 COM
LEFT JOIN [dbo].[RAD_Procesados] P
ON COM.RADCOM_numero_documento = P.PRO_Documento
WHERE P.PRO_Documento IS NOT NULL AND CONVERT(VARCHAR(10),COM.RADCOM_fecha_insercion,101) >= CONVERT(VARCHAR(10),GETDATE(),101);


SELECT P.*
FROM RAD_Procesados P
LEFT JOIN [dbo].[RAD_Comercial1] COM
ON COM.RADCOM_numero_documento = P.PRO_Documento
WHERE P.PRO_Documento IS NOT NULL AND CONVERT(VARCHAR(10),COM.RADCOM_fecha_insercion,101) >= CONVERT(VARCHAR(10),GETDATE(),101) 

EXECUTE [dbo].[SP_FiltroNumeros];
EXECUTE [dbo].[SP_TransactionData_temp4];
EXECUTE [dbo].[SP_ConsultaProcesados];

SELECT 
	PRO_Documento AS Factura,
	PRO_NumPedido AS Pedido,
	PRO_Email AS 'Notificado a',
	FORMAT(MIN(PRO_FechaInsercion),'yyyy-MM-dd HH:mm:ss') AS 'Fecha de re-envio',
	PRO_Proceso AS Proceso,
	PRO_Estado
FROM RAD_Procesados 
WHERE PRO_Documento LIKE '%V151259%'
GROUP BY PRO_Documento, PRO_NumPedido, PRO_Email, PRO_Proceso, PRO_Estado;


