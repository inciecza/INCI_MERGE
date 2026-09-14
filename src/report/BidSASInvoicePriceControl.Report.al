report 70817 "Bid SAS Invoice Price Control"
{
    ApplicationArea = All;
    Caption = 'Bid SAS Invoice Price Control';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Bid SAS Invoice Price Control.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;
            column(Fark; "External Document No.")
            {
            }
            column(Fatura_Tarihi; "Posting Date")
            {
            }
            column(Fatura_No; "Document No.")
            {
            }
            column("Sipariş_Tarihi"; "Document Date")
            {
            }
            column("Sipariş_No"; "Job Task No.")
            {
            }
            column("Chs_Ünvanı"; Description)
            {
            }
            column("Stok_Adı"; "Item Description")
            {
            }
            column("Sipariş_Vadesi"; "Job No.")
            {
            }
            column(Fatura_Vadesi; "Job Task No.")
            {
            }
            column("Sipariş_Miktarı"; "Valued Quantity")
            {
            }
            column("Giriş_Miktarı"; "Invoiced Quantity")
            {
            }
            column("Fatura_Fiyatı"; "Cost per Unit")
            {
            }
            column("Sipariş_Fiyatı"; "Cost per Unit (ACY)")
            {
            }
            column("Birim_Fiyat_Farkı"; "Purchase Amount (Actual)")
            {
            }
            column("Toplam_Fiyat_Farkı"; "Purchase Amount (Expected)")
            {
            }
            column(Chs_Kodu; "Source No.")
            {
            }
            column(Stok_Kodu; "Item No.")
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
        LPurcInvHeader: record "Purch. Inv. Header";
        LPurcInvLine: record "Purch. Inv. Line";
        LPurchHeaderArchive: Record "Purchase Header Archive";
        LPurchLineArchive: Record "Purchase Line Archive";
    begin
        Clear(TempVLE);
        LPurcInvHeader.SetRange("Cancelled", false);
        if StartDate = 0D then
            error('Start Date cannot be empty. Please select a valid start date.');
        if EndDate = 0D then
            error('End Date cannot be empty. Please select a valid end date.');

        LPurcInvHeader.SetRange("Posting Date", StartDate, EndDate);
        if LPurcInvHeader.FindSet() then
            repeat
                if (LPurcInvHeader."Order/Document Type-B2F" = 'ST-DMO') or
                (LPurcInvHeader."Order/Document Type-B2F" = 'ST-DMO KATALOG') or
               (LPurcInvHeader."Order/Document Type-B2F" = 'ST-DOĞRUDAN TEMİN') or
                (LPurcInvHeader."Order/Document Type-B2F" = 'ST-ÖZEL HASTANE') then begin


                    LPurcInvLine.Init();
                    LPurcInvLine.SetRange("Document No.", LPurcInvHeader."No.");
                    LPurcInvLine.SetRange(Type, LPurcInvLine.Type::Item);
                    if LPurcInvLine.FindSet() then begin
                        LPurchHeaderArchive.Init();
                        LPurchHeaderArchive.SetRange("Document Type", LPurchHeaderArchive."Document Type"::Order);
                        LPurchHeaderArchive.SetRange("No.", LPurcInvLine."Order No.");
                        LPurchHeaderArchive.SetCurrentKey("Version No.");
                        if LPurchHeaderArchive.FindLast() then;
                    end;
                    repeat
                        TempVLE.Init();
                        i += 1;
                        TempVLE."Entry No." := i;
                        TempVLE."Posting Date" := LPurcInvHeader."Posting Date"; // Fatura Tarihi
                        TempVLE."Document No." := LPurcInvHeader."Vendor Invoice No."; // Fatura No
                        TempVLE."Document Date" := LPurchHeaderArchive."Order Date"; // Sipariş Tarihi
                        TempVLE."Job Task No." := LPurchHeaderArchive."No."; // Sipariş No
                        TempVLE."Source No." := LPurcInvHeader."Buy-from Vendor No."; // Chs Kodu
                        TempVLE.Description := LPurcInvHeader."Buy-from Vendor Name"; //Chs Ünvanı
                        TempVLE."Item No." := LPurcInvLine."No."; //Stok No
                        TempVLE.CalcFields("Item Description"); // Stok Adı
                        TempVLE."Job No." := LPurcInvLine."Payment Terms Code-INC"; //Sipariş Vadesi
                        TempVLE."Job Task No." := LPurcInvLine."Payment Terms Code-INC";//Fatura Vadesi
                        LPurchLineArchive.Init();
                        LPurchLineArchive.SetRange("Document No.", LPurchHeaderArchive."No.");
                        LPurchLineArchive.SetRange(Type, LPurchLineArchive.Type::Item);
                        LPurchLineArchive.SetRange("Line No.", LPurcInvLine."Line No.");
                        if LPurchLineArchive.FindSet() then begin
                            TempVLE."Valued Quantity" := LPurchLineArchive."Quantity"; //Sipariş Miktarı
                            TempVLE."Cost per Unit (ACY)" := LPurchLineArchive."Direct Unit Cost"; //Sipariş Fiyatı
                        end;
                        TempVLE."Invoiced Quantity" := LPurcInvLine."Quantity"; // Giriş Miktarı
                        TempVLE."Cost per Unit" := LPurcInvLine."Direct Unit Cost"; // Fatura Fiyatı
                        TempVLE."Purchase Amount (Actual)" := LPurcInvLine."Direct Unit Cost" - LPurchLineArchive."Direct Unit Cost";//Birim Fiyat Farkı
                        TempVLE."Purchase Amount (Expected)" := TempVLE."Purchase Amount (Actual)" * TempVLE."Invoiced Quantity"; //Toplam Fiyat Farkı
                        if TempVLE."Purchase Amount (Expected)" > 0 then
                            TempVLE."External Document No." := 'Fazla kesilen'
                        else if TempVLE."Purchase Amount (Expected)" < 0 then
                            TempVLE."External Document No." := 'Eksik kesilen';

                        /*
                        TempVLE."User ID" := CopyStr(LSalesInvoiceHeader."User ID", 1, 50);
                        TempVLE."Purchase Amount (Actual)" := LSalesInvoiceLine."Amount"; // Tutar Kdv Hariç
                        TempVLE."External Document No." := CopyStr(LSalesInvoiceLine."Responsibility Center", 1, maxStrLen(LSalesInvoiceHeader."Responsibility Center"));

                        TempVLE."Order No." := GetSalesRepresentatives(LSalesInvoiceLine."Responsibility Center", 1); //Merkez Temsilci
                        TempVLE."Item Charge No." := GetSalesRepresentatives(LSalesInvoiceLine."Responsibility Center", 2); // Saha Temsilci
                        */
                        TempVLE.Insert();
                    until LPurcInvLine.Next() = 0;
                end;
            until LPurcInvHeader.Next() = 0;
        //InsertWarehouseShipment();
    end;

    local procedure GetSalesRepresentatives(SalesRepresentatives: code[10];
Index: Integer) rtnvalue: code[20]
    var
        LResponsibilityCenter: Record "Responsibility Center";
        LCustomerRegion: record "Customer Regions_Inc";
    begin
        Clear(LResponsibilityCenter);
        Clear(LCustomerRegion);
        if LResponsibilityCenter.Get(SalesRepresentatives) then
            if LCustomerRegion.Get(LResponsibilityCenter."Customer Region_Inc") then begin
                LCustomerRegion.CalcFields("Central Repre. Name_Inc", "Sales Field Repre. Name_Inc");
                if Index = 1 then
                    exit(LCustomerRegion."Central Repre. Name_Inc")
                else if Index = 2 then
                    exit(LCustomerRegion."Sales Field Repre. Name_Inc");
            end;
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
                //  LSalesLine.SetRange("Responsibility Center", ResponsibilityCode);
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
                    TempVLE."Job Task No." := SegmentCheck(LSalesLine."No.");
                    TempVLE.Insert();
                end;

            until LWarehouseShipmentLine.Next() = 0;
    end;

    local procedure SegmentCheck(pItemNo: Code[20]) rtnvalue: code[20]
    var
        LItem: record Item;
    begin
        Clear(LItem);
        if LItem.Get(pItemNo) then
            if LItem."No." = '26700' then
                exit('Keytruda')
            else
                exit(LItem."Segmentfor Private HospitalINC");
    end;




    var
        i: Integer;
        StartDate: Date;
        EndDate: Date;

}