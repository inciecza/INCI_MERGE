report 70812 "Pending Order Report_Inc"
{
    Caption = 'Pending Order Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    ApplicationArea = All;
    RDLCLayout = './src/layout/Pending Order Report.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;

            column(GirisNo; "Entry No.")
            {
            }
            column(IslemTarihi; SystemCreatedAt)
            {
            }
            column(MaddeNo; "Item No.")
            {
            }
            column(MaddeAdi; GetItemDescription("Item No."))
            {
            }
            column(FaturaNo; "Document No.")
            {
            }
            column(MusteriAd; Description)
            {
            }
            column(BirimFiyat; "Cost per Unit")
            {
            }
            column(Tutar; "Purchase Amount (Actual)")
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
            column(Segment; "Job Task No.")
            {
            }
            column(Merkez_Temsilci; "Order No.")
            {

            }
            column(Saha_Temsilci; "Item Charge No.")
            {

            }
            column(DetayGoster; "Document Line No.")
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
                        ToolTip = 'Select the responsibility center or enter a filter.';
                        Editable = ResponsControl;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            ResponsibilityCenter: Record "Responsibility Center";
                        begin
                            if Page.RunModal(Page::"Responsibility Center List", ResponsibilityCenter) = Action::LookupOK then begin
                                ResponsibilityCode := ResponsibilityCenter.Code;
                                exit(true);
                            end;
                        end;
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
                    field(viewDetailData; ViewDetailData)
                    {
                        ApplicationArea = All;
                        Caption = 'View Detail Data';
                        ToolTip = 'Select to include View Detail Data in the report.';
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
        LUserSetup: Record "User Setup";

        LWarehouseShipment: Record "Warehouse Shipment Header";
        LWarehouseShipmentLine: Record "Warehouse Shipment Line";
        LSalesHeader: Record "Sales Header";
        LSalesLine: Record "Sales Line";
    begin
        Clear(TempVLE);
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


        Clear(LWarehouseShipmentLine);
        LWarehouseShipmentLine.SetRange("Source Type", 37);
        LWarehouseShipmentLine.SetRange("Source Subtype", LSalesHeader."Document Type"::Order);
        LWarehouseShipmentLine.SetRange(SystemCreatedAt, CreateDateTime(StartDate, 000000T), CreateDateTime(EndDate, 235959T));
        if LWarehouseShipmentLine.FindSet() then
            repeat
                Clear(LSalesLine);
                if ResponsibilityCode <> '' then
                    LSalesLine.SetFilter("Responsibility Center", ResponsibilityCode);
                LSalesLine.SetRange("Document Type", LSalesLine."Document Type"::Order);
                LSalesLine.SetRange("Document No.", LWarehouseShipmentLine."Source No.");
                LSalesLine.SetRange("Line No.", LWarehouseShipmentLine."Source Line No.");
                LSalesLine.SetRange("Order/Document Type-B2F", 'ST-ÖZEL HASTANE');
                if LSalesLine.FindSet() then begin
                    TempVLE.Init();
                    i += 1;
                    LSalesLine.calcFields("Sell-to Customer Name");
                    TempVLE."Entry No." := i;
                    TempVLE.SystemCreatedAt := LWarehouseShipmentLine.SystemCreatedAt;
                    TempVLE."Item No." := LSalesLine."No.";
                    //   TempVLE.CalcFields("Item Description");
                    // TempVLE."User ID" := TempVLE."Item Description";
                    TempVLE."Document No." := LSalesLine."Document No.";
                    TempVLE.Description := LSalesLine."Sell-to Customer Name";
                    TempVLE."Valued Quantity" := LWarehouseShipmentLine.Quantity; // Miktar
                    TempVLE."Cost per Unit" := LSalesLine."Unit Price"; // Birim Fiyat
                    TempVLE."Cost Amount (Non-Invtbl.)" := LWarehouseShipmentLine.Quantity * LSalesLine."Unit Price"; // Tutar Kdv Hariç
                    TempVLE."External Document No." := CopyStr(LSalesLine."Responsibility Center", 1, maxStrLen(LSalesLine."Responsibility Center"));
                    TempVLE."Job Task No." := SegmentCheck(LSalesLine."No.");
                    TempVLE."Order No." := GetSalesRepresentatives(LSalesLine."Responsibility Center", 1); //Merkez Temsilci
                    TempVLE."Item Charge No." := GetSalesRepresentatives(LSalesLine."Responsibility Center", 2); // Saha Temsilci
                    if viewDetailData then
                        TempVLE."Document Line No." := 1;
                    TempVLE.Insert();
                end;

            until LWarehouseShipmentLine.Next() = 0;
    end;

    local procedure GetSalesRepresentatives(SalesRepresentatives: code[10]; Index: Integer) rtnvalue: code[20]
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

    local procedure GetItemDescription(pItemNo: Code[20]) rtnvalue: Text[100]
    var
        LItem: record Item;
    begin
        Clear(LItem);
        if LItem.Get(pItemNo) then
            exit(LItem.Description);
    end;


    var
        i: Integer;
        ResponsibilityCode: code[10];
        StartDate: Date;
        EndDate: Date;
        ResponsControl: boolean;
        ViewDetailData: boolean;

}