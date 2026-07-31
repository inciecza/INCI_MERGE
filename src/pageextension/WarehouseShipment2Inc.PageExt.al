pageextension 70802 "Warehouse Shipment2_Inc" extends "Warehouse Shipment"
{
    actions
    {
        addlast(Processing)
        {
            action("Separate Shipments_Inc")
            {
                ApplicationArea = All;
                Caption = 'Separate Shipments';
                Image = Shipment;
                trigger OnAction()
                begin
                    WarehouseSeperate();
                    CurrPage.Update();
                end;

            }
        }
    }

    local procedure WarehouseSeperate()
    var
        LWHShipmentLine: Record "Warehouse Shipment Line";
        LWHShipmentLine2: Record "Warehouse Shipment Line";
        LWHShipmentHeader: Record "Warehouse Shipment Header";
        LCategory: Record "Item Category";
        LItem: Record Item;
        LInciGenSet: Record "Inci General Setup_Inc";
        LSalesHeader: Record "Sales Header";
        LNoSeriesMgt: Codeunit "No. Series";
        LFirstWarehouseClass: Code[10];
        LFirstSortingCategory: Integer;
        LFirstLineFound: Boolean;
        // Yeni shipment'lar için kombinasyon → header no eşleşmesi
        // AL'de dictionary olmadığı için geçici tablo kullanıyoruz
        LTempMapping: Record "Warehouse Shipment Line" temporary;
        LNewHeaderNo: Code[20];
        LCurrentWarehouseClass: Code[10];
        LCurrentPrivateHospital: Integer;
        LNextLineNo: Integer;
        DocumentType: Option "Private Hospital","DMO Bid","Open Bid","Direct Supply Bid";
    begin
        Clear(LInciGenSet);
        LInciGenSet.Get();
        // --- 1. İlk satırın kombinasyonunu bul ---
        Clear(LWHShipmentLine);
        LWHShipmentLine.SetRange("No.", Rec."No.");
        LWHShipmentLine.SetCurrentKey("Line No.");
        LFirstLineFound := false;


        if LWHShipmentLine.FindSet() then begin
            // İlk satırın kombinasyonunu al
            Clear(LSalesHeader);
            if LSalesHeader.Get(LSalesHeader."Document Type"::Order, LWHShipmentLine."Source No.") then
                case LSalesHeader."Order/Document Type-B2F" of
                    'ST-ÖZEL HASTANE':
                        DocumentType := DocumentType::"Private Hospital";
                    'ST-DMO':
                        DocumentType := DocumentType::"DMO Bid";
                    'ST-AÇIK İHALE':
                        DocumentType := DocumentType::"Open Bid";
                    'ST-DOĞRUDAN TEMİN':
                        DocumentType := DocumentType::"Direct Supply Bid";
                    else
                        DocumentType := DocumentType::"Private Hospital"; // Varsayılan değer
                end
            else
                DocumentType := DocumentType::"Private Hospital"; // Varsayılan değer
            Clear(LItem);
            Clear(LCategory);
            if LItem.Get(LWHShipmentLine."Item No.") then begin
                LFirstWarehouseClass := LItem."Warehouse Class Code";
                if LCategory.Get(LItem."Item Category Code") then
                    case DocumentType of
                        DocumentType::"Private Hospital":
                            LFirstSortingCategory := LCategory."Private hospital_Inc";
                        DocumentType::"DMO Bid":
                            LFirstSortingCategory := LCategory."DMO Bid_Inc";
                        DocumentType::"Open Bid":
                            LFirstSortingCategory := LCategory."Open Bid_Inc";
                        DocumentType::"Direct Supply Bid":
                            LFirstSortingCategory := LCategory."Direct Supply Bid_Inc";
                        else
                            LFirstSortingCategory := LCategory."Private hospital_Inc";
                    end
                else
                    LFirstSortingCategory := 0;
            end;
            LFirstLineFound := true;
        end;

        if not LFirstLineFound then
            exit;

        // --- 2. Tüm satırları gez ---
        Clear(LWHShipmentLine);
        LWHShipmentLine.SetRange("No.", Rec."No.");
        LWHShipmentLine.SetCurrentKey("Line No.");

        if LWHShipmentLine.FindSet(true) then
            repeat
                Clear(LItem);
                Clear(LCategory);
                LCurrentWarehouseClass := '';
                LCurrentPrivateHospital := 0;

                if LItem.Get(LWHShipmentLine."Item No.") then begin
                    LCurrentWarehouseClass := LItem."Warehouse Class Code";
                    if LCategory.Get(LItem."Item Category Code") then
                        case DocumentType of
                            DocumentType::"Private Hospital":
                                LCurrentPrivateHospital := LCategory."Private hospital_Inc";
                            DocumentType::"DMO Bid":
                                LCurrentPrivateHospital := LCategory."DMO Bid_Inc";
                            DocumentType::"Open Bid":
                                LCurrentPrivateHospital := LCategory."Open Bid_Inc";
                            DocumentType::"Direct Supply Bid":
                                LCurrentPrivateHospital := LCategory."Direct Supply Bid_Inc";
                            else
                                LCurrentPrivateHospital := LCategory."Private hospital_Inc";
                        end;
                end;

                // İlk satırın kombinasyonuyla aynıysa → orijinal belgede bırak
                if (LCurrentWarehouseClass = LFirstWarehouseClass) and
                   (LCurrentPrivateHospital = LFirstSortingCategory) then begin
                    // Hiçbir şey yapma, bu satır kalıyor
                end else begin
                    // --- 3. Bu kombinasyon için daha önce header açıldı mı? ---
                    // Geçici mapping tablosunda ara
                    // "Bin Code" alanını WarehouseClass, "Zone Code" alanını PrivateHospital (text) olarak kullanıyoruz
                    LNewHeaderNo := '';
                    Clear(LTempMapping);
                    LTempMapping.SetRange("Bin Code", LCurrentWarehouseClass);
                    LTempMapping.SetRange("Zone Code", Format(LCurrentPrivateHospital));
                    if LTempMapping.FindFirst() then
                        LNewHeaderNo := LTempMapping."No."
                    else begin
                        // Yeni Warehouse Shipment Header oluştur
                        Clear(LWHShipmentHeader);
                        LWHShipmentHeader.Init();
                        LWHShipmentHeader.TransferFields(Rec, false);
                        Clear(LNoSeriesMgt);
                        LWHShipmentHeader."No." := LNoSeriesMgt.GetNextNo(LInciGenSet."Warehouse Sep.No Series"); // Numara serisi otomatik atansın
                        LWHShipmentHeader.Insert(true);
                        LNewHeaderNo := LWHShipmentHeader."No.";

                        // Mapping'e kaydet
                        Clear(LTempMapping);
                        LTempMapping.Init();
                        LTempMapping."No." := LNewHeaderNo;
                        LTempMapping."Bin Code" := LCurrentWarehouseClass;
                        LTempMapping."Zone Code" := Format(LCurrentPrivateHospital);
                        LTempMapping."Line No." := LTempMapping."Line No." + 1;
                        LTempMapping.Insert();
                    end;

                    // --- 4. Yeni Header'a Line ekle ---
                    // Yeni header'daki son line no'yu bul
                    Clear(LWHShipmentLine2);
                    LWHShipmentLine2.SetRange("No.", LNewHeaderNo);
                    if LWHShipmentLine2.FindLast() then
                        LNextLineNo := LWHShipmentLine2."Line No." + 10000
                    else
                        LNextLineNo := 10000;

                    Clear(LWHShipmentLine2);
                    LWHShipmentLine2.Init();
                    LWHShipmentLine2.TransferFields(LWHShipmentLine, true);
                    LWHShipmentLine2."No." := LNewHeaderNo;
                    LWHShipmentLine2."Line No." := LNextLineNo;
                    LWHShipmentLine2.Insert(true);

                    // --- 5. Orijinal satırı sil ---
                    LWHShipmentLine.Delete(true);
                end;

            until LWHShipmentLine.Next() = 0;

        Message('Shipment ayrıştırma tamamlandı.');
    end;
}