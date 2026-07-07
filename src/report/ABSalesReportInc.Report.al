report 70801 "AB Sales Report_Inc"
{
    ApplicationArea = All;
    Caption = 'AB Sales Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/AB Sales Report.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;

            column(GirisNo; "Entry No.")
            {
            }
            column(Tarih; "Posting Date")
            {
            }
            column(MaddeNo; "Item No.")
            {
            }
            column(MaddeAdi; "User ID")
            {
            }
            column(FaturaNo; "Document No.")
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
            column(MusteriBolgesi; "External Document No.")
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

                    field(CustomerRegion; CustomerRegionCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Customer Region';
                        ToolTip = 'Select the customer region to filter the report.';
                        TableRelation = "Customer Regions_Inc";
                    }
                    field(Segment; SegmentOption)
                    {
                        ApplicationArea = All;
                        Caption = 'Segment';
                        ToolTip = 'Select the segment to filter the report.';
                    }
                    field(StartDate; Stardate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'Select the start date to filter the report.';
                    }
                    field(EndDate; Enddate)
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
    }

    local procedure FillTempVLE()
    var
        LSalesInvoiceHeader: Record "Sales Invoice Header";
        LSalesInvoiceLine: Record "Sales Invoice Line";
    begin
        Clear(TempVLE);
        LSalesInvoiceHeader.SetRange("Cancelled", false);
        if Stardate <> 0D then
            error('Start Date cannot be empty. Please select a valid start date.');
        if enddate <> 0D then
            error('End Date cannot be empty. Please select a valid end date.');
        if customerRegionCode = '' then
            error('Customer Region cannot be empty. Please select a valid customer region.');
        LSalesInvoiceHeader.SetRange("Posting Date", Stardate, Enddate);
        LSalesInvoiceHeader.SetRange("Customer Region Code_Inc", CustomerRegionCode);
        if LSalesInvoiceHeader.FindSet() then
            repeat
                LSalesInvoiceLine.SetRange("Document No.", LSalesInvoiceHeader."No.");
                if LSalesInvoiceLine.FindSet() then
                    repeat
                        TempVLE.Init();
                        i += 1;
                        TempVLE."Entry No." := i;
                        TempVLE."Posting Date" := LSalesInvoiceHeader."Posting Date";
                        TempVLE."Item No." := LSalesInvoiceLine."No.";
                        TempVLE."User ID" := CopyStr(LSalesInvoiceHeader."User ID", 1, 50);
                        TempVLE."Document No." := LSalesInvoiceHeader."No.";
                        TempVLE.Description := LSalesInvoiceHeader."Sell-to Customer Name";
                        TempVLE."Invoiced Quantity" := LSalesInvoiceLine."Quantity";
                        TempVLE."Cost per Unit" := LSalesInvoiceLine."Unit Price";
                        TempVLE."Purchase Amount (Actual)" := LSalesInvoiceLine."Amount";
                        TempVLE."Cost per Unit (ACY)" := LSalesInvoiceLine."Amount Including VAT";
                        TempVLE."External Document No." := LSalesInvoiceHeader."Customer Region Code_Inc";
                        if SegmentCheck(LSalesInvoiceLine."No.") then
                            TempVLE.Insert();
                    until LSalesInvoiceLine.Next() = 0;
            until LSalesInvoiceHeader.Next() = 0;

    end;

    local procedure SegmentCheck(pItemNo: Code[20]) rtnvalue: boolean
    var
        LItem: record Item;
    begin
        Clear(LItem);
        LItem.Get(pItemNo);
        case
            SegmentOption of
            SegmentOption::"AB":
                begin
                    if (LItem."Segmentfor Private HospitalINC" = 'A GRUBU') or (LItem."Segmentfor Private HospitalINC" = 'B GRUBU') then
                        exit(true)
                    else
                        exit(false);
                end;
            SegmentOption::"REÇETELİ":
                begin
                    if (LItem."Segmentfor Private HospitalINC" = 'REÇETELİ') then
                        exit(true)
                    else
                        exit(false);
                end;
        end;

    end;



    var
        i: Integer;
        CustomerRegionCode: code[20];
        Stardate: Date;
        Enddate: Date;
        SegmentOption: Option "AB","REÇETELİ";

}