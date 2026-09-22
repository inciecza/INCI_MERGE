codeunit 70800 "Inci Job Queue Entry Mang2_Inc"
{

    TableNo = "Job Queue Entry";
    trigger OnRun()
    begin

        case Rec."Parameter String" of
            'sendmiadreport':
                SendMiadReport();
        end;
    end;



    local procedure SendMiadReport()
    var
        LStartDate: Date;
        LEndDate: Date;
    begin
        LStartDate := Today;
        LEndDate := CalcDate('<+6M>', LStartDate);
        if CheckMiadData(LStartDate, LEndDate) then
            SendMiadReportData(LStartDate, LEndDate);

    end;

    local procedure CheckMiadData(pStartDate: Date; pEndDate: Date): Boolean
    var
        LItemLedgerEntry: Record "Item Ledger Entry";
        LIncGenSetup: Record "Inci General Setup_Inc";
        LCompany: Record "Company";
    begin


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
        LItemLedgerEntry.SetRange("Expiration Date", pStartDate, pEndDate);

        if LItemLedgerEntry.FindSet() then
            exit(true);
        exit(false);
    end;

    procedure SendMiadReportData(pStartDate: Date; pEndDate: Date): Boolean
    var
        LMailingGroup: Record "Mailing Group";
        LReport: Report "Miad Stock Report_Inc";
        BodyBlob: Codeunit "Temp Blob";
        BodyBlob2: Codeunit "Temp Blob";
        LInciGeneralSetup: codeunit InciGeneral_Inc;
        AttchInStream: InStream;
        Instrm: InStream;
        AttchOutStream: OutStream;
        BodyStream: OutStream;
        body: Text;
        lBCCTo: List of [Text];
        lCCTo: List of [Text];
        lSendTo: List of [Text];
        lBCCtoAdd: Text;
        lCCtoAdd: Text;
        lsendToAdd: Text;
        FileName: Text[250];
        LMailSubject: Text[250];
        Text_Body1_Lbl: Label 'Merhaba,';
        Text_Body2_Lbl: Label 'Süresi yaklaşan stok kalemleri ektedir.';
        Text_Body3_Lbl: Label 'Saygılarımızla.';
        Text_MailSubject: Label 'Miad Stok Bilgilendirme Raporu';
        LText_FileName_Lbl: Label 'Miad Stok Raporu';
    begin
        if not LMailingGroup.Get('MIADR') then
            exit(false);

        lSendTo := LMailingGroup.TO_Inc.Split(';');
        lCCTo := LMailingGroup.CC_Inc.Split(';');
        lBCCTo := LMailingGroup.BCC_Inc.Split(';');

        LMailSubject := Text_MailSubject;

        // Body
        BodyBlob.CreateOutStream(BodyStream, TEXTENCODING::UTF8);
        BodyStream.WriteText(Text_Body1_Lbl + '<br><br>');
        BodyStream.WriteText(Text_Body2_Lbl + '<br><br>');
        BodyStream.WriteText(Text_Body3_Lbl);
        BodyBlob.CreateInStream(Instrm, TEXTENCODING::UTF8);
        Instrm.ReadText(body);

        // Attachment
        BodyBlob2.CreateOutStream(AttchOutStream);
        LReport.SetParameters(pStartDate, pEndDate);
        LReport.SaveAs('', ReportFormat::Excel, AttchOutStream);
        BodyBlob2.CreateInStream(AttchInStream);

        FileName :=
            Format(Date2DMY(Today, 3)) + '.' +
            Format(Date2DMY(Today, 2)) + '.' +
            Format(Date2DMY(Today, 1)) + '-' +
            LText_FileName_Lbl + '.xlsx';

        exit(
            LInciGeneralSetup.SendEmailviaSMTP(
                lSendTo,
                lCCTo,
                lBCCTo,
                LMailSubject,
                body,
                AttchInStream,
                FileName
            )

        );
    end;



    #region WarehouseSeperate

    procedure WarehouseSeperate(pWSH: Record "Warehouse Shipment Header")
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
        LWHShipmentLine.SetRange("No.", pWSH."No.");
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
        LWHShipmentLine.SetRange("No.", pWSH."No.");
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
                        LWHShipmentHeader.TransferFields(pWSH, false);
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

        Message('Sevkiyat ayrıştırma tamamlandı.');
    end;

    procedure UpdateWHSH()
    var
        LWSL: Record "Warehouse Shipment Line";
        LWSH: Record "Warehouse Shipment Header";
        LCustomer: Record Customer;
        LItemQuant: Decimal;
        LItemCount: Decimal;
    begin
        LWSH.Init();
        LWSH.SetRange("Field Update_Inc", false);
        if LWSH.FindSet() then
            repeat
                if LWSH."Customer Name_Inc" = '' then begin
                    Clear(LCustomer);
                    Clear(LWSL);
                    LWSL.SetRange("No.", LWSH."No.");
                    if LWSL.FindFirst() then
                        if LCustomer.Get(LWSL."Destination No.") then begin
                            LWSH."Customer Name_Inc" := LCustomer.Name;
                            LWSH."Customer Region Code_Inc" := LCustomer."Customer Region Code_Inc";

                        end;
                end;
                Clear(LItemQuant);
                Clear(LItemCount);
                Clear(LWSL);
                LWSL.SetRange("No.", LWSH."No.");
                if LWSL.FindSet() then
                    repeat
                        LItemQuant += LWSL.Quantity;
                        LItemCount += 1;
                    until LWSL.Next() = 0;

                LWSH."Total Item Count_Inc" := LItemCount;
                LWSH."Total Item Quantity_Inc" := LItemQuant;
                LWSH.Note_Inc := CopyStr(GetNote(LWSH."No."), 1, MaxStrLen(LWSH.Note_Inc));
                LWSH."Field Update_Inc" := true;
                LWSH.Modify();

            until LWSH.Next() = 0;

    end;

    local procedure GetNote(pWSLNo: Code[20]) rtnText: Text
    var
        LRecordLink: Record "Record Link";
        LWhseShptHeader: Record "Warehouse Shipment Header";
        LInStream: InStream;
    begin
        Clear(rtnText);

        if not LWhseShptHeader.Get(pWSLNo) then
            exit('');

        LRecordLink.SetRange(Company, CompanyName());
        LRecordLink.SetRange("Record ID", LWhseShptHeader.RecordId);
        LRecordLink.SetRange(Type, LRecordLink.Type::Note);

        if LRecordLink.FindLast() then begin
            LRecordLink.CalcFields(Note);

            if LRecordLink.Note.HasValue then begin
                LRecordLink.Note.CreateInStream(LInStream, TextEncoding::UTF8);
                LInStream.ReadText(rtnText);
            end;
        end;

        exit(rtnText);
    end;

    #endregion WarehouseSeperate
}