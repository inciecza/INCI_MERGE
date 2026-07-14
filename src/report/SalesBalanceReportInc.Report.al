report 70806 "Sales Balance Report_Inc"
{
    ApplicationArea = All;
    Caption = 'Sales Balance Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/SalesBalanceReport.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;

            column(SıraNo; "Entry No.")
            {
            }
            column(Tarih; "Posting Date")
            {
            }
            column(MaddeNo; "Item No.")
            {
            }
            column(FaturaNo; "Document No.")
            {
            }
            column(MaddeAdi; "User ID")
            {
            }
            column(MusteriAd; Description)
            {
            }
            column(Miktar; "Invoiced Quantity")
            {
            }
            column(BirimFiyat; "Cost per Unit")
            {
            }
            column(Tutar; "Purchase Amount (Actual)")
            {
            }
            column(TutarKdvDahil; "Cost per Unit (ACY)")
            {
            }
            column(CompanyLogo; CompanyInformation.Picture)
            {
            }
            trigger OnPreDataItem()
            begin

                CompanyInformation.Get();
                CompanyInformation.CalcFields(Picture);
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

                    field(EndDate; PostingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Date';
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
    }

    local procedure FillTempVLE()
    var
        LSalesLineArachive: Record "Sales Line Archive";
    begin
        if PostingDate = 0D then
            PostingDate := Today();
        TempArchiveInsertHeader();
        Clear(TempSalesInvoiceHeader);

        Clear(TempVLE);
        if TempSalesInvoiceHeader.FindSet() then
            repeat
                LSalesLineArachive.SetRange("Document No.", TempSalesInvoiceHeader."No.");
                LSalesLineArachive.SetRange("Version No.", TempSalesInvoiceHeader."Version No.");
                if LSalesLineArachive.FindSet() then
                    repeat
                        if (LSalesLineArachive.LostINC) and (LSalesLineArachive."Reason CodeINC" = '2') then begin
                            TempVLE.Init();
                            i += 1;
                            TempVLE."Entry No." := i;
                            TempVLE."Posting Date" := TempSalesInvoiceHeader."Date Archived";
                            TempVLE."Item No." := LSalesLineArachive."No.";
                            TempVLE."Document No." := TempSalesInvoiceHeader."No.";
                            TempVLE."User ID" := CopyStr(LSalesLineArachive.Description, 1, MaxStrLen(UserId));
                            TempVLE.Description := TempSalesInvoiceHeader."Sell-to Customer Name";
                            TempVLE."Invoiced Quantity" := LSalesLineArachive."Quantity";
                            TempVLE."Cost per Unit" := LSalesLineArachive."Unit Price";
                            TempVLE."Purchase Amount (Actual)" := LSalesLineArachive."Amount";
                            TempVLE."Cost per Unit (ACY)" := LSalesLineArachive."Amount Including VAT";
                            TempVLE.Insert();
                        end;
                    until LSalesLineArachive.Next() = 0;

            until TempSalesInvoiceHeader.Next() = 0;

    end;

    local procedure TempArchiveInsertHeader()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        LastDocumentNo: Code[20];
    begin
        TempSalesInvoiceHeader.Reset();
        TempSalesInvoiceHeader.DeleteAll();
        LastDocumentNo := '';
        SalesHeaderArchive.Reset();
        SalesHeaderArchive.SetRange("Date Archived", PostingDate);
        SalesHeaderArchive.SetCurrentKey("No.", "Version No.");
        SalesHeaderArchive.Ascending(false);
        if SalesHeaderArchive.FindSet() then
            repeat
                if LastDocumentNo <> SalesHeaderArchive."No." then begin
                    LastDocumentNo := SalesHeaderArchive."No.";
                    TempSalesInvoiceHeader.Init();
                    TempSalesInvoiceHeader."No." := SalesHeaderArchive."No.";
                    TempSalesInvoiceHeader."Version No." := SalesHeaderArchive."Version No.";
                    TempSalesInvoiceHeader."Sell-to Customer No." := SalesHeaderArchive."Sell-to Customer No.";
                    TempSalesInvoiceHeader."Sell-to Customer Name" := SalesHeaderArchive."Sell-to Customer Name";
                    TempSalesInvoiceHeader."Bill-to Customer No." := SalesHeaderArchive."Bill-to Customer No.";
                    TempSalesInvoiceHeader."Posting Date" := SalesHeaderArchive."Posting Date";
                    TempSalesInvoiceHeader."Document Date" := SalesHeaderArchive."Document Date";
                    TempSalesInvoiceHeader."Date Archived" := SalesHeaderArchive."Date Archived";

                    TempSalesInvoiceHeader.Insert();
                end;
            until SalesHeaderArchive.Next() = 0;
    end;

    local procedure SegmentCheck(pItemNo: Code[20]) rtnvalue: Code[10]
    var
        LItem: record Item;
    begin
        Clear(LItem);
        if LItem.Get(pItemNo) then
            rtnvalue := LItem."Segmentfor Private HospitalINC";
    end;



    var
        i: Integer;
        CustomerRegionCode: code[20];
        PostingDate: Date;
        TempSalesInvoiceHeader: Record "Sales Header Archive" temporary;
        CompanyInformation: Record "Company Information";

}