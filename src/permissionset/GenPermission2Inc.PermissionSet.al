permissionset 70800 "Gen.Permission2_Inc"
{
    Assignable = true;
    Permissions = tabledata "Separate Invoice Creation_Inc" = RIMD,
        table "Separate Invoice Creation_Inc" = X,
        report "AB Sales Report_Inc" = X,
        report "Bid Price Request Report_Inc" = X,
        report "Bid Purchase Order DT_Inc" = X,
        report "Bid Purchase Order Open-DMO" = X,
        report "Bid Sales Quote DT_Inc" = X,
        report "Checks Collec. Payment Rep2" = X,
        report "Open Bid Sales Quote_Inc" = X,
        report "Sales Balance Report_Inc" = X,
        page Joker_Cari_Kartlar_Inc = X;
}