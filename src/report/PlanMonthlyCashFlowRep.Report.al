report 70826 "Plan. Monthly CashFlow Rep."
{
    ApplicationArea = All;
    Caption = 'Planned Monthly Cash Flow Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Monthly Cash Flow Report.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;

            column(PostingDate; "Posting Date") { }                                 // Ayın ilk günü
            column(Month; "Order No.") { }                                          // Ay (yy.mm-Ay adı)
            column(MonthIdx; "Document Line No.") { }                               // Ay sırası (1..12)

            // Faaliyet Gelirleri
            column(Devir; "Item Ledger Entry Quantity") { }                         // HAZIR DEĞER / DEVİR (ilk ay: banka TL, sonraki aylar: önceki ay kümülatif)
            column(UsdEur; "Cost Amount (Non-Invtbl.)(ACY)") { }                    // USD EURO KARŞILIĞI (sadece ilk ay)
            column(GrupIciGelir; "Cost Posted to G/L") { }                          // GRUP İÇİ (müşteri)
            column(MusCekMevcut; "Cost Amount (Non-Invtbl.)") { }                   // MÜŞTERİ ÇEKLERİ MEVCUT
            column(MusCekIlave; "Exp. Cost Posted to G/L (ACY)") { }                // MÜŞTERİ ÇEKLERİ İLAVE (manuel gelir, Çek)
            column(Ihracat; "Discount Amount") { }                                  // İHRACAT
            column(MusTahsilat; "Invoiced Quantity") { }                            // MÜŞTERİ TAHSİLAT

            // Ek Nakit Gelirler
            column(StokTutari; "Valued Quantity") { }                               // STOK TUTARI (sadece ilk ay)

            // Ticari Ürün Ödemeleri
            column(BorcCekleri; "Cost Amount (Expected) (ACY)") { }                 // BORÇ ÇEKLERİ
            column(BankaDBS; "Cost Amount (Expected)") { }                          // BANKA DBS
            column(GrupIciOdeme; "Cost Amount (Actual) (ACY)") { }                  // GRUP İÇİ (tedarikçi)
            column(AcikHesaplar; "Cost Amount (Actual)") { }                        // AÇIK HESAPLAR
            column(OzelAlim1; "Cost per Unit") { }                                  // ÖZEL ALIM (rapor ayı)
            column(OzelAlim2; "Cost per Unit (ACY)") { }                            // ÖZEL ALIM (rapor ayı + 1)
            column(OzelAlim3; "Cost Posted to G/L (ACY)") { }                       // ÖZEL ALIM (rapor ayı + 2)
            column(IhaleAlim1; "Purchase Amount (Actual)") { }                      // İHALE ALIM (rapor ayı)
            column(IhaleAlim2; "Purchase Amount (Expected)") { }                    // İHALE ALIM (rapor ayı + 1)
            column(IhaleAlim3; "Expected Cost Posted to G/L") { }                   // İHALE ALIM (rapor ayı + 2)

            // Faaliyet Giderleri / Faaliyet Dışı Giderler
            column(IsletmeGiderleri; "Sales Amount (Actual)") { }                   // İŞLETME GİDERLERİ (Vergi dışı)
            column(VergiOdemesi; "Sales Amount (Expected)") { }                     // VERGİ ÖDEMESİ

            // Satır etiketleri (alım satırlarının ay adları)
            column(OzelAlimLbl1; OzelAlimLbl1) { }
            column(OzelAlimLbl2; OzelAlimLbl2) { }
            column(OzelAlimLbl3; OzelAlimLbl3) { }
            column(IhaleAlimLbl1; IhaleAlimLbl1) { }
            column(IhaleAlimLbl2; IhaleAlimLbl2) { }
            column(IhaleAlimLbl3; IhaleAlimLbl3) { }
            column(IsINC; IsINCCompany) { }                                         // 1 = Şirket INC

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
                    field(ReportDate; ReportDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Report Date';
                        ToolTip = 'Select the report date. The report covers 12 months starting with the month of this date.';
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
            ReportDate := Today;
        end;
    }

    local procedure FillTempVLE()
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cheque: Record "Cheque-B2F";
        LCompany: Record Company;
        CurrDate: Date;
        AmountLCY: Decimal;
        k: Integer;
    begin
        if ReportDate = 0D then
            error('Report Date cannot be empty. Please select a valid report date.');

        // Rapor tarihinden önceki günün kurları
        YesterdayDate := ReportDate - 1;
        EURRate := GetExchangeRate('EUR', YesterdayDate);
        USDRate := GetExchangeRate('USD', YesterdayDate);
        GBPRate := GetExchangeRate('GBP', YesterdayDate);
        GRAMRate := GetExchangeRate('GRAM', YesterdayDate);
        ONSRate := GetExchangeRate('ONS', YesterdayDate);

        // Kurlar hazır olmadan banka TL karşılıkları hesaplanamaz
        CalcBankOpeningBalances();

        // Şirket ayrımı
        IsINCCompany := 0;
        if LCompany.Get(CompanyName) then
            if LCompany.Name = 'INC' then
                IsINCCompany := 1;

        TempVLE.Reset();
        TempVLE.DeleteAll();
        MonthCount := 12;
        StartDate := DMY2Date(1, Date2DMY(ReportDate, 2), Date2DMY(ReportDate, 3)); // Rapor ayının ilk günü

        OzelAlimLbl1 := 'ÖZEL ' + GetMonthNameUpper(Date2DMY(StartDate, 2)) + ' ALIM';
        OzelAlimLbl2 := 'ÖZEL ' + GetMonthNameUpper(Date2DMY(CalcDate('<+1M>', StartDate), 2)) + ' ALIM';
        OzelAlimLbl3 := 'ÖZEL ' + GetMonthNameUpper(Date2DMY(CalcDate('<+2M>', StartDate), 2)) + ' ALIM';
        IhaleAlimLbl1 := 'İHALE ' + GetMonthNameUpper(Date2DMY(StartDate, 2)) + ' ALIM';
        IhaleAlimLbl2 := 'İHALE ' + GetMonthNameUpper(Date2DMY(CalcDate('<+1M>', StartDate), 2)) + ' ALIM';
        IhaleAlimLbl3 := 'İHALE ' + GetMonthNameUpper(Date2DMY(CalcDate('<+2M>', StartDate), 2)) + ' ALIM';

        for k := 1 to MonthCount do begin
            CurrDate := CalcDate(StrSubstNo('<+%1M>', k - 1), StartDate);
            TempVLE.Init();
            TempVLE."Entry No." := k;
            TempVLE."Posting Date" := CurrDate;
            TempVLE."Order No." := GetMonthYearText(CurrDate); // Ay
            TempVLE."Document Line No." := k;                  // Ay sırası
            TempVLE."Item Ledger Entry Quantity" := 0;         // Devir
            TempVLE."Cost Amount (Non-Invtbl.)(ACY)" := 0;     // USD EURO karşılığı
            TempVLE."Cost Posted to G/L" := 0;                 // Grup içi (gelir)
            TempVLE."Cost Amount (Non-Invtbl.)" := 0;          // Müşteri çekleri mevcut
            TempVLE."Exp. Cost Posted to G/L (ACY)" := 0;      // Müşteri çekleri ilave
            TempVLE."Discount Amount" := 0;                    // İhracat
            TempVLE."Invoiced Quantity" := 0;                  // Müşteri tahsilat
            TempVLE."Valued Quantity" := 0;                    // Stok tutarı
            TempVLE."Cost Amount (Expected) (ACY)" := 0;       // Borç çekleri
            TempVLE."Cost Amount (Expected)" := 0;             // Banka DBS
            TempVLE."Cost Amount (Actual) (ACY)" := 0;         // Grup içi (ödeme)
            TempVLE."Cost Amount (Actual)" := 0;               // Açık hesaplar
            TempVLE."Cost per Unit" := 0;                      // Özel alım 1
            TempVLE."Cost per Unit (ACY)" := 0;                // Özel alım 2
            TempVLE."Cost Posted to G/L (ACY)" := 0;           // Özel alım 3
            TempVLE."Purchase Amount (Actual)" := 0;           // İhale alım 1
            TempVLE."Purchase Amount (Expected)" := 0;         // İhale alım 2
            TempVLE."Expected Cost Posted to G/L" := 0;        // İhale alım 3
            TempVLE."Sales Amount (Actual)" := 0;              // İşletme giderleri
            TempVLE."Sales Amount (Expected)" := 0;            // Vergi ödemesi
            TempVLE.Insert();
        end;

        // İlk ay: USD + EUR banka bakiyelerinin TL karşılığı ve stok tutarı
        AddToTempVLE(1, 14, BankBalUSDLCY + BankBalEURLCY);
        AddStockToTempVLE();

        // Tedarikçi açık faturaları
        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange(Open, true);
        if VendLedgEntry.FindSet() then
            repeat
                AmountLCY := GetAmountLCY(VendLedgEntry);

                if (VendLedgEntry."Vendor No." = 'ST00101001') or (VendLedgEntry."Vendor No." = 'ST00007001') then
                    AddToTempVLE(GetEntryNo(VendLedgEntry."Due Date"), 3, AmountLCY) // Grup içi
                else
                    if VendLedgEntry."Payment Method Code" = 'DBS' then
                        AddToTempVLE(GetEntryNo(VendLedgEntry."Due Date"), 2, AmountLCY) // DBS
                    else
                        AddToTempVLE(GetEntryNo(VendLedgEntry."Due Date"), 4, AmountLCY); // Açık hesaplar
            until VendLedgEntry.Next() = 0;

        // Çekler (ödenmemiş)
        Cheque.SetFilter("Transaction Standard Type", '<>%1', Cheque."Transaction Standard Type"::Paid);
        if Cheque.FindSet() then
            repeat
                AddChequeToTempVLE(Cheque);
            until Cheque.Next() = 0;

        // Müşteri açık faturaları (vade rapor tarihi ve sonrası)
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetFilter("Due Date", '>=%1', ReportDate);
        if CustLedgEntry.FindSet() then
            repeat
                AddCustLedgerToTempVLE(CustLedgEntry);
            until CustLedgEntry.Next() = 0;

        AddPurchaseInvoicesToTempVLE();
        AddManualExpensesToTempVLE();
        AddManualRevenuesToTempVLE();
        CalcMonthlyBalances();
    end;

    // Devir: ilk ay bankalardaki TL toplamı, sonraki aylar bir önceki ayın kümülatif tutarı.
    // Kümülatif = Devir + USD/EUR + Faaliyet gelirleri + Stok - Ticari ödemeler - Faaliyet giderleri - Vergi
    // (RDLC'deki KÜMÜLATİF satırı ile aynı formül)
    local procedure CalcMonthlyBalances()
    var
        PrevCum: Decimal;
    begin
        PrevCum := BankBalTL;
        TempVLE.Reset();
        if TempVLE.FindSet() then
            repeat
                TempVLE."Item Ledger Entry Quantity" := PrevCum; // Devir
                PrevCum :=
                    TempVLE."Item Ledger Entry Quantity" +
                    TempVLE."Cost Amount (Non-Invtbl.)(ACY)" +
                    TempVLE."Cost Posted to G/L" + TempVLE."Cost Amount (Non-Invtbl.)" +
                    TempVLE."Exp. Cost Posted to G/L (ACY)" + TempVLE."Discount Amount" +
                    TempVLE."Invoiced Quantity" +
                    TempVLE."Valued Quantity" -
                    TempVLE."Cost Amount (Expected) (ACY)" - TempVLE."Cost Amount (Expected)" -
                    TempVLE."Cost Amount (Actual) (ACY)" - TempVLE."Cost Amount (Actual)" -
                    TempVLE."Cost per Unit" - TempVLE."Cost per Unit (ACY)" - TempVLE."Cost Posted to G/L (ACY)" -
                    TempVLE."Purchase Amount (Actual)" - TempVLE."Purchase Amount (Expected)" -
                    TempVLE."Expected Cost Posted to G/L" -
                    TempVLE."Sales Amount (Actual)" - TempVLE."Sales Amount (Expected)";
                TempVLE.Modify();
            until TempVLE.Next() = 0;
    end;

    // Stok tutarı: Item Ledger Entry'de kalan miktar x madde kartındaki birim maliyet (ilk aya yazılır)
    local procedure AddStockToTempVLE()
    var
        Item: Record Item;
        ItemLedgEntry: Record "Item Ledger Entry";
        StockAmount: Decimal;
    begin
        StockAmount := 0;
        if Item.FindSet() then
            repeat
                ItemLedgEntry.Reset();
                ItemLedgEntry.SetRange("Item No.", Item."No.");
                ItemLedgEntry.SetRange(Open, true);
                ItemLedgEntry.CalcSums("Remaining Quantity");
                StockAmount += ItemLedgEntry."Remaining Quantity" * Item."Unit Cost";
            until Item.Next() = 0;

        AddToTempVLE(1, 12, StockAmount);
    end;

    // Ödenmemiş satınalma faturaları (Posted Purchase Invoices): Vade tarihi > rapor tarihi.
    // Sütun = vade tarihinin ayı, satır = Posting Date'in ayı (rapor ayı, +1, +2).
    // INC: SA-İNCİ-ÖZEL HASTANE / SA-İNCİ-İHALE
    // Diğer: SA-ÖZEL HASTANE / SA-AÇIK İHALE, SA-DMO, SA-DOĞRUDAN TEMİN
    local procedure AddPurchaseInvoicesToTempVLE()
    begin
        if IsINCCompany = 1 then begin
            ProcessPurchaseInvoices('SA-İNCİ-ÖZEL HASTANE', '', '', true);
            ProcessPurchaseInvoices('SA-İNCİ-İHALE', '', '', false);
        end else begin
            ProcessPurchaseInvoices('SA-ÖZEL HASTANE', '', '', true);
            ProcessPurchaseInvoices('SA-AÇIK İHALE', 'SA-DMO', 'SA-DOĞRUDAN TEMİN', false);
        end;
    end;

    local procedure ProcessPurchaseInvoices(pType1: Text; pType2: Text; pType3: Text; pIsOzel: Boolean)
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        RemAmount: Decimal;
        AmountLCY: Decimal;
        PostingIdx: Integer;
        Grp: Integer;
    begin
        if pType2 = '' then
            PurchInvHeader.SetFilter("Order/Document Type-B2F", '%1', pType1)
        else
            PurchInvHeader.SetFilter("Order/Document Type-B2F", '%1|%2|%3', pType1, pType2, pType3);
        PurchInvHeader.SetFilter("Due Date", '>%1', ReportDate);
        PurchInvHeader.SetRange("Posting Date", StartDate, CalcDate('<+3M-1D>', StartDate));
        if PurchInvHeader.FindSet() then
            repeat
                PostingIdx := MonthIndexOf(PurchInvHeader."Posting Date"); // 1..3
                if (PostingIdx >= 1) and (PostingIdx <= 3) then begin
                    PurchInvHeader.CalcFields("Remaining Amount");
                    RemAmount := PurchInvHeader."Remaining Amount";
                    if RemAmount <> 0 then begin
                        if PurchInvHeader."Currency Factor" <> 0 then
                            AmountLCY := ConvertToLCY(PurchInvHeader."Currency Code", RemAmount, RemAmount / PurchInvHeader."Currency Factor")
                        else
                            AmountLCY := ConvertToLCY(PurchInvHeader."Currency Code", RemAmount, RemAmount);

                        if pIsOzel then
                            Grp := 14 + PostingIdx // 15, 16, 17 = Özel alım
                        else
                            Grp := 17 + PostingIdx; // 18, 19, 20 = İhale alım
                        AddToTempVLE(GetEntryNo(PurchInvHeader."Due Date"), Grp, AmountLCY);
                    end;
                end;
            until PurchInvHeader.Next() = 0;
    end;

    // Banka hesaplarındaki (102 ile başlayan) kayıtların rapor tarihinden bir gün önceki bakiyesi
    local procedure CalcBankOpeningBalances()
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankBalTL := 0;
        BankBalEUR := 0;
        BankBalUSD := 0;
        BankBalGBP := 0;
        BankBalGRAM := 0;
        BankBalONS := 0;
        BankBalOtherLCY := 0;

        BankAccLedgEntry.SetFilter("Bank Account No.", '102*');
        BankAccLedgEntry.SetFilter("Posting Date", '..%1', YesterdayDate);
        if BankAccLedgEntry.FindSet() then
            repeat
                case BankAccLedgEntry."Currency Code" of
                    '':
                        BankBalTL += BankAccLedgEntry.Amount;
                    'EUR':
                        BankBalEUR += BankAccLedgEntry.Amount;
                    'USD':
                        BankBalUSD += BankAccLedgEntry.Amount;
                    'GBP':
                        BankBalGBP += BankAccLedgEntry.Amount;
                    'GRAM':
                        BankBalGRAM += BankAccLedgEntry.Amount;
                    'ONS':
                        BankBalONS += BankAccLedgEntry.Amount;
                    else
                        BankBalOtherLCY += BankAccLedgEntry."Amount (LCY)";
                end;
            until BankAccLedgEntry.Next() = 0;

        BankBalEURLCY := BankBalEUR * GetRate('EUR');
        BankBalUSDLCY := BankBalUSD * GetRate('USD');
    end;

    // Döviz kodunu TL kuruna çevirir, boşsa TL (1).
    // ONS (ons altın) USD cinsinden fiyatlandığı için TL kuru = ONS fiyatı x USD kuru
    local procedure GetRate(pCurrencyCode: Code[10]): Decimal
    begin
        case pCurrencyCode of
            '':
                exit(1);
            'EUR':
                exit(EURRate);
            'USD':
                exit(USDRate);
            'GBP':
                exit(GBPRate);
            'GRAM':
                exit(GRAMRate);
            'ONS':
                exit(ONSRate * USDRate);
        end;

        exit(0);
    end;

    // Boş döviz = TL, bilinen 5 kur için tutar x kur, diğerleri için pFallbackLCY (kaydın kendi LCY tutarı)
    local procedure ConvertToLCY(pCurrencyCode: Code[10]; pAmount: Decimal; pFallbackLCY: Decimal): Decimal
    begin
        if pCurrencyCode = '' then
            exit(pAmount);

        if pCurrencyCode in ['EUR', 'USD', 'GBP', 'GRAM', 'ONS'] then
            exit(pAmount * GetRate(pCurrencyCode));

        exit(pFallbackLCY);
    end;

    local procedure GetAmountLCY(var pVLE: Record "Vendor Ledger Entry"): Decimal
    begin
        pVLE.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        exit(ConvertToLCY(pVLE."Currency Code", -pVLE."Remaining Amount", -pVLE."Remaining Amt. (LCY)"));
    end;

    local procedure AddCustLedgerToTempVLE(var pCLE: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
        AmountLCY: Decimal;
        EntryNo: Integer;
    begin
        if not Customer.Get(pCLE."Customer No.") then
            exit;

        pCLE.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        AmountLCY := ConvertToLCY(pCLE."Currency Code", pCLE."Remaining Amount", pCLE."Remaining Amt. (LCY)");
        EntryNo := GetEntryNo(pCLE."Due Date");

        case Customer."Customer Group_Inc" of
            Customer."Customer Group_Inc"::"Group Company":
                AddToTempVLE(EntryNo, 5, AmountLCY); // Grup içi
            Customer."Customer Group_Inc"::Export:
                AddToTempVLE(EntryNo, 6, AmountLCY); // İhracat
            Customer."Customer Group_Inc"::"Pharmaceutical Distributor":
                AddToTempVLE(EntryNo, 7, AmountLCY); // Müşteri tahsilat (Ecza depoları)
            Customer."Customer Group_Inc"::Pharmacy,
            Customer."Customer Group_Inc"::"Private Hospital":
                if IsINCCompany = 0 then
                AddToTempVLE(EntryNo, 7, AmountLCY); // Müşteri tahsilat (Eczacı, Özel Hastane): INC dışı şirketlerde
        end;
    end;

    local procedure AddChequeToTempVLE(var pCheque: Record "Cheque-B2F")
    var
        AmountLCY: Decimal;
    begin
        AmountLCY := ConvertToLCY(pCheque."Currency Code", pCheque.Amount, pCheque.Amount);

        if pCheque."Our Cheque" then
            AddToTempVLE(GetEntryNo(pCheque."Due Date"), 8, AmountLCY) // Borç çekleri
        else
            AddToTempVLE(GetEntryNo(pCheque."Due Date"), 9, AmountLCY); // Müşteri çekleri mevcut
    end;

    // Tarihin ay sırası: rapor ayı = 1, sonraki aylar 2, 3, ...
    local procedure MonthIndexOf(pDate: Date): Integer
    begin
        exit((Date2DMY(pDate, 3) - Date2DMY(StartDate, 3)) * 12 + Date2DMY(pDate, 2) - Date2DMY(StartDate, 2) + 1);
    end;

    // Rapor tarihinden küçük vadeliler ilk aya (rapor ayı), diğerleri kendi ayına yazılır
    local procedure GetEntryNo(pDueDate: Date): Integer
    begin
        if pDueDate < ReportDate then
            exit(1);

        exit(MonthIndexOf(pDueDate));
    end;

    // pGroup:
    // 2 = DBS, 3 = Grup içi (ödeme), 4 = Açık hesaplar, 5 = Grup içi (gelir), 6 = İhracat,
    // 7 = Müşteri tahsilat, 8 = Borç çekleri, 9 = Müşteri çekleri mevcut, 10 = Müşteri çekleri ilave,
    // 11 = İşletme giderleri, 13 = Vergi ödemesi, 12 = Stok, 14 = USD/EUR karşılığı,
    // 15..17 = Özel alım (rapor ayı, +1, +2), 18..20 = İhale alım (rapor ayı, +1, +2)
    local procedure AddToTempVLE(pEntryNo: Integer; pGroup: Integer; pAmount: Decimal)
    begin
        if (pEntryNo < 1) or (pEntryNo > MonthCount) then
            exit; // 12 aylık aralığın dışında

        if not TempVLE.Get(pEntryNo) then
            exit;

        case pGroup of
            2:
                TempVLE."Cost Amount (Expected)" += pAmount;
            3:
                TempVLE."Cost Amount (Actual) (ACY)" += pAmount;
            4:
                TempVLE."Cost Amount (Actual)" += pAmount;
            5:
                TempVLE."Cost Posted to G/L" += pAmount;
            6:
                TempVLE."Discount Amount" += pAmount;
            7:
                TempVLE."Invoiced Quantity" += pAmount;
            8:
                TempVLE."Cost Amount (Expected) (ACY)" += pAmount;
            9:
                TempVLE."Cost Amount (Non-Invtbl.)" += pAmount;
            10:
                TempVLE."Exp. Cost Posted to G/L (ACY)" += pAmount;
            11:
                TempVLE."Sales Amount (Actual)" += pAmount;
            12:
                TempVLE."Valued Quantity" += pAmount;
            13:
                TempVLE."Sales Amount (Expected)" += pAmount;
            14:
                TempVLE."Cost Amount (Non-Invtbl.)(ACY)" += pAmount;
            15:
                TempVLE."Cost per Unit" += pAmount;
            16:
                TempVLE."Cost per Unit (ACY)" += pAmount;
            17:
                TempVLE."Cost Posted to G/L (ACY)" += pAmount;
            18:
                TempVLE."Purchase Amount (Actual)" += pAmount;
            19:
                TempVLE."Purchase Amount (Expected)" += pAmount;
            20:
                TempVLE."Expected Cost Posted to G/L" += pAmount;
        end;
        TempVLE.Modify();
    end;

    local procedure GetExchangeRate(pCurrencyCode: Code[10]; pDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", pCurrencyCode);
        CurrExchRate.SetFilter("Starting Date", '..%1', pDate);
        if CurrExchRate.FindLast() then begin
            // Kur birimi 1 değilse (örn. 100 birim) birim başına kura çevirir
            if CurrExchRate."Exchange Rate Amount" <> 0 then
                exit(CurrExchRate."Relational Exch. Rate Amount" / CurrExchRate."Exchange Rate Amount");
            exit(CurrExchRate."Relational Exch. Rate Amount");
        end;

        exit(0);
    end;

    local procedure GetMonthYearText(pDate: Date): Text[20]
    var
        LMonth: Integer;
        LYear: Text[2];
    begin
        LMonth := Date2DMY(pDate, 2);
        LYear := Format(Date2DMY(pDate, 3) MOD 100);

        case LMonth of
            1:
                exit(LYear + '.01-Ocak');
            2:
                exit(LYear + '.02-Şubat');
            3:
                exit(LYear + '.03-Mart');
            4:
                exit(LYear + '.04-Nisan');
            5:
                exit(LYear + '.05-Mayıs');
            6:
                exit(LYear + '.06-Haziran');
            7:
                exit(LYear + '.07-Temmuz');
            8:
                exit(LYear + '.08-Ağustos');
            9:
                exit(LYear + '.09-Eylül');
            10:
                exit(LYear + '.10-Ekim');
            11:
                exit(LYear + '.11-Kasım');
            12:
                exit(LYear + '.12-Aralık');
        end;

        exit('');
    end;

    // Satır etiketleri için büyük harfli Türkçe ay adı (UpperCase Türkçe i/İ harflerini doğru çevirmediği için sabit yazıldı)
    local procedure GetMonthNameUpper(pMonth: Integer): Text[20]
    begin
        case pMonth of
            1:
                exit('OCAK');
            2:
                exit('ŞUBAT');
            3:
                exit('MART');
            4:
                exit('NİSAN');
            5:
                exit('MAYIS');
            6:
                exit('HAZİRAN');
            7:
                exit('TEMMUZ');
            8:
                exit('AĞUSTOS');
            9:
                exit('EYLÜL');
            10:
                exit('EKİM');
            11:
                exit('KASIM');
            12:
                exit('ARALIK');
        end;

        exit('');
    end;

    // Manuel giderler: Vergi => VERGİ ÖDEMESİ, diğerleri (Vergi olmayan) => İŞLETME GİDERLERİ
    local procedure AddManualExpensesToTempVLE()
    var
        ManualExpense: Record "Cash Flow Manual Expense";
    begin
        ManualExpense.SetFilter("Ending Date", '>=%1', ReportDate);
        if ManualExpense.FindSet() then
            repeat
                if ManualExpense."Expense Type_Inc" = ManualExpense."Expense Type_Inc"::Tax then
                    AddToTempVLE(GetEntryNo(ManualExpense."Ending Date"), 13, ManualExpense.Amount)
                else
                    AddToTempVLE(GetEntryNo(ManualExpense."Ending Date"), 11, ManualExpense.Amount);
            until ManualExpense.Next() = 0;
    end;

    // Manuel gelirler:
    // Çek => MÜŞTERİ ÇEKLERİ İLAVE
    // Kamu / Özel => MÜŞTERİ TAHSİLAT (sadece INC dışı şirketlerde)
    local procedure AddManualRevenuesToTempVLE()
    var
        ManualRevenue: Record "Cash Flow Manual Revenue";
    begin
        ManualRevenue.SetFilter("Ending Date", '>=%1', ReportDate);
        if ManualRevenue.FindSet() then
            repeat
                case ManualRevenue."Revenue Type_Inc" of
                    ManualRevenue."Revenue Type_Inc"::Cheque:
                        AddToTempVLE(GetEntryNo(ManualRevenue."Ending Date"), 10, ManualRevenue.Amount);
                    ManualRevenue."Revenue Type_Inc"::Public,
                    ManualRevenue."Revenue Type_Inc"::Private:
                        if IsINCCompany = 0 then
                            AddToTempVLE(GetEntryNo(ManualRevenue."Ending Date"), 7, ManualRevenue.Amount);
                end;
            until ManualRevenue.Next() = 0;
    end;

    var
        ReportDate: Date;
        YesterdayDate: Date;
        StartDate: Date;
        MonthCount: Integer;
        IsINCCompany: Integer;
        OzelAlimLbl1: Text[50];
        OzelAlimLbl2: Text[50];
        OzelAlimLbl3: Text[50];
        IhaleAlimLbl1: Text[50];
        IhaleAlimLbl2: Text[50];
        IhaleAlimLbl3: Text[50];
        // Kurlar (rapor tarihi - 1)
        EURRate: Decimal;
        USDRate: Decimal;
        GBPRate: Decimal;
        GRAMRate: Decimal;
        ONSRate: Decimal;
        // Banka bakiyeleri
        BankBalTL: Decimal;
        BankBalEUR: Decimal;
        BankBalUSD: Decimal;
        BankBalGBP: Decimal;
        BankBalGRAM: Decimal;
        BankBalONS: Decimal;
        BankBalOtherLCY: Decimal;
        BankBalEURLCY: Decimal;
        BankBalUSDLCY: Decimal;
}
