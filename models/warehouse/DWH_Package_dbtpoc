

MERGE INTO ACCEL_BI_BR.DimPackage_Dbtpoc T
USING (
    SELECT *
    FROM ACCEL_BI_STG.stg_package_dbtpoc
) S
ON T.PackageCode = S.PackageCode

WHEN MATCHED AND (
    T.PackageCode <> S.PackageCode OR
    T.PackageName <> S.PackageName OR
    T.PackageShortName <> S.PackageShortName OR
    T.PackageDescription <> S.PackageDescription OR
    T.PackagePrice <> S.PackagePrice OR
    T.IsActive <> S.IsActive OR
    T.IsAllowAlaCarte <> S.IsAllowAlaCarte OR
    T.CompanyCode <> S.CompanyCode OR
    T.SearchTypeCode <> S.SearchTypeCode OR
    T.YearsSearched <> S.YearsSearched OR
    T.IsPackagePlus <> S.IsPackagePlus OR
    T.IsAddlInfoNeeded <> S.IsAddlInfoNeeded OR
    T.NoFMComponent <> S.NoFMComponent OR
    T.NameCount <> S.NameCount OR
    T.CountyCount <> S.CountyCount OR
    T.AskConv <> S.AskConv OR
    T.IsMinorBlocked <> S.IsMinorBlocked OR
    T.IsAddPositionLocationSearches <> S.IsAddPositionLocationSearches OR
    T.Is_Auto_W2_Opt <> S.Is_Auto_W2_Opt OR
    T.Is_Auto_W2_Utv <> S.Is_Auto_W2_Utv OR
    T.Is_int_address_question <> S.Is_int_address_question OR
    T.Is_Sin_Required <> S.Is_Sin_Required
)
THEN UPDATE SET
    T.PackageCode = S.PackageCode,
    T.PackageName = S.PackageName,
    T.PackageShortName = S.PackageShortName,
    T.PackageDescription = S.PackageDescription,
    T.PackagePrice = S.PackagePrice,
    T.IsActive = S.IsActive,
    T.IsAllowAlaCarte = S.IsAllowAlaCarte,
    T.CompanyCode = S.CompanyCode,
    T.SearchTypeCode = S.SearchTypeCode,
    T.YearsSearched = S.YearsSearched,
    T.IsPackagePlus = S.IsPackagePlus,
    T.IsAddlInfoNeeded = S.IsAddlInfoNeeded,
    T.NoFMComponent = S.NoFMComponent,
    T.NameCount = S.NameCount,
    T.CountyCount = S.CountyCount,
    T.AskConv = S.AskConv,
    T.IsMinorBlocked = S.IsMinorBlocked,
    T.IsAddPositionLocationSearches = S.IsAddPositionLocationSearches,
    T.Is_Auto_W2_Opt = S.Is_Auto_W2_Opt,
    T.Is_Auto_W2_Utv = S.Is_Auto_W2_Utv,
    T.Is_int_address_question = S.Is_int_address_question,
    T.Is_Sin_Required = S.Is_Sin_Required

WHEN NOT MATCHED THEN INSERT (
    PACKAGECODE, PackageName, PackageShortName, PackageDescription, PackagePrice,
    IsActive, IsAllowAlaCarte, CompanyCode, SearchTypeCode, YearsSearched,
    IsPackagePlus, IsAddlInfoNeeded, NoFMComponent, NameCount, CountyCount,
    AskConv, IsMinorBlocked, IsAddPositionLocationSearches, Is_Auto_W2_Opt,
    Is_Auto_W2_Utv, Is_int_address_question, Is_Sin_Required
)
VALUES (
    S.PackageCode, S.PackageName, S.PackageShortName, S.PackageDescription, S.PackagePrice,
    S.IsActive, S.IsAllowAlaCarte, S.CompanyCode, S.SearchTypeCode, S.YearsSearched,
    S.IsPackagePlus, S.IsAddlInfoNeeded, S.NoFMComponent, S.NameCount, S.CountyCount,
    S.AskConv, S.IsMinorBlocked, S.IsAddPositionLocationSearches, S.Is_Auto_W2_Opt,
    S.Is_Auto_W2_Utv, S.Is_int_address_question, S.Is_Sin_Required
);
