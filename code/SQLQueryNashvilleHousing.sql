-- Cleaning Data in SQL Queries

-- PART 1: Standardize Date Format
BEGIN TRAN
BEGIN TRY
    ALTER TABLE PortfolioProject.dbo.NashvilleHousing
    ADD SaleDateConverted Date;

    UPDATE NashvilleHousing
    SET SaleDateConverted = CONVERT(Date,SaleDate)
END TRY
BEGIN CATCH
    ROLLBACK TRAN
    -- Log error here
    RETURN
END CATCH
COMMIT TRAN

-- PART 2: Populate Property Address data
BEGIN TRAN
BEGIN TRY
    UPDATE a
    SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
    FROM PortfolioProject.dbo.NashvilleHousing a
    JOIN PortfolioProject.dbo.NashvilleHousing b
        ON a.ParcelID = b.ParcelID
        AND a.[UniqueID] <> b.[UniqueID]
    WHERE a.PropertyAddress IS NULL
END TRY
BEGIN CATCH
    ROLLBACK TRAN
    -- Log error here
    RETURN
END CATCH
COMMIT TRAN

-- PART 3: Breaking out Address into Individual Columns (Address, City, State)
BEGIN TRAN
BEGIN TRY
    ALTER TABLE NashvilleHousing
    ADD PropertySplitAddress NVARCHAR(255),
        PropertySplitCity NVARCHAR(255),
        OwnerSplitAddress NVARCHAR(255),
        OwnerSplitCity NVARCHAR(255),
        OwnerSplitState NVARCHAR(255);

    UPDATE NashvilleHousing
    SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
        PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)),
        OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
        OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
        OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1);
END TRY
BEGIN CATCH
    ROLLBACK TRAN
    -- Log error here
    RETURN
END CATCH
COMMIT TRAN

-- PART 4: Change Y and N to Yes and No in "Sold as Vacant" field
BEGIN TRAN
BEGIN TRY
    UPDATE NashvilleHousing
    SET SoldAsVacant = 
        CASE 
            WHEN SoldAsVacant = 'Y' THEN 'Yes'
            WHEN SoldAsVacant = 'N' THEN 'No'
            ELSE SoldAsVacant
        END
END TRY
BEGIN CATCH
    ROLLBACK TRAN
    -- Log error here
    RETURN
END CATCH
COMMIT TRAN

-- PART 5: Remove Duplicates
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID,
            PropertyAddress,
            SalePrice,
            SaleDate,
            LegalReference
            ORDER BY UniqueID
        ) row_num
    FROM PortfolioProject.dbo.NashvilleHousing
)
BEGIN TRAN
BEGIN TRY
    DELETE FROM RowNumCTE
    WHERE row_num > 1
END TRY
BEGIN CATCH
    ROLLBACK TRAN
    -- Log error here
    RETURN
END CATCH
COMMIT TRAN

-- PART 6: Delete Unused Columns
BEGIN TRAN
BEGIN TRY
    ALTER TABLE PortfolioProject.dbo.NashvilleHousing
    DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
END TRY
BEGIN CATCH
    ROLLBACK TRAN
    -- Log error here
    RETURN
END CATCH
COMMIT TRAN
