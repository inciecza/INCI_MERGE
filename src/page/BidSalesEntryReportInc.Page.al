page 70804 "Bid Sales Entry Report_Inc"
{
    ApplicationArea = All;
    Caption = 'Bid Sales Entry Report';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "Bid Sales Entry Buffer_Inc";
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
            }

            repeater(General)
            {
                Editable = false;
                field("Order Year"; Rec."Order Year")
                {
                    ApplicationArea = All;
                    Caption = 'Sipariş Yıl', locked = true;
                }
                field("Order Month"; Rec."Order Month")
                {
                    ApplicationArea = All;
                    Caption = 'Sipariş Ay', locked = true;
                }
                field("Order Status"; Rec."Order Status")
                {
                    ApplicationArea = All;
                    Caption = 'Sipariş Durumu', locked = true;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = All;
                    Caption = 'Fiş Tarihi', locked = true;
                }
                field("Sell-to Customer Name"; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'Chs Ünvanı', locked = true;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'Sevk Firma', locked = true;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = All;
                    Caption = 'Ambar', locked = true;
                }
                field("Ship-to City"; Rec."Ship-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Sevk Şehir', locked = true;
                }
                field("Manufacturer Name"; Rec."Manufacturer Name")
                {
                    ApplicationArea = All;
                    Caption = 'Üretici', locked = true;
                }
                field("Shrink Pack Qty"; Rec."Shrink Pack Qty")
                {
                    ApplicationArea = All;
                    Caption = 'Ambalaj İçi Miktarı', locked = true;
                }
                field("Description 1"; Rec."Description 1")
                {
                    ApplicationArea = All;
                    Caption = 'Açıklama 1', locked = true;
                }
                field(GTIN; Rec.GTIN)
                {
                    ApplicationArea = All;
                    Caption = 'Barkod', locked = true;
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                    Caption = 'Stok Adı', locked = true;
                }
                field("Order Total Qty"; Rec."Order Total Qty")
                {
                    ApplicationArea = All;
                    Caption = 'Sipariş Toplamı', locked = true;
                }
                field("Shipped Qty"; Rec."Shipped Qty")
                {
                    ApplicationArea = All;
                    Caption = 'Sevk Edilen', locked = true;
                }
                field("Outstanding Qty"; Rec."Outstanding Qty")
                {
                    ApplicationArea = All;
                    Caption = 'Bekleyen', locked = true;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    Caption = 'Birim', locked = true;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    Caption = 'Açıklama 2', locked = true;
                }
                field("Bid Registration No."; Rec."Bid Registration No.")
                {
                    ApplicationArea = All;
                    Caption = 'İhale Kayıt No', locked = true;
                }
                field("Delivery Date"; Rec."Delivery Date")
                {
                    ApplicationArea = All;
                    Caption = 'Teslim Tarihi', locked = true;
                }
                field("Order Amount"; Rec."Order Amount")
                {
                    ApplicationArea = All;
                    Caption = 'Sipariş Tutarı', locked = true;
                }
                field("Contract Ending Date"; Rec."Contract Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Sözleşme Bitiş Tarihi', locked = true;
                }
                field("Bid Date"; Rec."Bid Date")
                {
                    ApplicationArea = All;
                    Caption = 'İhale Tarihi', locked = true;
                }
                field("Payment Terms Code"; Rec."Payment Terms Code")
                {
                    ApplicationArea = All;
                    Caption = 'Vade', locked = true;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Belge No', locked = true;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Caption = 'Fiyat', locked = true;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                    Caption = 'Maliyet', locked = true;
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
                ToolTip = 'Seçilen tarih aralığındaki Satış Siparişi ve Satış Faturası satırlarını getirir.', locked = true;

                trigger OnAction()
                begin
                    GetSalesData();
                end;
            }
        }
    }

    var
        StartDateFilter: Date;
        EndDateFilter: Date;
        MissingDatesErr: Label 'Lütfen Başlangıç ve Bitiş Tarihi seçiniz.', locked = true;
        DateOrderErr: Label 'Başlangıç Tarihi, Bitiş Tarihinden büyük olamaz.', locked = true;
        StatusPendingTxt: Label 'Bekleyen', locked = true;
        StatusInvoicedTxt: Label 'Kapanan', locked = true;

    local procedure GetSalesData()
    var
        LSalesLine: Record "Sales Line";
        LSalesHeader: Record "Sales Header";
        LSalesInvLine: Record "Sales Invoice Line";
        LSalesInvHeader: Record "Sales Invoice Header";
        LItem: Record Item;
        LBidHeader: Record "Bid Header-INC";
        LManufacturer: Record Manufacturer;
        LBidFinal: record "Bid Final-Assessment Line-INC";
        LEntryNo: Integer;
    begin
        if (StartDateFilter = 0D) or (EndDateFilter = 0D) then
            Error(MissingDatesErr);

        if StartDateFilter > EndDateFilter then
            Error(DateOrderErr);

        Rec.Reset();
        Rec.DeleteAll();
        LEntryNo := 0;

        // ---------------------------------------------------------------
        // 1) SATIŞ SİPARİŞLERİ (açık Sales Order satırları)
        // ---------------------------------------------------------------
        LSalesHeader.SetRange("Document Type", LSalesLine."Document Type"::Order);
        LSalesHeader.SetRange("Posting Date", StartDateFilter, EndDateFilter);
        LSalesHeader.Setfilter("Order/Document Type-B2F", '<>ST-ÖZEL HASTANE');
        if LSalesHeader.FindSet() then
            repeat
                Clear(LSalesLine);
                LSalesLine.SetRange("Document Type", LSalesLine."Document Type"::Order);
                LSalesLine.SetRange("Document No.", LSalesHeader."No.");
                if LSalesLine.FindSet() then
                    repeat
                        LEntryNo += 1;
                        Rec.Init();
                        Rec."Entry No." := LEntryNo;
                        Rec."Source Type" := Rec."Source Type"::Order;
                        Rec."Source Document No." := LSalesLine."Document No.";
                        Rec."Order Year" := Date2DMY(LSalesHeader."Posting Date", 3);
                        Rec."Order Month" := Date2DMY(LSalesHeader."Posting Date", 2);
                        Rec."Order Status" := StatusPendingTxt;
                        Rec."Document Date" := LSalesHeader."Posting Date";
                        Rec."Sell-to Customer Name" := LSalesHeader."Sell-to Customer Name";
                        Rec."Ship-to Name" := LSalesHeader."Ship-to Name";
                        Rec."Location Code" := LSalesLine."Location Code";
                        Rec."Ship-to City" := LSalesHeader."Ship-to City";
                        Rec."Shrink Pack Qty" := LSalesLine."Shrink Pack Qty-INC";
                        LItem.Init();
                        if LItem.Get(LSalesLine."No.") then
                            if LManufacturer.Get(LItem."Manufacturer Code") then
                                Rec."Manufacturer Name" := LManufacturer.Name;
                        if LSalesLine.GTININC <> '' then
                            Rec.GTIN := LSalesLine.GTININC
                        else
                            Rec.GTIN := LItem.GTIN;
                        Rec."Unit of Measure Code" := LSalesLine."Bid Unit of MeasureINC";
                        LBidHeader.Init();
                        if LBidHeader.Get(LSalesLine."Bid No.INC") then begin
                            Rec."Bid Registration No." := LBidHeader."Bid Registration No.";
                            Rec."Delivery Date" := LBidHeader."1. Delivery Date";
                            Rec."Contract Ending Date" := LBidHeader."Contract Ending Date";
                            Rec."Bid Date" := LBidHeader."Bid Date-Hour";
                            Rec."Payment Terms Code" := LBidHeader."Payment Terms Code";
                            if LBidHeader."Shipping Advice" = LBidHeader."Shipping Advice"::Partial then
                                Rec."Description 2" := 'Peyderpey Teslimat'
                            else
                                Rec."Description 2" := 'Tam Teslimat';
                            LBidFinal.Init();
                            LBidFinal.SetRange("Bid No.", LSalesLine."Bid No.INC");
                            LBidFinal.SetRange("External Line No.", LSalesLine."External Line No.INC");
                            if LBidFinal.FindFirst() then
                                Rec."Direct Unit Cost" := LBidFinal."Direct Unit Cost";
                        end;

                        Rec."Description 1" := LSalesHeader."Your Reference";
                        Rec."Item Description" := LSalesLine.Description;
                        Rec."Order Total Qty" := LSalesLine."Outstanding Quantity";
                        Rec."Shipped Qty" := 0;
                        Rec."Outstanding Qty" := LSalesLine."Outstanding Quantity";
                        Rec."Order Amount" := LSalesLine.Amount;
                        Rec."Unit Price" := LSalesLine."Unit Price";
                        Rec."Document No." := LSalesHeader."Your Reference";

                        Rec.Insert();

                    until LSalesLine.Next() = 0;
            until LSalesHeader.Next() = 0;

        // ---------------------------------------------------------------
        // 2) SATIŞ FATURALARI (Posted Sales Invoice satırları)
        // ---------------------------------------------------------------
        LSalesInvHeader.SetRange("Posting Date", StartDateFilter, EndDateFilter);
        LSalesInvHeader.SetRange("Order/Document Type-B2F", '<>ST-ÖZEL HASTANE');
        if LSalesInvHeader.FindSet() then
            repeat
                Clear(LSalesInvLine);
                LSalesInvLine.SetRange("Document No.", LSalesInvHeader."No.");
                LSalesInvLine.SetFilter(Type, '<>%1', LSalesInvLine.Type::" ");
                if LSalesInvLine.FindSet() then
                    repeat
                        LEntryNo += 1;
                        Rec.Init();
                        Rec."Entry No." := LEntryNo;
                        Rec."Source Type" := Rec."Source Type"::Invoice;
                        Rec."Source Document No." := LSalesInvLine."Document No.";
                        Rec."Order Year" := Date2DMY(LSalesInvHeader."Posting Date", 3);
                        Rec."Order Month" := Date2DMY(LSalesInvHeader."Posting Date", 2);
                        Rec."Order Status" := StatusInvoicedTxt;
                        Rec."Document Date" := LSalesInvHeader."Posting Date";
                        Rec."Sell-to Customer Name" := LSalesInvHeader."Sell-to Customer Name";
                        Rec."Ship-to Name" := LSalesInvHeader."Ship-to Name";
                        Rec."Location Code" := LSalesInvLine."Location Code";
                        Rec."Ship-to City" := LSalesInvHeader."Ship-to City";
                        LItem.Init();
                        if LItem.Get(LSalesInvLine."No.") then
                            if LManufacturer.Get(LItem."Manufacturer Code") then
                                Rec."Manufacturer Name" := LManufacturer.Name;
                        Rec.GTIN := LItem.GTIN;
                        Rec."Shrink Pack Qty" := LItem."Shrink Pack Quantity_Inc";
                        Rec."Unit of Measure Code" := LSalesInvLine."Bid Unit of MeasureINC";
                        Rec."Description 1" := LSalesInvHeader."Your Reference";
                        Rec."Item Description" := LSalesInvLine.Description;
                        Rec."Order Total Qty" := LSalesInvLine.Quantity;
                        Rec."Shipped Qty" := LSalesInvLine.Quantity;
                        Rec."Outstanding Qty" := 0;
                        Rec."Order Amount" := LSalesInvLine.Amount;
                        Rec."Unit Price" := LSalesInvLine."Unit Price";
                        Rec."Document No." := LSalesInvHeader."Your Reference";

                        Rec.Insert();

                    until LSalesInvLine.Next() = 0;
            until LSalesInvHeader.Next() = 0;

        CurrPage.Update(false);
    end;
}
