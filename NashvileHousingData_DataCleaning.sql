USE [PortfolioProject]
GO
/****** Object:  StoredProcedure [dbo].[BLD_WRK_NashvileHousingData]    Script Date: 09-10-2021 06:13:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Elakkiya Rajendran
-- Create date: 20211009
-- Description:	RAW -> WRK (DATA CLEANING)
-- =============================================
ALTER PROCEDURE [dbo].[BLD_WRK_NashvileHousingData] 
AS
BEGIN

-- =============================================
-- DROP TABLE BLOCK
-- =============================================
IF OBJECT_ID('WRK_NashvileHousingData') IS NOT NULL
DROP TABLE [WRK_NashvileHousingData]

-- =============================================
-- CREATE TABLE BLOCK
-- =============================================
CREATE TABLE [WRK_NashvileHousingData]
(
	   [RowNumber]	INT IDENTITY(1,1)
	  ,[UniqueID ]	VARCHAR(255)
      ,[ParcelID]	VARCHAR(255)
      ,[LandUse]	VARCHAR(255)
      ,[PropertyAddress] NVARCHAR(255)
      ,[SaleDate]	DATE
      ,[SalePrice]	FLOAT
      ,[LegalReference]	VARCHAR(255)
      ,[SoldAsVacant]	NVARCHAR(255)
      ,[OwnerName]	NVARCHAR(255)
      ,[OwnerAddress]	NVARCHAR(255)
      ,[Acreage]	FLOAT
      ,[TaxDistrict]	NVARCHAR(255)
      ,[LandValue]	FLOAT
      ,[BuildingValue]	FLOAT
      ,[TotalValue]	FLOAT
      ,[YearBuilt]	DATE
      ,[Bedrooms]	INT
      ,[FullBath]	INT
      ,[HalfBath]	INT
)


-- =============================================
-- TRUNCATE TABLE BLOCK
-- =============================================
TRUNCATE TABLE [WRK_NashvileHousingData]

-- =============================================
-- INSERT INTO BLOCK
-- =============================================
INSERT INTO [WRK_NashvileHousingData]
(
	   [UniqueID ]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
)
SELECT
	NULLIF([UniqueID ], '')
      ,NULLIF([ParcelID], '')
      ,NULLIF([LandUse], '')
      ,NULLIF([PropertyAddress], '')
      ,NULLIF([SaleDate], '')
      ,NULLIF([SalePrice],'')
      ,NULLIF([LegalReference],'')
      ,NULLIF([SoldAsVacant],'')
      ,NULLIF([OwnerName], '')
      ,NULLIF([OwnerAddress], '')
      ,NULLIF([Acreage],'')
      ,NULLIF([TaxDistrict],'')
      ,NULLIF([LandValue],'')
      ,NULLIF([BuildingValue],'')
      ,NULLIF([TotalValue], '')
      ,NULLIF([YearBuilt], '')
      ,NULLIF([Bedrooms], '')
      ,NULLIF([FullBath], '')
      ,NULLIF([HalfBath], '')
FROM [RAW_NashvileHousingData_20211009]
--(56477 rows affected)

/**
SQL DATA CLEANING
Dataset : Nashvile Housing Data
**/

--POPULATING NULL VALUES IN PROPERTY ADDRESS
SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress,
ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM WRK_NashvileHousingData A
JOIN WRK_NashvileHousingData B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

UPDATE A
SET PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress) 
FROM WRK_NashvileHousingData A
JOIN WRK_NashvileHousingData B
ON A.ParcelID = B.ParcelID
AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL
--29 ROWS AFFECTED

--====================================================
--PROPERTY ADDRESS -> ADDRESS, CITY
--ADDING TWO COLUMNS -> PropertySplitAddress, PropertySplitCity
--====================================================
/**
SELECT PropertyAddress
FROM WRK_NashvileHousingData

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as City
FROM WRK_NashvileHousingData
**/

ALTER TABLE WRK_NashvileHousingData
ADD PropertySplitAddress NVARCHAR(255), PropertySplitCity NVARCHAR(255);

UPDATE WRK_NashvileHousingData
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)
, PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT * 
FROM WRK_NashvileHousingData

--(56477 rows affected)

--====================================================
--OWNER ADDRESS -> ADDRESS, CITY, STATE
--USING PARSENAME
--ADDING 3 COLUMNS -> 
--====================================================

/**Replacing the seperator , with period(.) as recognizable by PARSENAME
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM WRK_NashvileHousingData
**/

ALTER TABLE WRK_NashvileHousingData
ADD OwnerSplitAddress NVARCHAR(255), OwnerSplitCity NVARCHAR(255), OwnerSplitState NVARCHAR(255);

UPDATE WRK_NashvileHousingData
SET OwnerSplitAddress =PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
--(56477 rows affected)

--====================================================
--SOLDASVACANT COL HAS YES/NO/Y/N -> YES/NO
--====================================================
/**
CHECK FOR THE DISTINCT VALUES(WITH COUNTS)

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM WRK_NashvileHousingData
GROUP BY SoldAsVacant
--(4 rows affected) (INITIAL CHECK)
--(2 rows affected) (AFTER UPDATE QUERY)
**/
UPDATE WRK_NashvileHousingData
SET SoldAsVacant =
					CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'NO'
						ELSE SoldAsVacant
					END
--(56477 rows affected)

--====================================================
--REMOVE DUPLICATES
--====================================================
/**Duplicate count check with selected features
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY ParcelID,
			PropertyAddress,
			SaleDate,
			SalePrice,
			LegalReference
ORDER BY ParcelID
) AS DUP_COUNT
FROM WRK_NashvileHousingData
**/

/**
WITH NoDupCTE AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY ParcelID,
			PropertyAddress,
			SaleDate,
			SalePrice,
			LegalReference
ORDER BY ParcelID
) AS DUP_COUNT
FROM WRK_NashvileHousingData
)
SELECT * FROM NoDupCTE
--DELETE FROM NoDupCTE
WHERE DUP_COUNT > 1
--ORDER BY ParcelID
--(104 rows affected) (WITH SELECT FROM NoDupCTE)
--(104 rows affected) (WITH DELETE QUERY)
--(0 rows affected) (WITH SELECT AFTER DELETE QUERY)

**/
--=========================================================================
--DROPPING UNUSED COLUMNS (MAY BE FEATURE SELECTION AFTER DATA CLEANING)
--=========================================================================

ALTER TABLE WRK_NashvileHousingData
DROP COLUMN [PropertyAddress], [SaleDate], [OwnerAddress], [TaxDistrict]
--================================================
--CHECK COLUMN NAMES AND DATA TYPES
--================================================
SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'WRK_NashvileHousingData'
--(21 rows affected)


	
END

/**
SELECT * FROM [RAW_NashvileHousingData_20211009]
ALTER TABLE WRK_NashvileHousingData
ADD DateOfSale;
Update WRK_NashvileHousingData
SET DateOfSale = CONVERT(Date, SaleDate)
**/