
SELECT * FROM pro_mark.marketing_campaign;


-- CREACION DE TABLA PARA REALIZAR TABLA DE TRABAJO--
CREATE TABLE pro_mark.marketing_campaign_clean AS
SELECT *
FROM pro_mark.marketing_campaign;

SELECT 
COUNT(*) AS total_filas,
COUNT(DISTINCT ID) AS ids_unicos
FROM pro_mark.marketing_campaign_clean;

-- CTE (WITH) para organizar la consulta Y VERFICAR SI EXISTEN DUPLICADOS --
WITH duplicated_profiles AS (
    SELECT 
        `ï»¿ID`,
        Year_Birth,
        Education,
        Marital_Status,
        Income,
        Kidhome,
        Teenhome,
        Dt_Customer,
        Recency,
        NumWebPurchases,
        NumStorePurchases,
        NumWebVisitsMonth,
        Response,
        ROW_NUMBER() OVER(
            PARTITION BY 
                Year_Birth,
                Education,
                Marital_Status,
                Income,
                Kidhome,
                Teenhome,
                Dt_Customer
            ORDER BY `ï»¿ID`
        ) AS row_num
    FROM pro_mark.marketing_campaign_clean
)

SELECT *
FROM duplicated_profiles
WHERE row_num > 1;

--CAMBIO NOMBRE DE COLUMNA--
ALTER TABLE pro_mark.marketing_campaign_clean
CHANGE COLUMN `ï»¿ID` ID INT;


--VERIFICAR SI ECISTEN ESPACIOS EN COLUMNAS CATEGORICAS--
SELECT DISTINCT
    Marital_Status,
    TRIM(Marital_Status) AS marital_status_clean
FROM pro_mark.marketing_campaign_clean;


SELECT DISTINCT
    Education,
    TRIM(Education) AS education_clean
FROM pro_mark.marketing_campaign_clean;


-- VERFICACION DE ESPACIOS NULOS E--
SELECT *
FROM pro_mark.marketing_campaign_clean
WHERE Income IS NULL;



---CREACION DE VISTA (MEDIANA POR EDUCATION PARA REEMPLZAR POR VALORES NULOS--
CREATE OR REPLACE VIEW pro_mark.vista_mediana_education AS
SELECT 
    Education, 
    CAST(AVG(Income) AS SIGNED) AS mediana_ingreso
FROM (
    SELECT 
        Education, 
        Income,
        ROW_NUMBER() OVER (PARTITION BY Education ORDER BY Income) as posicion,
        COUNT(*) OVER (PARTITION BY Education) as total
    FROM pro_mark.marketing_campaign_clean
    WHERE Income IS NOT NULL 
) AS subconsulta
WHERE posicion IN (FLOOR((total + 1) / 2), CEIL((total + 1) / 2))
GROUP BY Education;

-- REEMPLZAR AQUELLOS VALORES NULOS POR LA MEDIANA USANDO LA VISTA CREADA--
UPDATE pro_mark.marketing_campaign_clean m
SET Income = (
    SELECT mediana_ingreso 
    FROM pro_mark.vista_mediana_education v 
    WHERE v.Education = m.Education
)
WHERE m.Income IS NULL;

--ESTANDARIZACION DE DATOS--
SELECT * FROM pro_mark.marketing_campaign
WHERE Year_Birth < 1901;

ALTER TABLE pro_mark.marketing_campaign_clean 
MODIFY COLUMN Year_Birth YEAR(4);

ALTER TABLE pro_mark.marketing_campaign_clean 
MODIFY COLUMN Income DECIMAL(10,2),
MODIFY COLUMN MntWines DECIMAL(10,2),
MODIFY COLUMN MntFruits DECIMAL(10,2),
MODIFY COLUMN MntMeatProducts DECIMAL(10,2),
MODIFY COLUMN MntFishProducts DECIMAL(10,2),
MODIFY COLUMN MntSweetProducts DECIMAL(10,2),
MODIFY COLUMN MntGoldProds DECIMAL(10,2),
MODIFY COLUMN AcceptedCmp1 TINYINT(1),
MODIFY COLUMN AcceptedCmp2 TINYINT(1),
MODIFY COLUMN AcceptedCmp3 TINYINT(1),
MODIFY COLUMN AcceptedCmp4 TINYINT(1),
MODIFY COLUMN AcceptedCmp5 TINYINT(1),
MODIFY COLUMN Complain TINYINT(1),
MODIFY COLUMN Response TINYINT(1);

UPDATE pro_mark.marketing_campaign_clean 
SET Dt_Customer = STR_TO_DATE(Dt_Customer, '%d/%m/%Y');

ALTER TABLE pro_mark.marketing_campaign_clean 
MODIFY COLUMN Dt_Customer DATE;

ALTER TABLE pro_mark.marketing_campaign_clean 
DROP COLUMN Z_CostContact, 
DROP COLUMN Z_Revenue;
