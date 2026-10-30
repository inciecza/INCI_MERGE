report 70822 "Plan. Daily CashFlow Rep._Inc"
{
    ApplicationArea = All;
    Caption = 'Planned Daily Cash Flow Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Daily Cash Flow Report.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;

            column(Type; "Document No.") { }                                        // Tür (1 = Vadesi geçmiş, 2 = Rapor tarihi ve sonrası)
            column(PostingDate; "Posting Date") { }                                 // Tarih
            column(Week; "Location Code") { }                                       // Hafta
            column(Month; "Order No.") { }                                          // Ay
            column(DayNo; "Document Line No.") { }                                  // Haftanın günü (1 = Pazartesi ... 7 = Pazar)
            column(WeeklyDevir; "Sales Amount (Actual)") { }                        // Haftalık: günün DEVİR tutarı (sadece haftalık modda dolu)
            column(WeeklyToplam; "Sales Amount (Expected)") { }                     // Haftalık: günün TOPLAM tutarı (sadece haftalık modda dolu)
            column(ReportMode; ReportModeNo) { }                                    // 0 = Günlük, 1 = Haftalık

            column(AcikHesapCariOdeme; "Cost Amount (Actual)") { }                  // Açık Hesap Cari ödeme
            column(GrupIciOdeme; "Cost Amount (Actual) (ACY)") { }                  // Grup İçi
            column(VadesiGelecekDBS; "Cost Amount (Expected)") { }                  // Vadesi Gelecek DBS Bakiyesi
            column(FirmaCekleri; "Cost Amount (Expected) (ACY)") { }                // Firma Çekleri
            column(MusteriCekleri; "Cost Amount (Non-Invtbl.)") { }                 // Müşteri Çekleri
            column(SiparisOdemeleri; "Cost Amount (Non-Invtbl.)(ACY)") { }          // Sipariş Ödemeleri
            column(VergiSGKOdemeleri; "Sales Amount (Actual)") { }                  // Vergi + SGK Ödemeleri
            column(MaasKiraOdemeleri; "Sales Amount (Expected)") { }                // Maaş + Kira Ödemeleri
            column(DMOAcikHesap; "Valued Quantity") { }                             // DMO Açık Hesap
            column(Ihale; "Item Ledger Entry Quantity") { }                         // İhale
            column(EczaDepolari; "Invoiced Quantity") { }                           // Ecza Depoları
            column(Eczaci; "Cost per Unit") { }                                     // Eczacı
            column(Ihracat; "Discount Amount") { }                                  // İhracat
            column(GrupIciTahsilat; "Cost Posted to G/L") { }                       // Grup İçi (müşteri)
            column(OzelHastaneKisaVade; "Cost Posted to G/L (ACY)") { }             // Özel Hastane KISA VADE
            column(OzelHastaneUzunVade; "Cost per Unit (ACY)") { }                  // Özel Hastane UZUN VADE
            column(OzelHastaneKeytruda; "Purchase Amount (Actual)") { }             // Özel Hastane KEYTRUDA
            column(ManuelGelirKamu; "Purchase Amount (Expected)") { }               // Kamu
            column(ManuelGelirOzel; "Expected Cost Posted to G/L") { }              // Özel
            column(ManuelGelirDiger; "Exp. Cost Posted to G/L (ACY)") { }           // Çek, DMO, Diğer

            // Kurlar (rapor tarihi - 1)
            column(EURRate; EURRate) { }
            column(USDRate; USDRate) { }
            column(GBPRate; GBPRate) { }
            column(GRAMRate; GRAMRate) { }
            column(ONSRate; ONSRate) { }

            // Banka bakiyeleri (döviz cinsinden)
            column(BankBalTL; BankBalTL) { }
            column(BankBalEUR; BankBalEUR) { }
            column(BankBalUSD; BankBalUSD) { }
            column(BankBalGBP; BankBalGBP) { }
            column(BankBalGRAM; BankBalGRAM) { }
            column(BankBalONS; BankBalONS) { }

            // Banka bakiyeleri (TL karşılığı)
            column(BankBalEURLCY; BankBalEURLCY) { }
            column(BankBalUSDLCY; BankBalUSDLCY) { }
            column(BankBalGBPLCY; BankBalGBPLCY) { }
            column(BankBalGRAMLCY; BankBalGRAMLCY) { }
            column(BankBalONSLCY; BankBalONSLCY) { }
            column(BankBalOtherLCY; BankBalOtherLCY) { }
            column(BankBalTotalLCY; BankBalTotalLCY) { }

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
                    field(ReportType; ReportType)
                    {
                        ApplicationArea = All;
                        Caption = 'Report Type';
                        OptionCaption = 'Günlük,Haftalık', Locked = true;
                        ToolTip = 'Select Daily or Weekly report type.', Locked = true;
                    }
                    field(ReportDate; ReportDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Report Date';
                        ToolTip = 'Select the report date to filter the report.';
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
        CurrDate: Date;
        EndDate: Date;
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Cheque: Record "Cheque-B2F";
        AmountLCY: Decimal;
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

        // Kurlar hazir olmadan banka TL karsiliklari hesaplanamaz
        CalcBankOpeningBalances();

        TempVLE.Reset();
        TempVLE.DeleteAll();
        i := 0;

        StartDate := YesterdayDate;
        EndDate := CalcDate('<+5M>', ReportDate) - 1;

        if ReportType = ReportType::Weekly then
            ReportModeNo := 1
        else
            ReportModeNo := 0;

        for CurrDate := StartDate to EndDate do begin
            TempVLE.Init();
            i += 1;
            TempVLE."Entry No." := i;
            TempVLE."Posting Date" := CurrDate; // Tarih
            if CurrDate < ReportDate then
                TempVLE."Document No." := '1' // Rapor tarihinden önceki (vadesi geçmiş) satır
            else
                TempVLE."Document No." := '2'; // Rapor tarihi ve sonrası
            TempVLE."Location Code" := Format(Date2DWY(CurrDate, 2)) + '.Hafta';//Hafta
            TempVLE."Order No." := GetMonthYearText(CurrDate);//Ay
            TempVLE."Document Line No." := Date2DWY(CurrDate, 1); // Haftanın günü (1 = Pazartesi)
            TempVLE."Cost Amount (Actual)" := 0; // Açık Hesap Cari ödeme
            TempVLE."Cost Amount (Actual) (ACY)" := 0; // GRUP İÇİ
            TempVLE."Cost Amount (Expected)" := 0; //  Vadesi Gelecek DBS Bakiyesi
            TempVLE."Cost Amount (Expected) (ACY)" := 0; // Firma Çekleri
            TempVLE."Cost Amount (Non-Invtbl.)" := 0; // Müşteri Çekleri
            TempVLE."Cost Amount (Non-Invtbl.)(ACY)" := 0; // Sipariş Ödemeleri
            TempVLE."Sales Amount (Actual)" := 0; //Vergi + SGK Ödemeleri
            TempVLE."Sales Amount (Expected)" := 0; //Maaş + Kira Ödemeleri
            TempVLE."Valued Quantity" := 0; // DMO Açık Hesap
            TempVLE."Item Ledger Entry Quantity" := 0; // İhale
            TempVLE."Invoiced Quantity" := 0; //Ecza Depoları
            TempVLE."Cost per Unit" := 0; // Eczacı
            TempVLE."Discount Amount" := 0; //İhracat
            TempVLE."Cost Posted to G/L" := 0; // Grup İçi
            TempVLE."Cost Posted to G/L (ACY)" := 0; //Özel Hastane KISA VADE
            TempVLE."Cost per Unit (ACY)" := 0; // Özel Hastane UZUN VADE
            TempVLE."Purchase Amount (Actual)" := 0; // Özel Hastane KEYTRUDA
            TempVLE."Purchase Amount (Expected)" := 0;//Kamu
            TempVLE."Expected Cost Posted to G/L" := 0;//Özel
            TempVLE."Exp. Cost Posted to G/L (ACY)" := 0; //Çek, DMO,Diğer

            TempVLE.Insert();
        end;

        VendLedgEntry.SetRange("Document Type", VendLedgEntry."Document Type"::Invoice);
        VendLedgEntry.SetRange(Open, true);
        if VendLedgEntry.FindSet() then
            repeat
                AmountLCY := GetAmountLCY(VendLedgEntry);

                if (VendLedgEntry."Vendor No." = 'ST00101001') or (VendLedgEntry."Vendor No." = 'ST00007001') then
                    AddToTempVLE(VendLedgEntry."Due Date", 1, AmountLCY) // Grupiçi
                else
                    if VendLedgEntry."Payment Method Code" = 'DBS' then
                        AddToTempVLE(VendLedgEntry."Due Date", 2, AmountLCY) // DBS
                    else
                        AddToTempVLE(VendLedgEntry."Due Date", 3, AmountLCY); // Grup - DBS Dışı
            until VendLedgEntry.Next() = 0;

        Cheque.SetFilter("Transaction Standard Type", '<>%1', Cheque."Transaction Standard Type"::Paid);
        if Cheque.FindSet() then
            repeat
                AddChequeToTempVLE(Cheque);
            until Cheque.Next() = 0;

        // Müşteri vade filtresi rapor tarihi üzerinden (rapor tarihi dahil)
        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetFilter("Due Date", '>=%1', ReportDate);
        if CustLedgEntry.FindSet() then
            repeat
                AddCustLedgerToTempVLE(CustLedgEntry);
            until CustLedgEntry.Next() = 0;

        if ReportType = ReportType::Weekly then begin
            // Haftalık: 108 ile başlayan banka kayıtları (MÜŞ POS/TİCA) + günlük DEVİR/TOPLAM hesabı
            AddWeeklyBankEntriesToTempVLE();
            CalcWeeklyBalances();
        end else begin
            AddReleasedPurchOrdersToTempVLE();
            AddManualExpensesToTempVLE();
            AddManualRevenuesToTempVLE();
        end;

    end;

    // Haftalık modda sadece haftalık rapordaki satırları besleyen gruplar işlenir:
    // 2 = DBS, 3 = Açık Hesap Borç, 7/8/9/18 = Açık Alacaklar (DMO, İhale, Ecza Deposu, Eczacı),
    // 10 = İhracat, 12/13/14 = Açık Alacaklar (Özel Hastane), 19 = Müş POS/Tica (banka 108)
    local procedure IsWeeklyGroup(pGroup: Integer): Boolean
    begin
        exit(pGroup in [2, 3, 7, 8, 9, 10, 12, 13, 14, 18, 19]);
    end;

    // Haftalık MÜŞ POS/TİCA: Bank Account Ledger Entry, Bank Account No. 108 ile başlayan, Open = Yes.
    // Vade tarihi "Closed at Date" alanından alınır, tutar "Amount" (TL'ye çevrilerek) Cost Posted to G/L alanına yazılır.
    local procedure AddWeeklyBankEntriesToTempVLE()
    var
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
        AmountLCY: Decimal;
    begin
        BankAccLedgEntry.SetFilter("Bank Account No.", '108*');
        BankAccLedgEntry.SetRange(Open, true);
        if BankAccLedgEntry.FindSet() then
            repeat
                AmountLCY := ConvertToLCY(BankAccLedgEntry."Currency Code", BankAccLedgEntry.Amount, BankAccLedgEntry."Amount (LCY)");
                AddToTempVLE(BankAccLedgEntry."Closed at Date", 19, AmountLCY);
            until BankAccLedgEntry.Next() = 0;
    end;

    // Haftalık DEVİR / TOPLAM:
    // Satır neti = Müş Çek + İhracat - Borç Çekleri + Müş POS/Tica + Açık Alacaklar - DBS - Açık Hesap Borç
    // İlk satır (rapor tarihi - 1) kendi toplamını devir olarak bırakır, sonraki her gün önceki günün TOPLAM'ını devralır.
    // DEVİR "Sales Amount (Actual)", TOPLAM "Sales Amount (Expected)" alanlarına yazılır (haftalık modda başka amaçla kullanılmaz).
    local procedure CalcWeeklyBalances()
    var
        PrevTotal: Decimal;
        DayNet: Decimal;
    begin
        PrevTotal := 0;
        TempVLE.Reset();
        if TempVLE.FindSet() then
            repeat
                DayNet :=
                    TempVLE."Cost Amount (Non-Invtbl.)" +                                  // Müş Çek/Senet
                    TempVLE."Discount Amount" -                                            // İhracat Tahsilatları
                    TempVLE."Cost Amount (Expected) (ACY)" +                               // Borç Çekleri (çıkar)
                    TempVLE."Cost Posted to G/L" +                                         // Müş POS/Tica
                    TempVLE."Valued Quantity" + TempVLE."Item Ledger Entry Quantity" +     // Açık Alacaklar
                    TempVLE."Invoiced Quantity" + TempVLE."Cost per Unit" +
                    TempVLE."Cost Posted to G/L (ACY)" + TempVLE."Cost per Unit (ACY)" +
                    TempVLE."Purchase Amount (Actual)" -
                    TempVLE."Cost Amount (Expected)" -                                     // DBS (çıkar)
                    TempVLE."Cost Amount (Actual)";                                        // Açık Hesap Borç (çıkar)

                TempVLE."Sales Amount (Actual)" := PrevTotal;               // DEVİR
                TempVLE."Sales Amount (Expected)" := PrevTotal + DayNet;    // TOPLAM
                PrevTotal := PrevTotal + DayNet;
                TempVLE.Modify();
            until TempVLE.Next() = 0;
    end;

    // Banka hesaplarındaki (102 ile başlayan) kayıtların rapor tarihinden bir gün önceki (YesterdayDate)
    // bakiyesi: döviz cinsine göre bakiye ve kurla TL karşılığı. Kurlar bu procedure'dan ÖNCE hesaplanmış olmalı.
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

        // Bakiye = tarihe kadar olan tüm kayıtlar ("Open" mutabakatla kapanan kayıtları dışarıda bırakırdı)
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

        // TL karşılıkları (GetRate: EUR/USD/GBP/GRAM kuru, ONS için ONS(USD) x USD kuru)
        BankBalEURLCY := BankBalEUR * GetRate('EUR');
        BankBalUSDLCY := BankBalUSD * GetRate('USD');
        BankBalGBPLCY := BankBalGBP * GetRate('GBP');
        BankBalGRAMLCY := BankBalGRAM * GetRate('GRAM');
        BankBalONSLCY := BankBalONS * GetRate('ONS');

        BankBalTotalLCY := BankBalTL + BankBalEURLCY + BankBalUSDLCY + BankBalGBPLCY +
                           BankBalGRAMLCY + BankBalONSLCY + BankBalOtherLCY;
    end;

    // Döviz kodunu TL kuruna çevirir, boşsa TL (1).
    // ONS (ons altın) USD cinsinden fiyatlandığı için TL kuru = ONS fiyatı x USD kuru (Excel: Y5 = ONS x USD)
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
        SalesInvHeader: Record "Sales Invoice Header";
        AmountLCY: Decimal;
    begin
        if not Customer.Get(pCLE."Customer No.") then
            exit;

        pCLE.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        AmountLCY := ConvertToLCY(pCLE."Currency Code", pCLE."Remaining Amount", pCLE."Remaining Amt. (LCY)");

        case Customer."Customer Group_Inc" of
            Customer."Customer Group_Inc"::DMO:
                AddToTempVLE(pCLE."Due Date", 7, AmountLCY);
            Customer."Customer Group_Inc"::"State Hospital",
            Customer."Customer Group_Inc"::"Univertsity Hospital":
                AddToTempVLE(pCLE."Due Date", 8, AmountLCY);
            Customer."Customer Group_Inc"::"Pharmaceutical Distributor":
                AddToTempVLE(pCLE."Due Date", 9, AmountLCY);
            Customer."Customer Group_Inc"::Pharmacy:
                AddToTempVLE(pCLE."Due Date", 18, AmountLCY); // Eczacı
            Customer."Customer Group_Inc"::Export:
                AddToTempVLE(pCLE."Due Date", 10, AmountLCY); // İhracat
            Customer."Customer Group_Inc"::"Group Company":
                AddToTempVLE(pCLE."Due Date", 11, AmountLCY);
            Customer."Customer Group_Inc"::"Private Hospital":
                begin
                    if not SalesInvHeader.Get(pCLE."Document No.") then
                        exit;
                    case UpperCase(Format(SalesInvHeader."Item Payment Terms Type_Inc")) of
                        'KISA VADE':
                            AddToTempVLE(pCLE."Due Date", 12, AmountLCY);
                        'UZUN VADE':
                            AddToTempVLE(pCLE."Due Date", 13, AmountLCY);
                        'KEYTRUDA':
                            AddToTempVLE(pCLE."Due Date", 14, AmountLCY);
                    end;
                end;
        end;
    end;

    local procedure AddChequeToTempVLE(var pCheque: Record "Cheque-B2F")
    var
        AmountLCY: Decimal;
        EntryNo: Integer;
    begin
        AmountLCY := ConvertToLCY(pCheque."Currency Code", pCheque.Amount, pCheque.Amount);

        EntryNo := GetEntryNo(pCheque."Due Date");
        if (EntryNo < 1) or (EntryNo > i) then
            exit; // 5 aylık aralığın dışında

        if not TempVLE.Get(EntryNo) then
            exit;

        if pCheque."Our Cheque" then
            TempVLE."Cost Amount (Expected) (ACY)" += AmountLCY
        else
            TempVLE."Cost Amount (Non-Invtbl.)" += AmountLCY;
        TempVLE.Modify();
    end;

    // Vadesi rapor tarihinden küçük olanlar ilk satıra (Rapor tarihi - 1), diğerleri kendi gününe yazılır
    local procedure GetEntryNo(pDueDate: Date): Integer
    begin
        if pDueDate < ReportDate then
            exit(1);

        exit(pDueDate - StartDate + 1);
    end;

    // pGroup: 1 = Grupiçi (Actual ACY), 2 = DBS (Expected), 3 = DBS Dışı (Actual),
    // 4 = Sipariş, 5 = Vergi+SGK, 6 = Maaş+Kira,
    // 7 = DMO, 8 = İhale, 9 = Ecza Deposu, 10 = İhracat, 11 = Grup İçi (müşteri),
    // 12 = Özel Hastane Kısa Vade, 13 = Özel Hastane Uzun Vade, 14 = Özel Hastane Keytruda
    // 15 = Manuel Gelir Kamu, 16 = Manuel Gelir Özel, 17 = Manuel Gelir Diğer, 18 = Eczacı
    local procedure AddToTempVLE(pDueDate: Date; pGroup: Integer; pAmount: Decimal)
    var
        EntryNo: Integer;
    begin
        if (ReportType = ReportType::Weekly) and not IsWeeklyGroup(pGroup) then
            exit; // Haftalık raporda olmayan satırlar (Grup içi, Sipariş, Vergi/SGK, Maaş/Kira, Manuel gelir) işlenmez

        EntryNo := GetEntryNo(pDueDate);
        if (EntryNo < 1) or (EntryNo > i) then
            exit; // 5 aylık aralığın dışında

        if not TempVLE.Get(EntryNo) then
            exit;

        case pGroup of
            1:
                TempVLE."Cost Amount (Actual) (ACY)" += pAmount;
            2:
                TempVLE."Cost Amount (Expected)" += pAmount;
            3:
                TempVLE."Cost Amount (Actual)" += pAmount;
            4:
                TempVLE."Cost Amount (Non-Invtbl.)(ACY)" += pAmount;
            5:
                TempVLE."Sales Amount (Actual)" += pAmount;
            6:
                TempVLE."Sales Amount (Expected)" += pAmount;
            7:
                TempVLE."Valued Quantity" += pAmount;
            8:
                TempVLE."Item Ledger Entry Quantity" += pAmount;
            9:
                TempVLE."Invoiced Quantity" += pAmount;
            10:
                TempVLE."Discount Amount" += pAmount;
            11:
                TempVLE."Cost Posted to G/L" += pAmount;
            12:
                TempVLE."Cost Posted to G/L (ACY)" += pAmount;
            13:
                TempVLE."Cost per Unit (ACY)" += pAmount;
            14:
                TempVLE."Purchase Amount (Actual)" += pAmount;
            15:
                TempVLE."Purchase Amount (Expected)" += pAmount;
            16:
                TempVLE."Expected Cost Posted to G/L" += pAmount;
            17:
                TempVLE."Exp. Cost Posted to G/L (ACY)" += pAmount;
            18:
                TempVLE."Cost per Unit" += pAmount;
            19:
                TempVLE."Cost Posted to G/L" += pAmount; // Haftalık: Müş POS/Tica (banka 108)
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

    local procedure AddReleasedPurchOrdersToTempVLE()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        OutstandingAmt: Decimal;
        OutstandingAmtLCY: Decimal;
        AmountLCY: Decimal;
    begin
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetRange(Status, PurchHeader.Status::Released);
        if PurchHeader.FindSet() then
            repeat
                OutstandingAmt := 0;
                OutstandingAmtLCY := 0;

                PurchLine.Reset();
                PurchLine.SetRange("Document Type", PurchHeader."Document Type");
                PurchLine.SetRange("Document No.", PurchHeader."No.");
                if PurchLine.FindSet() then
                    repeat
                        OutstandingAmt += PurchLine."Outstanding Amount";
                        OutstandingAmtLCY += PurchLine."Outstanding Amount (LCY)";
                    until PurchLine.Next() = 0;

                AmountLCY := ConvertToLCY(PurchHeader."Currency Code", OutstandingAmt, OutstandingAmtLCY);

                if AmountLCY <> 0 then
                    // Rapor tarihinden küçükler Rapor tarihi - 1 satırına, diğerleri kendi gününe yazılır (GetEntryNo)
                    AddToTempVLE(PurchHeader."Due Date", 4, AmountLCY);
            until PurchHeader.Next() = 0;
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

    local procedure AddManualExpensesToTempVLE()
    var
        ManualExpense: Record "Cash Flow Manual Expense";
    begin
        ManualExpense.SetFilter("Ending Date", '>=%1', ReportDate);
        ManualExpense.SetFilter("Expense Type_Inc", '<>%1', ManualExpense."Expense Type_Inc"::" ");
        if ManualExpense.FindSet() then
            repeat
                case ManualExpense."Expense Type_Inc" of
                    ManualExpense."Expense Type_Inc"::Tax,
                    ManualExpense."Expense Type_Inc"::"Social Security":
                        AddToTempVLE(ManualExpense."Ending Date", 5, ManualExpense.Amount);
                    ManualExpense."Expense Type_Inc"::Salary,
                    ManualExpense."Expense Type_Inc"::Rent:
                        AddToTempVLE(ManualExpense."Ending Date", 6, ManualExpense.Amount);
                end;
            until ManualExpense.Next() = 0;
    end;

    local procedure AddManualRevenuesToTempVLE()
    var
        ManualRevenue: Record "Cash Flow Manual Revenue";
    begin
        ManualRevenue.SetFilter("Ending Date", '>=%1', ReportDate);
        if ManualRevenue.FindSet() then
            repeat
                case ManualRevenue."Revenue Type_Inc" of
                    ManualRevenue."Revenue Type_Inc"::Public:
                        AddToTempVLE(ManualRevenue."Ending Date", 15, ManualRevenue.Amount);
                    ManualRevenue."Revenue Type_Inc"::Private:
                        AddToTempVLE(ManualRevenue."Ending Date", 16, ManualRevenue.Amount);
                    else
                        AddToTempVLE(ManualRevenue."Ending Date", 17, ManualRevenue.Amount);
                end;
            until ManualRevenue.Next() = 0;
    end;

    var
        i: Integer;
        ReportDate: Date;
        ReportType: Option Daily,Weekly;
        ReportModeNo: Integer;
        YesterdayDate: Date;
        StartDate: Date;
        // Kurlar (rapor tarihi - 1)
        EURRate: Decimal;
        USDRate: Decimal;
        GBPRate: Decimal;
        GRAMRate: Decimal;
        ONSRate: Decimal;
        // Banka bakiyeleri (döviz cinsinden)
        BankBalTL: Decimal;
        BankBalEUR: Decimal;
        BankBalUSD: Decimal;
        BankBalGBP: Decimal;
        BankBalGRAM: Decimal;
        BankBalONS: Decimal;
        // Banka bakiyeleri (TL karşılığı)
        BankBalEURLCY: Decimal;
        BankBalUSDLCY: Decimal;
        BankBalGBPLCY: Decimal;
        BankBalGRAMLCY: Decimal;
        BankBalONSLCY: Decimal;
        BankBalOtherLCY: Decimal;
        BankBalTotalLCY: Decimal;

}
