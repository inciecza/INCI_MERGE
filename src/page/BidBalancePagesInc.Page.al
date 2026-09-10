page 70803 "Bid Balance Pages_Inc"
{
    ApplicationArea = All;
    Caption = 'Bid Balance Pages';
    PageType = List;
    UsageCategory = Lists;
    Editable = false;
    SourceTable = "Bid Final-Assessment Line-INC";
    SourceTableView = sorting("Bid No.", "Line No.");

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Durumu; BidHeader.Status)
                {
                    ApplicationArea = All;
                    Caption = 'Durumu', Locked = true;
                }
                field(IhaleTarihi; BidHeader."Bid Date-Hour")
                {
                    ApplicationArea = All;
                    Caption = 'İhale Tarihi', Locked = true;
                }
                field(Sehir; Rec.City)
                {
                    ApplicationArea = All;
                    Caption = 'Şehir', Locked = true;
                }
                field(IhaleKayitNo; BidHeader."Bid Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'İhale Kayıt No', Locked = true;
                }
                field(Tipi; BidHeader."Bid Class")
                {
                    ApplicationArea = All;
                    Caption = 'Tipi', Locked = true;
                }
                field(UniteKodu; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Ünite Kodu', Locked = true;
                }
                field(UniteAdi; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'Ünite Adı', Locked = true;
                }
                field(SozlesmeBitisTarihi; BidHeader."Contract Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Sözleşme Bitiş Tarihi', Locked = true;
                }
                field(Sozlesme; ContractSignedTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Sözleşme', Locked = true;
                }
                field(SiraNo; Rec."External Line No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sıra No', Locked = true;
                }
                field(StokKodu; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Stok Kodu', Locked = true;
                }
                field(Uretici; ManufacturerName)
                {
                    ApplicationArea = All;
                    Caption = 'Üretici', Locked = true;
                }
                field(Barkod; Rec.GTIN)
                {
                    ApplicationArea = All;
                    Caption = 'Barkod', Locked = true;
                }
                field(StokAdi; Rec."Item Description")
                {
                    ApplicationArea = All;
                    Caption = 'Stok Adı', Locked = true;
                }
                field(KazanilanMiktar; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Caption = 'Kazanılan Miktar', Locked = true;
                }
                field(PlusMinusMiktar; Rec."+/- Quantity")
                {
                    ApplicationArea = All;
                    Caption = '(+/-) Miktar', Locked = true;
                }
                field(Birim; Rec."Unit of Measure")
                {
                    ApplicationArea = All;
                    Caption = 'Birim', Locked = true;
                }
                field(Fiyat; Rec."Price Won")
                {
                    ApplicationArea = All;
                    Caption = 'Fiyat', Locked = true;
                }
                field(ToplamTutar; Rec."Total Quote")
                {
                    ApplicationArea = All;
                    Caption = 'Toplam Tutar', Locked = true;
                }
                field(TAlinanSiparis; TAlinanSiparisQty)
                {
                    ApplicationArea = All;
                    Caption = 'T.Alınan Sipariş', Locked = true;
                }
                field(TSevkEdilenSiparis; TSevkEdilenSiparisQty)
                {
                    ApplicationArea = All;
                    Caption = 'T.Sevk Edilen Sipariş', Locked = true;
                }
                field(SiparisBakiye; SiparisBakiyeQty)
                {
                    ApplicationArea = All;
                    Caption = 'Sipariş Bakiye', Locked = true;
                }

                // TODO: "İhale Bakiye" - mapping/kaynak henüz netleşmedi.

                field(SevkTutar; SevkTutarAmt)
                {
                    ApplicationArea = All;
                    Caption = 'Sevk Tutar', Locked = true;
                }
                field(FaturaYeniFiyat; FaturaYeniFiyatValue)
                {
                    ApplicationArea = All;
                    Caption = 'Fatura Yeni Fiyat', Locked = true;
                }
                field(Maliyet; MaliyetValue)
                {
                    ApplicationArea = All;
                    Caption = 'Maliyet', Locked = true;
                }
                field(FiyatFarki; FiyatFarkiTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Fiyat Farkı', Locked = true;
                }
                field(DonenVade; DonenVadeCode)
                {
                    ApplicationArea = All;
                    Caption = 'Dönen Vade', Locked = true;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetHeaderInfo();
        GetManufacturerInfo();
        GetContractSignedInfo();
        GetSalesOrderInfo();
        GetPurchaseRequestInfo();
        GetFiyatFarkiInfo();
    end;

    var
        BidHeader: Record "Bid Header-INC";
        Item: Record Item;
        Manufacturer: Record Manufacturer;
        SalesLine: Record "Sales Line";
        PurchReqLine: Record "Bid Purchase Request Line-INC";
        ManufacturerName: Text[100];
        ContractSignedTxt: Text[100];
        FiyatFarkiTxt: Text[10];
        TAlinanSiparisQty: Decimal;
        TSevkEdilenSiparisQty: Decimal;
        SiparisBakiyeQty: Decimal;
        SevkTutarAmt: Decimal;
        FaturaYeniFiyatValue: Decimal;
        MaliyetValue: Decimal;
        DonenVadeCode: Code[10];

    local procedure GetHeaderInfo()
    begin
        if not BidHeader.Get(Rec."Bid No.") then
            Clear(BidHeader);
    end;

    local procedure GetManufacturerInfo()
    begin
        ManufacturerName := '';
        if Item.Get(Rec."Item No.") then
            if Item."Manufacturer Code" <> '' then
                if Manufacturer.Get(Item."Manufacturer Code") then
                    ManufacturerName := Manufacturer.Name;
    end;

    local procedure GetContractSignedInfo()
    begin
        ContractSignedTxt := '';
        if BidHeader."Contract Signed" then
            ContractSignedTxt := 'Yapıldı'
        else
            ContractSignedTxt := 'Yapılmadı';
    end;

    local procedure GetFiyatFarkiInfo()
    begin
        if BidHeader."Price Diff. Will be Applied" then
            FiyatFarkiTxt := 'VAR'
        else
            FiyatFarkiTxt := 'YOK';
    end;

    local procedure GetSalesOrderInfo()
    begin
        TAlinanSiparisQty := 0;
        TSevkEdilenSiparisQty := 0;
        SiparisBakiyeQty := 0;
        SevkTutarAmt := 0;
        FaturaYeniFiyatValue := 0;
        if Rec."Blanket Sales Order No." <> '' then
            exit;
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Blanket Order");
        SalesLine.SetRange("Document No.", Rec."Blanket Sales Order No.");
        SalesLine.SetRange("Bid No.INC", Rec."Bid No.");
        SalesLine.SetRange("External Line No.INC", Rec."External Line No.");
        if SalesLine.FindSet() then
            repeat
                TAlinanSiparisQty += SalesLine.Quantity;
                TSevkEdilenSiparisQty += SalesLine."Qty. to Ship";
                SiparisBakiyeQty += SalesLine."Outstanding Qty. (Base)";
                SevkTutarAmt += SalesLine."Qty. to Ship" * SalesLine."Unit Price";
                FaturaYeniFiyatValue := SalesLine."Unit Price";
            until SalesLine.Next() = 0;
    end;

    local procedure GetPurchaseRequestInfo()
    begin
        MaliyetValue := 0;
        DonenVadeCode := '';

        PurchReqLine.Reset();
        PurchReqLine.SetRange("Bid No.", Rec."Bid No.");
        PurchReqLine.SetRange("Document Line No.", Rec."Line No.");
        if PurchReqLine.FindFirst() then begin
            MaliyetValue := PurchReqLine."Direct Unit Cost";
            DonenVadeCode := PurchReqLine."Payment Terms Code";
        end;
    end;
}