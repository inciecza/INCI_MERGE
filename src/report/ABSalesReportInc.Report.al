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
            column(SevkBekleyenMiktar; "Valued Quantity")
            {
            }
            column(SevkBekleyenTutar; "Cost Amount (Non-Invtbl.)")
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

                    field(ResponsibilityCode; ResponsibilityCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Responsibility Center';
                        ToolTip = 'Select the responsibility center to filter the report.';
                        TableRelation = "Responsibility Center";
                        Editable = ResponsControl;
                    }
                    field(Segment; SegmentOption)
                    {
                        ApplicationArea = All;
                        Caption = 'Segment';
                        ToolTip = 'Select the segment to filter the report.';
                    }
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

            Clear(LUserSetup);
            LUserSetup.Get(UserId);
            if LUserSetup."Sales Lines and Qty Contrl_Inc" then begin
                ResponsibilityCode := LUserSetup."Sales Resp. Ctr. Filter";
                ResponsControl := false;
            end
            else
                ResponsControl := true;

        end;
    }

    local procedure FillTempVLE()
    var
        LSalesInvoiceHeader: Record "Sales Invoice Header";
        LSalesInvoiceLine: Record "Sales Invoice Line";
        LUserSetup: Record "User Setup";
    begin
        Clear(TempVLE);
        LSalesInvoiceHeader.SetRange("Cancelled", false);
        if StartDate = 0D then
            error('Start Date cannot be empty. Please select a valid start date.');
        if EndDate = 0D then
            error('End Date cannot be empty. Please select a valid end date.');

        /* if ResponsibilityCode = '' then
             error('Responsibility Center cannot be empty. Please select a valid responsibility center.');
             */

        Clear(LUserSetup);
        LUserSetup.Get(UserId);
        if LUserSetup."Sales Lines and Qty Contrl_Inc" then
            if LUserSetup."Sales Resp. Ctr. Filter" <> ResponsibilityCode then
                ResponsibilityCode := LUserSetup."Sales Resp. Ctr. Filter";


        LSalesInvoiceHeader.SetRange("Posting Date", StartDate, EndDate);
        if ResponsibilityCode <> '' then
            LSalesInvoiceHeader.SetRange("Responsibility Center", ResponsibilityCode);
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
                        TempVLE."Invoiced Quantity" := LSalesInvoiceLine."Quantity"; // Miktar
                        TempVLE."Cost per Unit" := LSalesInvoiceLine."Unit Price"; // Birim Fiyat
                        TempVLE."Purchase Amount (Actual)" := LSalesInvoiceLine."Amount"; // Tutar Kdv Hariç
                        TempVLE."Cost per Unit (ACY)" := LSalesInvoiceLine."Amount Including VAT"; // Tutar Kdv Dahil
                        TempVLE."External Document No." := CopyStr(LSalesInvoiceHeader."Responsibility Center", 1, maxStrLen(LSalesInvoiceHeader."Responsibility Center"));
                        if SegmentCheck(LSalesInvoiceLine."No.") then
                            TempVLE.Insert();
                    until LSalesInvoiceLine.Next() = 0;
            until LSalesInvoiceHeader.Next() = 0;
        InsertWarehouseShipment();
    end;

    local procedure InsertWarehouseShipment()
    var
        LWarehouseShipment: Record "Warehouse Shipment Header";
        LWarehouseShipmentLine: Record "Warehouse Shipment Line";
        LSalesHeader: Record "Sales Header";
        LSalesLine: Record "Sales Line";
    begin
        Clear(LWarehouseShipmentLine);
        LWarehouseShipmentLine.SetRange("Source Type", 37);
        LWarehouseShipmentLine.SetRange("Source Subtype", LSalesHeader."Document Type"::Order);
        LWarehouseShipmentLine.SetRange(SystemCreatedAt, CreateDateTime(StartDate, 000000T), CreateDateTime(EndDate, 235959T));
        if LWarehouseShipmentLine.FindSet() then
            repeat
                Clear(LSalesLine);
                LSalesLine.SetRange("Responsibility Center", ResponsibilityCode);
                LSalesLine.SetRange("Document Type", LSalesLine."Document Type"::Order);
                LSalesLine.SetRange("Document No.", LWarehouseShipmentLine."Source No.");
                LSalesLine.SetRange("Line No.", LWarehouseShipmentLine."Source Line No.");
                LSalesLine.SetRange("Order/Document Type-B2F", 'ST-ÖZEL HASTANE');
                if LSalesLine.FindSet() then begin
                    TempVLE.Init();
                    i += 1;
                    TempVLE."Entry No." := i;
                    TempVLE."Posting Date" := LSalesLine."Posting Date";
                    TempVLE."Item No." := LSalesLine."No.";
                    TempVLE."User ID" := '';
                    TempVLE."Document No." := LSalesLine."Document No.";
                    TempVLE.Description := LSalesLine."Sell-to Customer Name";
                    TempVLE."Valued Quantity" := LSalesLine.Quantity; // Miktar
                    TempVLE."Cost per Unit" := 0; // Birim Fiyat
                    TempVLE."Cost Amount (Non-Invtbl.)" := LSalesLine.Amount; // Tutar Kdv Hariç
                    TempVLE."Cost per Unit (ACY)" := 0; // Tutar Kdv Dahil
                    TempVLE."External Document No." := CopyStr(LSalesLine."Responsibility Center", 1, maxStrLen(LSalesLine."Responsibility Center"));
                    if SegmentCheck(LSalesLine."No.") then
                        TempVLE.Insert();
                end;

            until LWarehouseShipmentLine.Next() = 0;
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
        ResponsibilityCode: code[10];
        StartDate: Date;
        EndDate: Date;
        SegmentOption: Option "AB","REÇETELİ";
        ResponsControl: boolean;

}