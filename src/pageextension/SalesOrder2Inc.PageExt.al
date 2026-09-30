pageextension 70801 "Sales Order2_Inc" extends "Sales Order"
{
    actions
    {
        modify("Create &Warehouse Shipment")
        {
            trigger OnAfterAction()
            var
                LWarehouseShipmentHeader: Record "Warehouse Shipment Header";
                LWarehouseShipmentLine: Record "Warehouse Shipment Line";
                LCompany: Record "Company";
                LSalesLine: Record "Sales Line";
                LInciJobQueueEntryMang2Inc: Codeunit "Inci Job Queue Entry Mang2_Inc";
                LInciGen: codeunit InciGeneral_Inc;
            begin
                LSalesLine.Init();
                LSalesLine.SetRange("Document No.", Rec."No.");
                LSalesLine.SetRange("Document Type", Rec."Document Type");
                if LSalesLine.FindSet() then
                    repeat
                        Clear(LInciGen);
                        LInciGen.CheckNegativeStock(LSalesLine);
                    until LSalesLine.Next() = 0;

                Clear(LCompany);
                if LCompany.Get(CompanyName) then
                    if LCompany.Name = 'INC' then begin

                        Clear(LInciJobQueueEntryMang2Inc);
                        LInciJobQueueEntryMang2Inc.UpdateWHSH();
                        exit;
                    end;

                Clear(LInciJobQueueEntryMang2Inc);
                LWarehouseShipmentLine.Init();
                LWarehouseShipmentLine.SetRange("Source No.", Rec."No.");
                LWarehouseShipmentLine.SetRange("Source Type", 37);
                LWarehouseShipmentLine.Setrange("Source Subtype", LWarehouseShipmentLine."Source Subtype"::"1");
                if LWarehouseShipmentLine.FindFirst() then begin
                    if LWarehouseShipmentHeader.Get(LWarehouseShipmentLine."No.") then
                        LInciJobQueueEntryMang2Inc.WarehouseSeperate(LWarehouseShipmentHeader);

                end;
                Clear(LInciJobQueueEntryMang2Inc);
                LInciJobQueueEntryMang2Inc.UpdateWHSH();
            end;
        }
    }
}
