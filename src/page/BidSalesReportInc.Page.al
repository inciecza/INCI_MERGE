page 70805 "Bid Sales Report_Inc"
{
    ApplicationArea = All;
    Caption = 'Bid Sales Report';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "Value Entry";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    RefreshOnActivate = false;

    layout
    {
        area(Content)
        {
            group(Filtreler)
            {
                Caption = 'Filtreler', locked = true;


                field(StartDateFilterField; StartDateFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Başlangıç Tarihi', locked = true;
                    ToolTip = 'Verilerin getirileceği dönemin başlangıç tarihini seçin.', locked = true;
                }
                field(EndDateFilterField; EndDateFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Bitiş Tarihi', locked = true;
                    ToolTip = 'Verilerin getirileceği dönemin bitiş tarihini seçin.', locked = true;
                }
                field(OrderDocumentTypeFilterField; OrderDocumentTypeFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Order/Document Type', locked = true;
                    ToolTip = 'Sipariş/Belge tipini seçin. Boş bırakılırsa tümü getirilir.', locked = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LDocType: Record "Order/Document Type-B2F";
                    begin
                        LDocType.SetRange(Area, LDocType.Area::Sales);
                        LDocType.SetRange("Global Dimension 1 Code", '01.02.03');
                        if Page.RunModal(0, LDocType) in [Action::LookupOK, Action::OK] then begin
                            OrderDocumentTypeFilter := LDocType.Code;
                            Text := LDocType.Code;
                            exit(true);
                        end;
                    end;
                }
            }

            repeater(General)
            {
                Editable = false;
                field(Yil; Rec."Source Code")
                {
                    ApplicationArea = All;
                    Caption = 'Yıl', locked = true;
                }
                field(Ay; Rec."Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ay', locked = true;
                }
                field(FaturaTarihi; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Fatura Tarihi', locked = true;
                }
                field(FaturaNo; Rec."Salespers./Purch. Code")
                {
                    ApplicationArea = All;
                    Caption = 'Fatura No', locked = true;
                }
                field(UniteAdi; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Ünite Adı', locked = true;
                }
                field(SevkYeri; Rec."Source Description-B2F")
                {
                    ApplicationArea = All;
                    Caption = 'Sevk Yeri', locked = true;
                }
                field(SevkSehri; Rec."Job Task No.")
                {
                    ApplicationArea = All;
                    Caption = 'Sevk Şehri', locked = true;
                }
                field(Uretici; Rec."Order No.")
                {
                    ApplicationArea = All;
                    Caption = 'Üretici', locked = true;
                }
                field(Barkod; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Barkod', locked = true;
                }
                field(UrunAdi; Rec."Item Description")
                {
                    ApplicationArea = All;
                    Caption = 'Ürün Adı', locked = true;
                }
                field(Birim; Rec."Return Reason Code")
                {
                    ApplicationArea = All;
                    Caption = 'Birim', locked = true;
                }
                field(IhaleMiktar; Rec."Valued Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'İhale Miktar', locked = true;
                }
                field(KutuMiktar; Rec."Invoiced Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Kutu Miktar', locked = true;
                }
                field(KutuIciAdet; Rec."Item Ledger Entry Quantity")
                {
                    ApplicationArea = All;
                    Caption = 'Kutu İçi Adet', locked = true;
                }
                field(StokKodu; Rec."Item No.")
                {
                    ApplicationArea = All;
                    Caption = 'Stok Kodu', locked = true;
                }
                field(Aciklama; Rec."Item Charge No.")
                {
                    ApplicationArea = All;
                    Caption = 'Açıklama', locked = true;
                }
                field(IhaleKayitNo; Rec."User ID")
                {
                    ApplicationArea = All;
                    Caption = 'İhale Kayıt No', locked = true;
                }
                field(BirimFiyat; Rec."Cost per Unit")
                {
                    ApplicationArea = All;
                    Caption = 'Birim Fiyat', locked = true;
                }
                field(IhaleBirimFiyat; Rec."Cost per Unit (ACY)")
                {
                    ApplicationArea = All;
                    Caption = 'İhale Birim Fiyat', locked = true;
                }
                field(ToplamTutar; Rec."Purchase Amount (Actual)")
                {
                    ApplicationArea = All;
                    Caption = 'Toplam Tutar', locked = true;
                }
                field(IhaleToplamTutar; Rec."Sales Amount (Actual)")
                {
                    ApplicationArea = All;
                    Caption = 'İhale Toplam Tutar', locked = true;
                }
                field(BolgeSorumlusu; Rec."Job No.")
                {
                    ApplicationArea = All;
                    Caption = 'Bölge Sorumlusu', locked = true;
                }
                field(Miad; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Miad', locked = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetData)
            {
                ApplicationArea = All;
                Caption = 'Verileri Getir', locked = true;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Seçilen filtrelere göre satış faturası satırlarını getirir.', locked = true;

                trigger OnAction()
                begin
                    GetSalesData();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        StartDateFilter := Today;
        EndDateFilter := Today;
    end;

    var
        OrderDocumentTypeFilter: Code[20];
        StartDateFilter: Date;
        EndDateFilter: Date;
        MissingDatesErr: Label 'Lütfen Başlangıç ve Bitiş Tarihi seçiniz.', locked = true;
        DateOrderErr: Label 'Başlangıç Tarihi, Bitiş Tarihinden büyük olamaz.', locked = true;

    local procedure GetSalesData()
    var
        LSalesInvoiceHeader: Record "Sales Invoice Header";
        LSalesInvoiceLine: Record "Sales Invoice Line";
        LBidHeader: Record "Bid Header-INC";
        LBidFinal: Record "Bid Final-Assessment Line-INC";
        LSalesPerson: Record "Salesperson/Purchaser";
        LEntryNo: Integer;
    begin
        if (StartDateFilter = 0D) or (EndDateFilter = 0D) then
            Error(MissingDatesErr);
        if StartDateFilter > EndDateFilter then
            Error(DateOrderErr);

        Rec.Reset();
        Rec.DeleteAll();

        LSalesInvoiceHeader.SetRange(Cancelled, false);
        if OrderDocumentTypeFilter <> '' then
            LSalesInvoiceHeader.SetRange("Order/Document Type-B2F", OrderDocumentTypeFilter);
        LSalesInvoiceHeader.SetRange("Posting Date", StartDateFilter, EndDateFilter);
        if LSalesInvoiceHeader.FindSet() then
            repeat
                LSalesInvoiceLine.SetRange("Document No.", LSalesInvoiceHeader."No.");
                LSalesInvoiceLine.SetRange(Type, LSalesInvoiceLine.Type::Item);
                if LSalesInvoiceLine.FindSet() then
                    repeat
                        LSalesInvoiceLine.CalcFields(GTIN_Inc, "Sell-to Customer Name");
                        Rec.Init();
                        LEntryNo += 1;
                        Rec."Entry No." := LEntryNo;
                        Rec."Source Code" := Format(Date2DMY(LSalesInvoiceHeader."Posting Date", 3)); // Yıl
                        Rec."Reason Code" := Format(Date2DMY(LSalesInvoiceHeader."Posting Date", 2)); // Ay
                        Rec."Posting Date" := LSalesInvoiceHeader."Posting Date"; // Fatura Tarihi
                        Rec."Salespers./Purch. Code" := CopyStr(LSalesInvoiceHeader."External Document No.", 1, 20); // Fatura No
                        Rec.Description := LSalesInvoiceLine."Sell-to Customer Name"; // Ünite Adı
                        Rec."Source Description-B2F" := LSalesInvoiceHeader."Ship-to Name"; // Sevk Yeri
                        Rec."Job Task No." := LSalesInvoiceHeader."Ship-to City"; // Sevk Şehri
                        Rec."Order No." := GetManufacturer(LSalesInvoiceLine."No."); // Üretici
                        Rec."Document No." := LSalesInvoiceLine.GTIN_Inc; // Barkod
                        Rec."Return Reason Code" := LSalesInvoiceLine."Bid Unit of MeasureINC"; // Birim
                        Rec."Invoiced Quantity" := LSalesInvoiceLine.Quantity; // Kutu Miktar
                        Rec."Item No." := LSalesInvoiceLine."No."; // Stok Kodu
                        Rec."Cost per Unit" := LSalesInvoiceLine."Unit Price"; // Birim Fiyat
                        Rec."Purchase Amount (Actual)" := LSalesInvoiceLine.Amount; // Toplam Tutar
                        Rec."External Document No." := CopyStr(GetMiad(LSalesInvoiceLine."No.", LSalesInvoiceHeader."External Document No."), 1, 35); // Miad

                        LBidHeader.Init();
                        if LBidHeader.Get(LSalesInvoiceHeader."Bid No.INC") then begin
                            Rec."Item Charge No." := Format(LBidHeader."Bid Class"); // Açıklama
                            Rec."User ID" := LBidHeader."Bid Registration No."; // İhale Kayıt No
                            LBidFinal.Init();
                            if LBidFinal.Get(LBidHeader."No.", LSalesInvoiceLine."External Line No.INC") then begin
                                Rec."Valued Quantity" := LBidFinal.Quantity; // İhale Miktar
                                Rec."Item Ledger Entry Quantity" := LBidFinal."Quantity per Box"; // Kutu İçi Adet
                                Rec."Cost per Unit (ACY)" := LBidFinal."Price Won"; // İhale Birim Fiyat
                                Rec."Sales Amount (Actual)" := LBidFinal."Total Quote"; // İhale Toplam Tutar
                            end;
                        end;

                        LSalesPerson.Init();
                        if LSalesPerson.Get(LSalesInvoiceHeader."Salesperson Code") then
                            Rec."Job No." := CopyStr(LSalesPerson.Name, 1, 20); // Bölge Sorumlusu

                        Rec.Insert();
                    until LSalesInvoiceLine.Next() = 0;
            until LSalesInvoiceHeader.Next() = 0;

        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    local procedure GetMiad(pItemNo: Code[20]; pExternalDocumentNo: Code[50]) rtnvalue: Text[50]
    var
        LItemLE: Record "Item Ledger Entry";
        LExpirationDate: Text[20];
    begin
        LItemLE.SetRange("Item No.", pItemNo);
        LItemLE.SetRange("External Document No.", pExternalDocumentNo);
        if LItemLE.FindSet() then
            repeat
                if LItemLE."Expiration Date" <> 0D then begin
                    LExpirationDate :=
                        PadStr(Format(Date2DMY(LItemLE."Expiration Date", 2)), 2, '0') + '.' +
                        Format(Date2DMY(LItemLE."Expiration Date", 3));
                    if StrPos(rtnvalue, LExpirationDate) = 0 then
                        if rtnvalue = '' then
                            rtnvalue := LExpirationDate
                        else
                            rtnvalue += ', ' + LExpirationDate;
                end;
            until LItemLE.Next() = 0;
    end;

    local procedure GetManufacturer(pItemNo: Code[20]): Code[20]
    var
        LItem: Record Item;
        LManufacturer: Record Manufacturer;
    begin
        if LItem.Get(pItemNo) then
            if LManufacturer.Get(LItem."Manufacturer Code") then
                exit(CopyStr(LManufacturer.Name, 1, 20));
    end;
}
