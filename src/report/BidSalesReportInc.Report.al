report 70816 "Bid Sales Report_Inc"
{
    ApplicationArea = All;
    Caption = 'Bid Sales Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Bid Sales Report.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;

            column(GirisNo; "Entry No.")
            {
            }
            column(Ay; "Reason Code")
            { }
            Column(Yil; "Source Code")
            {
            }
            column(Fatura_Tarihi; "Posting Date")
            {
            }
            column(Fatura_No; "Salespers./Purch. Code")
            {
            }
            column(Unite_Adı; "Description")
            {
            }
            column(Sevk_Yeri; "Source Description-B2F")
            {
            }
            column(Sevk_Sehri; "Job Task No.")
            {
            }
            column(Üretici; "Order No.")
            {
            }
            column(Barkod; "Document No.")
            {
            }
            column(Ürün_Adı; "Item Description")
            {
            }
            column(Birim; "Return Reason Code")
            {
            }
            column(İhale_Miktar; "Valued Quantity")
            {
            }
            column(Kutu_Miktar; "Invoiced Quantity")
            {
            }
            column(Kutu_İçi_Adet; "Item Ledger Entry Quantity")
            {
            }
            column(Stok_Kodu; "Item No.")
            {
            }
            column(Açıklama; "Item Charge No.")
            {
            }
            column(İhale_Kayıt_No; "User ID")
            {
            }
            column(Birim_Fiyat; "Cost per Unit")
            {
            }
            column(İhale_Birim_Fiyat; "Cost per Unit (ACY)")
            {
            }
            column(Toplam_Tutar; "Purchase Amount (Actual)")
            {
            }
            column(İhale_Toplam_Tutar; "Sales Amount (Actual)")
            {
            }
            column(Bölge_Sorumlusu; "Job No.")
            {
            }
            column(Miad; "External Document No.")
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
                    field("Order/Document Type"; "Order/Document Type")
                    {
                        ApplicationArea = All;
                        Caption = 'Order/Document Type';
                        ToolTip = 'Select the order/document type to filter the report.';
                        TableRelation = "Order/Document Type-B2F" where(Area = const(Sales),
                                                        "Global Dimension 1 Code" = const('01.02.03'));
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
        begin
            StartDate := Today;
            EndDate := Today;
        end;
    }

    local procedure FillTempVLE()
    var
        LSalesInvoiceHeader: Record "Sales Invoice Header";
        LSalesInvoiceLine: Record "Sales Invoice Line";
        LBidHeader: Record "Bid Header-INC";
        LBidFinal: Record "Bid Final-Assessment Line-INC";
        LSalesPerson: Record "Salesperson/Purchaser";
    begin
        Clear(TempVLE);
        LSalesInvoiceHeader.SetRange("Cancelled", false);
        if StartDate = 0D then
            error('Start Date cannot be empty. Please select a valid start date.');
        if EndDate = 0D then
            error('End Date cannot be empty. Please select a valid end date.');

        if "Order/Document Type" = '' then
            error('Order/Document Type cannot be empty. Please select a valid order/document type.');

        LSalesInvoiceHeader.SetRange("Posting Date", StartDate, EndDate);
        LSalesInvoiceHeader.SetRange("Order/Document Type-B2F", "Order/Document Type");
        if LSalesInvoiceHeader.FindSet() then
            repeat
                LSalesInvoiceLine.SetRange("Document No.", LSalesInvoiceHeader."No.");
                LSalesInvoiceLine.SetRange(Type, LSalesInvoiceLine.Type::Item);
                if LSalesInvoiceLine.FindSet() then
                    repeat
                        TempVLE.Init();
                        i += 1;
                        TempVLE."Entry No." := i;
                        TempVLE."Source Code" := format(Date2DMY(LSalesInvoiceHeader."Posting Date", 3)); //Yıl
                        TempVLE."Reason Code" := format(Date2DMY(LSalesInvoiceHeader."Posting Date", 2)); //Ay
                        TempVLE."Posting Date" := LSalesInvoiceHeader."Posting Date"; //Fatura Tarihi
                        TempVLE.CalcFields("Item Description");
                        TempVLE."Salespers./Purch. Code" := copyStr(LSalesInvoiceHeader."External Document No.", 1, 20); // Fatura No
                        LSalesInvoiceLine.CalcFields(GTIN_Inc, "Sell-to Customer Name");
                        TempVLE.Description := LSalesInvoiceLine."Sell-to Customer Name"; //Ünite Adı
                        TempVLE."Source Description-B2F" := LSalesInvoiceHeader."Ship-to Name"; //Sevk Yeri Adı
                        TempVLE."Job Task No." := LSalesInvoiceHeader."Ship-to City"; //Sevk Yeri Şehri
                        TempVLE."Order No." := GetManufacturer(LSalesInvoiceLine."No."); // Üretici
                        TempVLE."Document No." := LSalesInvoiceLine.GTIN_Inc; // Barkod
                        //Ürün Adı
                        TempVLE."Return Reason Code" := LSalesInvoiceLine."Bid Unit of MeasureINC";
                        TempVLE."Invoiced Quantity" := LSalesInvoiceLine."Quantity"; // Kutu Miktar
                        TempVLE."Item No." := LSalesInvoiceLine."No."; // Stok Kodu
                        TempVLE."Cost per Unit" := LSalesInvoiceLine."Unit Price"; // Birim Fiyat
                        TempVLE."Purchase Amount (Actual)" := LSalesInvoiceLine."Amount"; // Toplam Tutar
                        TempVLE."External Document No." := CopyStr(GetMiad(LSalesInvoiceLine."No.", LSalesInvoiceHeader."External Document No."), 1, 35); // Miad
                        LBidHeader.Init();
                        if LBidHeader.Get(LSalesInvoiceHeader."Bid No.INC") then begin
                            TempVLE."Item Charge No." := format(LBidHeader."Bid Class"); // Açıklama
                            TempVLE."User ID" := LBidHeader."Bid Registration No."; //İhale Kayıt No
                            LBidFinal.Init();
                            if LBidFinal.Get(LBidHeader."No.", LSalesInvoiceLine."External Line No.INC") then begin
                                TempVLE."Valued Quantity" := LBidFinal.Quantity; // İhale Miktarı
                                TempVLE."Item Ledger Entry Quantity" := LBidFinal."Quantity per Box"; //Kutu İçi Adet
                                TempVLE."Cost per Unit (ACY)" := LBidFinal."Price Won";  // İhale Birim Fiyat
                                TempVLE."Sales Amount (Actual)" := LBidFinal."Total Quote"; // İhale Toplam Tutar
                            end;
                        end;
                        LSalesPerson.Init();
                        if LSalesPerson.Get(LSalesInvoiceHeader."Salesperson Code") then
                            TempVLE."Job No." := CopyStr(LSalesPerson."Name", 1, 20);



                        TempVLE.Insert();
                    until LSalesInvoiceLine.Next() = 0;
            until LSalesInvoiceHeader.Next() = 0;
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

                    // Daha önce eklenmemişse ekle
                    if StrPos(rtnvalue, LExpirationDate) = 0 then begin
                        if rtnvalue = '' then
                            rtnvalue := LExpirationDate
                        else
                            rtnvalue += ', ' + LExpirationDate;
                    end;
                end;
            until LItemLE.Next() = 0;
    end;

    local procedure GetManufacturer(pItemNo: Code[20]) rtnvalue: code[20]
    var
        LItem: record Item;
        LManufacturer: record Manufacturer;
        LCustomer: record Customer;
    begin
        Clear(LItem);
        if LItem.Get(pItemNo) then;

        if LManufacturer.Get(LItem."Manufacturer Code") then
            exit(LManufacturer."Name");
    end;


    var
        i: Integer;
        StartDate: Date;
        EndDate: Date;
        "Order/Document Type": Code[20];
}