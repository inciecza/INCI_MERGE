report 70815 "SKT Stock Report_Inc"
{
    ApplicationArea = All;
    Caption = 'SKT Stock Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/SKT Stock Report.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;

            column(GirisNo; "Entry No.")
            {
            }
            column(Miad_Tarih; "Posting Date")
            {
            }
            column(MaddeNo; "Item No.")
            {
            }
            column(MaddeAd; "Item Description")
            {
            }
            column(Barkod; "Description")
            {
            }
            column(Miktar; "Invoiced Quantity")
            {
            }
            column(Uretici; "Item Charge No.")
            {
            }
            column(Lot_No; "User ID")
            {
            }
            column(LotKullan; "Invoiced Quantity")
            {
            }

            trigger OnPreDataItem()
            begin
                FillTempVLE();
            end;
        }

    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'Select the start date to filter the report.';
                    }
                    field(EndDate; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                        ToolTip = 'Select the end date to filter the report.';
                    }
                    field(ItemNo; ItemNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Item No.';
                        ToolTip = 'Select the item number to filter the report.';
                        TableRelation = Item;
                    }
                    field(ItemCategory; ItemCategory)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Category';
                        ToolTip = 'Select the item category to filter the report.';
                        TableRelation = "Item Category";
                    }
                    field(Location; Location)
                    {
                        ApplicationArea = All;
                        Caption = 'Location';
                        ToolTip = 'Select the location to filter the report.';
                    }

                    field(LotNo; LotNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Item Charge No.';
                        ToolTip = 'Select the item charge number to filter the report.';
                    }


                }
            }
        }
        actions
        {
            area(Processing)
            {
            }
        }
        trigger OnOpenPage()
        var
            LUserSetup: Record "User Setup";
        begin
            StartDate := Today;
            EndDate := CalcDate('<+10Y>', Today);

        end;
    }

    local procedure FillTempVLE()
    var
        LItemLedgerEntry: Record "Item Ledger Entry";
        LIncGenSetup: Record "Inci General Setup_Inc";
        LCompany: Record "Company";
        LItem: Record Item;
    begin
        Clear(LItem);
        if ItemNo <> '' then
            LItem.Setfilter("No.", ItemNo);
        LItem.Setfilter("Item Category Code", ItemCategory);
        if LItem.FindSet() then
            repeat
                Clear(TempVLE);
                Clear(LIncGenSetup);
                LIncGenSetup.Get();

                LItemLedgerEntry.Reset();
                if Location <> '' then
                    LItemLedgerEntry.Setfilter("Location Code", Location);
                LItemLedgerEntry.SetRange("Item No.", LItem."No.");
                LItemLedgerEntry.SetCurrentKey("Expiration Date");
                LItemLedgerEntry.SetAscending("Expiration Date", true);
                LItemLedgerEntry.Setfilter("Location Code", '%1|%2', LIncGenSetup."Private Hospital Bagc.Location", LIncGenSetup."Private Hospital Malt.Location");
                LItemLedgerEntry.Setfilter("Remaining Quantity", '>0');
                Clear(LCompany);
                if not (StartDate = 0D) and (EndDate = 0D) then
                    LItemLedgerEntry.SetRange("Expiration Date", StartDate, EndDate);

                if LItemLedgerEntry.FindSet() then
                    repeat
                        TempVLE.Reset();
                        TempVLE.SetRange("Item No.", LItemLedgerEntry."Item No.");
                        TempVLE.SetRange("Posting Date", LItemLedgerEntry."Expiration Date");
                        if LotNo then
                            TempVLE.SetRange("User ID", LItemLedgerEntry."Lot No.");

                        if TempVLE.FindFirst() then begin
                            TempVLE."Invoiced Quantity" += LItemLedgerEntry."Remaining Quantity";
                            TempVLE.Modify();
                        end else begin
                            TempVLE.Init();
                            i += 1;
                            LItemLedgerEntry.CalcFields("Item Description");
                            TempVLE."Entry No." := i;
                            TempVLE."Posting Date" := LItemLedgerEntry."Expiration Date";
                            TempVLE."Item No." := LItemLedgerEntry."Item No.";
                            TempVLE.Description := GetBarcode(LItemLedgerEntry."Item No.");
                            TempVLE."Item Description" := LItemLedgerEntry."Item Description";
                            TempVLE."Invoiced Quantity" := LItemLedgerEntry."Remaining Quantity";
                            TempVLE."User ID" := LItemLedgerEntry."Lot No."; // Lot No
                            TempVLE."Item Charge No." := CopyStr(GetManufacturerName(LItemLedgerEntry."Item No."), 1, 20);
                            if LotNo then
                                TempVLE."Invoiced Quantity" := 1;
                            TempVLE.Insert();
                        end;
                    until LItemLedgerEntry.Next() = 0;
                TempVLE.Reset();
            until LItem.Next() = 0;
    end;

    local procedure GetManufacturerName(pItemNo: code[20]): text[100]
    var
        LItem: Record Item;
    begin
        Clear(LItem);
        if LItem.Get(pItemNo) then begin
            LItem.CalcFields("Manufacturer Name_Inc");
            exit(LItem."Manufacturer Name_Inc");
        end
        else
            exit('');

    end;

    local procedure GetBarcode(pItemNo: code[20]): Text[100]
    var
        LItem: Record Item;
    begin
        if LItem.Get(pItemNo) then
            exit(LItem.GTIN);
        exit('');
    end;

    procedure SetParameters(pStartDate: Date; pEndDate: Date)
    begin
        StartDate := pStartDate;
        EndDate := pEndDate;
    end;

    var
        i: Integer;
        StartDate: Date;
        EndDate: Date;
        ItemCategory: text[100];
        ItemNo: Code[20];
        LotNo: boolean;
        Location: text[100];

}