-- NASHVILLE HOUSING CLEANING DATA PROJECT
-- NATE BORRIES 05-10-2023

----------------------------------------------------------
-- ENSURE DATA WAS IMPORTED CORRECTLY
SELECT *
FROM NashvilleHousingProject..NashvilleHousing



----------------------------------------------------------
-- STANDARDIZE DATE FORMAT
SELECT SaleDateConverted, CONVERT(date, SaleDate)
FROM NashvilleHousingProject..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)



--------------------------------------------------------------------------------------------------------------------
-- POPULATE PROPERTY ADDRESS DATA
SELECT *
FROM NashvilleHousingProject..NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID -- Unique Parcel ID  for Property Address... Populate NULL PropertyAddress with Address with same Parcel ID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) -- If a.propertyaddress is null, replace with b.propertyaddress
FROM NashvilleHousingProject..NashvilleHousing a
JOIN NashvilleHousingProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


UPDATE a -- Replaced PropertyAddress null data points with same address as that with same ParcelID/Different UniqueID
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousingProject..NashvilleHousing a
JOIN NashvilleHousingProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



--------------------------------------------------------------------------------------------------------------------
--BREAK PROPERTY ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY)

--Return street address, without comma
SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address -- this returns address without comma :)
FROM NashvilleHousingProject..NashvilleHousing

--Return city
SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress)) AS City --Takes 1 after comma until end of address (LEN = LENGTH)
FROM NashvilleHousingProject..NashvilleHousing

--Add new columns for parts of address, and update table
ALTER TABLE NashvilleHousingProject..NashvilleHousing --Update table with new split address
	ADD
	PropertySplitAddress nvarchar(255), -- Add new column for Street Address only
	PropertySplitCity nvarchar(255) -- Add new column for City only

UPDATE NashvilleHousingProject..NashvilleHousing
	SET
	PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1),
	PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

--Check to see new columns were added:
SELECT 	*
FROM NashvilleHousingProject..NashvilleHousing 



--------------------------------------------------------------------------------------------------------------------
--BREAK PROPERTY ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY)

-- look at Owner Address
SELECT OwnerAddress
FROM NashvilleHousingProject..NashvilleHousing 

-- Slplit into Address, City, State
SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'),3), --Parsename looks for periods. To be effective we needed to replace the commas with periods. 
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
from NashvilleHousingProject..NashvilleHousing 

--add columns, update table
ALTER TABLE NashvilleHousingProject..NashvilleHousing
	ADD 
	OwnerSplitAddress nvarchar(255), 
	OwnerSplitCity nvarchar(255), 
	OwnerSplitState nvarchar(255)

UPDATE NashvilleHousingProject..NashvilleHousing
	SET
	OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)



--------------------------------------------------------------------------------------------------------------------
-- CHANGE Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD

-- Show SoldAsVacant Types (Yes, Y, No, N)
SELECT DISTINCT SoldAsVacant, COUNT(SoldAsVacant)
FROM NashvilleHousingProject..NashvilleHousing
GROUP BY SoldAsVacant

-- Return Yes or No, regardless of Y/N
SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleHousingProject..NashvilleHousing

-- Update Table to replace all y/n with yes/no
Update NashvilleHousingProject..NashvilleHousing
	SET SoldAsVacant =	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END



--------------------------------------------------------------------------------------------------------------------
-- REMOVE DUPLICATES

-- Use CTE to find where there are duplicate valvues
WITH RowNumCTE AS(
	SELECT *, --select everything then add row number
		ROW_NUMBER() OVER (
		PARTITION BY -- Partition by data points that should be unique, yet still have duplicate values
		ParcelID,
		PropertyAddress,
		SalePrice,
		SaleDate,
		LegalReference
		ORDER BY UniqueID ) row_num-- Order by something that should be unique				
	FROM NashvilleHousingProject..NashvilleHousing
	)

DELETE -- Deleted rows where row_num was 2
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

 

--------------------------------------------------------------------------------------------------------------------
-- DELETE UNUSED COLUMNS

-- May want to delete original address columns that we split up earlier
SELECT *
FROM NashvilleHousingProject..NashvilleHousing 

ALTER TABLE NashvilleHousingProject..NashvilleHousing 
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE NashvilleHousingProject..NashvilleHousing 
DROP COLUMN SaleDate -- forgot to delete saledate :/



--------------------------------------------------------------------------------------------------------------------

