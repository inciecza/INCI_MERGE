report 70814 "Miad Stock Report_Inc"
{
    ApplicationArea = All;
    Caption = 'Miad Stock Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Miad Stock Report.rdlc';
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
            column(Uretici; "User ID")
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
            EndDate := Today;

        end;
    }

    local procedure FillTempVLE()
    var
        LItemLedgerEntry: Record "Item Ledger Entry";
        LIncGenSetup: Record "Inci General Setup_Inc";
        LCompany: Record "Company";
    begin
        Clear(TempVLE);


        Clear(LIncGenSetup);
        LIncGenSetup.Get();

        LItemLedgerEntry.Reset();
        LItemLedgerEntry.SetCurrentKey("Expiration Date");
        LItemLedgerEntry.SetAscending("Expiration Date", true);
        LItemLedgerEntry.Setfilter("Location Code", '%1|%2', LIncGenSetup."Private Hospital Bagc.Location", LIncGenSetup."Private Hospital Malt.Location");
        LItemLedgerEntry.Setfilter("Remaining Quantity", '>0');
        Clear(LCompany);
        if LCompany.Get(CompanyName) then
            if LCompany.Name = 'INC' then
                LItemLedgerEntry.Setfilter("Item Category Code", 'BİTMİŞ ÜRÜN');
        if not (StartDate = 0D) and (EndDate = 0D) then
            LItemLedgerEntry.SetRange("Expiration Date", StartDate, EndDate);

        if LItemLedgerEntry.FindSet() then
            repeat
                TempVLE.Reset();
                TempVLE.SetRange("Item No.", LItemLedgerEntry."Item No.");
                TempVLE.SetRange("Posting Date", LItemLedgerEntry."Expiration Date");

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
                    TempVLE."User ID" := CopyStr(GetManufacturerName(LItemLedgerEntry."Item No."), 1, 50);

                    TempVLE.Insert();
                end;
            until LItemLedgerEntry.Next() = 0;

        TempVLE.Reset();
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

}