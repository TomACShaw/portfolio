
SELECT * FROM OpenUnitsProject..open_units;


-- PREPARING THE DATASET


-- Renaming all fields to remove quotation marks
/*
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Product"]', 'Product', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Brand"]', 'Brand', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Category"]', 'Cate3gory', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Style"]', 'Style', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Quantity"]', 'Quantity', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Quantity Units"]', 'Quantity Units', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Volume"]', 'Volume', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Package"]', 'Package', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["ABV"]', 'ABV', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Units of Alcohol"]', 'Units of Alcohol', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Units (4 Decimal Places)"]', 'Units (4 Decimal Places)', 'COLUMN';
USE OpenUnitsProject
EXEC SP_RENAME 'open_units.["Units per 100ml"]', 'Units per 100ml', 'COLUMN';
*/

-- Creating a temp table to remove duplicate beers/ciders for calculations requiring distinct product info.
-- Since the package type and volume don't matter for these calculations, we can ignore them when partitioning
-- by product.
DROP TABLE IF EXISTS #singleton_open_units
CREATE TABLE #singleton_open_units (
	Product varchar(50),
	Brand varchar(50),
	Category varchar(50),
	Style varchar(50),
	Quantity varchar(50),
	[Quantity Units] varchar(50),
	Volume varchar(50),
	Package varchar(50),
	ABV varchar(50),
	[Units of Alcohol] varchar(50),
	[Units (4 Decimal Places)] varchar(50),
	[Units per 100ml] varchar(50)
);
WITH RowNumCTE (Product, Brand, Category, Style, Quantity,			-- Create a CTE with the same fields as open_units plus
	[Quantity Units], Volume, Package, ABV, [Units of Alcohol],		-- the RowNum field partitioned by product. This allows
	[Units (4 Decimal Places)], [Units per 100ml], rownum) AS (		-- us to only select the first record of each product.
	SELECT Product, Brand, Category, Style, Quantity,
		[Quantity Units], Volume, Package, ABV, [Units of Alcohol],
		[Units (4 Decimal Places)], [Units per 100ml],
		ROW_NUMBER() OVER (PARTITION BY Product ORDER BY Product)	-- if RowNum is > 1, that record is a duplicate product
	FROM open_units
)
INSERT INTO #singleton_open_units
SELECT Product, Brand, Category, Style, Quantity,
	[Quantity Units], Volume, Package, ABV, [Units of Alcohol],
	[Units (4 Decimal Places)], [Units per 100ml]
FROM RowNumCTE
WHERE rownum = 1;	-- only insert the first record of each product into the temp table

-- Trimming quotation marks to standardize fields
SELECT *,
	TRIM('"' FROM Product) as TrimmedProducts,
	TRIM('"' FROM Brand) as TrimmedBrands,
	TRIM('"' FROM Style) as TrimmedStyle
FROM OpenUnitsProject..open_units

UPDATE #singleton_open_units
SET Product = TRIM('"' FROM Product),
	Brand = TRIM('"' FROM Brand),
	Style = TRIM('"' FROM Style);

SELECT * FROM #singleton_open_units


--======================================================================


-- BEER VS. CIDER

-- Comparing the number of distinct beers vs. ciders in the dataset
SELECT Category,
	COUNT(Category) as CountPerCategory
FROM #singleton_open_units
GROUP BY Category;

-- Comparing average and max strength of beer vs. cider
SELECT Category,
	COUNT(Category) as CountPerCategory,
	ROUND(AVG(cast(ABV as float)), 3) as AvgABV,
	MAX(cast(ABV as float)) as MaxABV
FROM #singleton_open_units
GROUP BY Category


--=======================================================================


-- BEER NUMBERS

-- Comparing average and max strength of different styles of beer
SELECT Style,
	COUNT(Style) as CountPerStyle,
	ROUND(AVG(cast(ABV as float)), 3) as AvgABV,
	MAX(cast(ABV as float)) as MaxABV
FROM #singleton_open_units
WHERE Category = 'Beer' AND Style <> ''
GROUP BY Style
ORDER BY AvgABV DESC;

-- Comparing popularity of different styles of beer
SELECT Style,
	COUNT(Style) as CountPerStyle
FROM #singleton_open_units
WHERE Category = 'Beer' AND Style <> ''
GROUP BY Style
ORDER BY CountPerStyle DESC;


--======================================================================


-- TOTAL NUMBERS
/*
-- Ordering by highest percentage ABV
-- (RETURNS INCORRECT DATA since ABV is defined as varchar instead of float)
SELECT Product, Brand, Category, Style, ABV, [Units per 100ml]
FROM #singleton_open_units
ORDER BY ABV DESC;
*/

-- Ordering by highest percentage ABV
SELECT Product, Brand, Category, Style, cast(ABV as float) as ABV, [Units per 100ml]
FROM #singleton_open_units
ORDER BY ABV DESC;

-- Showing ABV percentage is equivalent to number of units per liter
SELECT Product, Brand, Category, Style, cast(ABV as float) as ABV,
	(cast([Units per 100ml] as float)*10) as [Units per 1L]
FROM #singleton_open_units;

-- Showing the total number of distinct products per brand
SELECT Brand, COUNT(Product) as NumberOfProducts
FROM #singleton_open_units
GROUP BY Brand
ORDER BY 2 DESC;

-- Showing the total number of distinct beers and ciders per brand
SELECT Brand,
	SUM(CASE WHEN Category = 'Beer' THEN 1 ELSE 0 END) AS NumberOfBeers,
	SUM(CASE WHEN Category = 'Cider' THEN 1 ELSE 0 END) AS NumberOfCiders
FROM #singleton_open_units
GROUP BY Brand
ORDER BY 3 DESC, 2 DESC;

-- Showing the total number of distinct beers and ciders per brand only including brands that produce both beer and cider
SELECT Brand,
	SUM(CASE WHEN Category = 'Beer' THEN 1 ELSE 0 END) AS NumberOfBeers, -- add one to the sum of beers for each product in the beer category
	SUM(CASE WHEN Category = 'Cider' THEN 1 ELSE 0 END) AS NumberOfCiders -- do the same for ciders, then group by brand
FROM #singleton_open_units
GROUP BY Brand
HAVING SUM(CASE WHEN Category = 'Beer' THEN 1 ELSE 0 END) > 0	-- there is at least one beer
	AND SUM(CASE WHEN Category = 'Cider' THEN 1 ELSE 0 END) > 0;	-- and there is at least one cider