Select OwnerName
From PortfolioProject..NashvilleHousing
where OwnerName is not null

--------------------------------------------------------------------------------------
-- Changing date format from datetime to date

Select SaleDate, CONVERT(date, SaleDate), SaleDateConverted
From PortfolioProject..NashvilleHousing

-- Not working correctly
Update PortfolioProject..NashvilleHousing
Set SaleDate = CONVERT(date, SaleDate)

ALTER TABLE PortfolioProject..NashvilleHousing
Add SaleDateConverted Date;
Update PortfolioProject..NashvilleHousing
Set SaleDateConverted = CONVERT(date, SaleDate)


--------------------------------------------------------------------------------------

-- Populate PropertyAddress data

-- Compare null PropertyAddresses to duplicate PropertyAddresses on ParcelID
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
	   ISNULL(a.PropertyAddress, b.PropertyAddress) as FixedAddresses
From PortfolioProject..NashvilleHousing a
Join PortfolioProject.. NashvilleHousing b
	On a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.propertyAddress is null;

-- Update the table
Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject..NashvilleHousing a
Join PortfolioProject.. NashvilleHousing b
	On a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.propertyAddress is null;


--------------------------------------------------------------------------------------

-- Breaking out addresses into individual columns (Address, City, State)

Select PropertyAddress
From PortfolioProject..NashvilleHousing

-- Since PropertyAddress is delimited by one comma, we can use a substring to separate the address and city
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
From PortfolioProject..NashvilleHousing

/* BULKY FORMATTING, SEE BELOW
-- Add and set new PropertyAddress fields
ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitAddress nvarchar(255);
Update PortfolioProject..NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1);

ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitCity nvarchar(255);
Update PortfolioProject..NashvilleHousing
Set PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))
*/

ALTER TABLE PortfolioProject..NashvilleHousing
Add PropertySplitAddress nvarchar(255),
	PropertySplitCity nvarchar(255);

Update PortfolioProject..NashvilleHousing
Set PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));


-- Split OwnerAddress into address, city, and state
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From PortfolioProject..NashvilleHousing
where OwnerAddress is not null;

/* BULKY FORMATTING, SEE BELOW
-- Add and set new OwnerAddress fields
ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitAddress nvarchar(255);
Update PortfolioProject..NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitCity nvarchar(255);
Update PortfolioProject..NashvilleHousing
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitState nvarchar(255);
Update PortfolioProject..NashvilleHousing
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);
*/


-- More efficient formatting for adding and setting new OwnerAddress field values

ALTER TABLE PortfolioProject..NashvilleHousing
Add OwnerSplitAddress nvarchar(255),
	OwnerSplitCity nvarchar(255),
	OwnerSplitState nvarchar(255);

UPDATE PortfolioProject..NashvilleHousing
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


--------------------------------------------------------------------------------------

-- Changing Y and N to Yes and No in "Sold as Vacant" field

Select Distinct SoldAsVacant, Count(SoldAsVacant)
From PortfolioProject..NashvilleHousing
Group By SoldAsVacant

Select DISTINCT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN
		REPLACE(SoldAsVacant, 'Y', 'Yes')
	WHEN SoldAsVacant = 'N' THEN
		REPLACE(SoldAsVacant, 'N', 'No')
	ELSE
		SoldAsVacant
	END
From PortfolioProject..NashvilleHousing


-- A more efficient way
Select DISTINCT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE
		SoldAsVacant
	END as SoldAsVacantFixed
From PortfolioProject..NashvilleHousing

Update NashvilleHousing
Set SoldAsVacant = CASE 
					WHEN SoldAsVacant = 'Y' THEN 'Yes'
					WHEN SoldAsVacant = 'N' THEN 'No'
					ELSE
						SoldAsVacant
					END




--------------------------------------------------------------------------------------






--------------------------------------------------------------------------------------






--------------------------------------------------------------------------------------






--------------------------------------------------------------------------------------





