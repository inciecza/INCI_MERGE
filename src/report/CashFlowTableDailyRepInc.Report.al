report 70827 "CashFlow Table Daily Rep._Inc"
{
    ApplicationArea = All;
    Caption = 'Cash Flow Tables Daily Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Cash Flow Tables Daily Report.rdlc';
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
            column(WeeklyDevir; "Sales Amount (Actual)") { }                        // (Günlük raporda kullanılmaz, RDLC uyumu için)
            column(WeeklyToplam; "Sales Amount (Expected)") { }                     // (Günlük raporda kullanılmaz, RDLC uyumu için)
            column(ReportMode; ReportModeNo) { }                                    // Her zaman 0 = Günlük
            column(IsINC; IsINCCompany) { }                                         // 1 = Şirket INC (bazı kolonlar RDLC'de gizlenir)

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
            column(ManuelGelirKamu; "Purchase Amount (Expected)") { }               // Kamu (bu raporda kullanılmaz)
            column(ManuelGelirOzel; "Expected Cost Posted to G/L") { }              // Özel (bu raporda kullanılmaz)
            column(ManuelGelirDiger; "Exp. Cost Posted to G/L (ACY)") { }           // Çek, DMO, Diğer (bu raporda kullanılmaz)

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
                    field(CashFlowForecastNo; CashFlowForecastNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Cash Flow Forecast No.';
                        TableRelation = "Cash Flow Forecast"."No.";
                        ToolTip = 'Select the cash flow forecast whose entries are used in the report.';
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
        CFEntry: Record "Cash Flow Forecast Entry";
        LCompany: Record Company;
        CurrDate: Date;
        EndDate: Date;
    begin
        if ReportDate = 0D then
            error('Report Date cannot be empty. Please select a valid report date.');
        if CashFlowForecastNo = '' then
            error('Cash Flow Forecast No. cannot be empty. Please select a cash flow forecast.');

        // Rapor tarihinden önceki günün kurları
        YesterdayDate := ReportDate - 1;
        EURRate := GetExchangeRate('EUR', YesterdayDate);
        USDRate := GetExchangeRate('USD', YesterdayDate);
        GBPRate := GetExchangeRate('GBP', YesterdayDate);
        GRAMRate := GetExchangeRate('GRAM', YesterdayDate);
        ONSRate := GetExchangeRate('ONS', YesterdayDate);

        // Kurlar hazır olmadan banka TL karşılıkları hesaplanamaz
        CalcBankOpeningBalances();

        TempVLE.Reset();
        TempVLE.DeleteAll();
        i := 0;

        StartDate := YesterdayDate;
        EndDate := CalcDate('<+5M>', ReportDate) - 1;
        ReportModeNo := 0; // Sadece günlük tasarım

        // Şirket ayrımı: INC şirketinde sadece Ecza Depoları ve İhracat (müşteri) satırları kullanılır
        IsINCCompany := 0;
        if LCompany.Get(CompanyName) then
            if LCompany.Name = 'INC' then
                IsINCCompany := 1;

        for CurrDate := StartDate to EndDate do begin
            TempVLE.Init();
            i += 1;
            TempVLE."Entry No." := i;
            TempVLE."Posting Date" := CurrDate; // Tarih
            if CurrDate < ReportDate then
                TempVLE."Document No." := '1' // Rapor tarihinden önceki (vadesi geçmiş) satır
            else
                TempVLE."Document No." := '2'; // Rapor tarihi ve sonrası
            TempVLE."Location Code" := Format(Date2DWY(CurrDate, 2)) + '.Hafta'; // Hafta
            TempVLE."Order No." := GetMonthYearText(CurrDate); // Ay
            TempVLE."Document Line No." := Date2DWY(CurrDate, 1); // Haftanın günü (1 = Pazartesi)
            TempVLE."Cost Amount (Actual)" := 0; // Açık Hesap Cari ödeme
            TempVLE."Cost Amount (Actual) (ACY)" := 0; // GRUP İÇİ
            TempVLE."Cost Amount (Expected)" := 0; // Vadesi Gelecek DBS Bakiyesi
            TempVLE."Cost Amount (Expected) (ACY)" := 0; // Firma Çekleri
            TempVLE."Cost Amount (Non-Invtbl.)" := 0; // Müşteri Çekleri
            TempVLE."Cost Amount (Non-Invtbl.)(ACY)" := 0; // Sipariş Ödemeleri
            TempVLE."Sales Amount (Actual)" := 0; // Vergi + SGK Ödemeleri
            TempVLE."Sales Amount (Expected)" := 0; // Maaş + Kira Ödemeleri
            TempVLE."Valued Quantity" := 0; // DMO Açık Hesap
            TempVLE."Item Ledger Entry Quantity" := 0; // İhale
            TempVLE."Invoiced Quantity" := 0; // Ecza Depoları
            TempVLE."Cost per Unit" := 0; // Eczacı
            TempVLE."Discount Amount" := 0; // İhracat
            TempVLE."Cost Posted to G/L" := 0; // Grup İçi (müşteri)
            TempVLE."Cost Posted to G/L (ACY)" := 0; // Özel Hastane KISA VADE
            TempVLE."Cost per Unit (ACY)" := 0; // Özel Hastane UZUN VADE
            TempVLE."Purchase Amount (Actual)" := 0; // Özel Hastane KEYTRUDA
            TempVLE."Purchase Amount (Expected)" := 0; // Kamu
            TempVLE."Expected Cost Posted to G/L" := 0; // Özel
            TempVLE."Exp. Cost Posted to G/L (ACY)" := 0; // Çek, DMO, Diğer

            TempVLE.Insert();
        end;

        // Özel hastane müşterilerinin vade tipi (fatura üzerinden), ödeme satırlarını faturanın grubundan düşmek için
        LoadPrivateHospitalGroups();

        CFEntry.SetRange("Cash Flow Forecast No.", CashFlowForecastNo);
        if CFEntry.FindSet() then
            repeat
                case CFEntry."Source Type" of
                    CFEntry."Source Type"::Payables:
                        AddPayableEntry(CFEntry);
                    CFEntry."Source Type"::"Purchase Orders":
                        AddToTempVLE(CFEntry."Cash Flow Date", 4, Abs(GetEntryAmountLCY(CFEntry))); // Sipariş Ödemeleri
                    CFEntry."Source Type"::"Our Cheque-B2F":
                        AddToTempVLE(CFEntry."Cash Flow Date", 20, Abs(GetEntryAmountLCY(CFEntry))); // Firma Çekleri
                    CFEntry."Source Type"::"Cust. Cheque-B2F":
                        AddToTempVLE(CFEntry."Cash Flow Date", 21, Abs(GetEntryAmountLCY(CFEntry))); // Müşteri Çekleri
                    CFEntry."Source Type"::"Cash Flow Manual Expense":
                        AddManualExpenseEntry(CFEntry);
                    CFEntry."Source Type"::Receivables:
                        AddReceivableEntry(CFEntry);
                end;
            until CFEntry.Next() = 0;
    end;

    // Tutar her zaman "Amount-B2F", döviz her zaman "Currency Code-B2F" alanından alınır.
    // Bilinen kurlar (EUR, USD, GBP, GRAM, ONS) rapor tarihinden bir önceki günün kuru ile çevrilir,
    // diğer dövizlerde kaydın "Amount (LCY)" tutarı kullanılır.
    local procedure GetEntryAmountLCY(var pCFEntry: Record "Cash Flow Forecast Entry"): Decimal
    begin
        exit(ConvertToLCY(pCFEntry."Currency Code-B2F", pCFEntry."Amount-B2F", pCFEntry."Amount (LCY)"));
    end;

    // Borç hesapları: Vendor No.-B2F = ST00101001 / ST00007001 => GRUP İÇİ,
    // satıcıdaki Payment Method Code = DBS => Vadesi Gelecek DBS, diğerleri => Açık Hesap Cari ödeme
    local procedure AddPayableEntry(var pCFEntry: Record "Cash Flow Forecast Entry")
    var
        Vendor: Record Vendor;
        AmountLCY: Decimal;
    begin
        AmountLCY := Abs(GetEntryAmountLCY(pCFEntry));

        if (pCFEntry."Vendor No.-B2F" = 'ST00101001') or (pCFEntry."Vendor No.-B2F" = 'ST00007001') then begin
            AddToTempVLE(pCFEntry."Cash Flow Date", 1, AmountLCY); // Grup içi
            exit;
        end;

        if Vendor.Get(pCFEntry."Vendor No.-B2F") then
            if Vendor."Payment Method Code" = 'DBS' then begin
                AddToTempVLE(pCFEntry."Cash Flow Date", 2, AmountLCY); // DBS
                exit;
            end;

        AddToTempVLE(pCFEntry."Cash Flow Date", 3, AmountLCY); // Açık Hesap Cari ödeme
    end;

    // Manuel gider: Source No. ile Cash Flow Manual Expense'e gidilir.
    // Vergi + Sosyal Güvenlik => Vergi + SGK, Maaş + Kira => Maaş + Kira
    local procedure AddManualExpenseEntry(var pCFEntry: Record "Cash Flow Forecast Entry")
    var
        ManualExpense: Record "Cash Flow Manual Expense";
        AmountLCY: Decimal;
    begin
        if not ManualExpense.Get(pCFEntry."Source No.") then
            exit;

        AmountLCY := Abs(GetEntryAmountLCY(pCFEntry));

        case ManualExpense."Expense Type_Inc" of
            ManualExpense."Expense Type_Inc"::Tax,
            ManualExpense."Expense Type_Inc"::"Social Security":
                AddToTempVLE(pCFEntry."Cash Flow Date", 5, AmountLCY);
            ManualExpense."Expense Type_Inc"::Salary,
            ManualExpense."Expense Type_Inc"::Rent:
                AddToTempVLE(pCFEntry."Cash Flow Date", 6, AmountLCY);
        end;
    end;

    // Müşteri numarası: önce Customer No.-B2F, boşsa Document No. ile Cust. Ledger Entry'den
    local procedure GetCustomerNo(var pCFEntry: Record "Cash Flow Forecast Entry"): Code[20]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        if pCFEntry."Customer No.-B2F" <> '' then
            exit(pCFEntry."Customer No.-B2F");

        CustLedgEntry.SetRange("Document No.", pCFEntry."Document No.");
        if CustLedgEntry.FindFirst() then
            exit(CustLedgEntry."Customer No.");

        exit('');
    end;

    // Her özel hastane müşterisi için faturadaki Item Payment Terms Type_Inc'e göre grup (12 = Kısa, 13 = Uzun, 14 = Keytruda)
    local procedure LoadPrivateHospitalGroups()
    var
        CFEntry: Record "Cash Flow Forecast Entry";
        Customer: Record Customer;
        SalesInvHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
    begin
        Clear(PrivateHospitalGroups);
        CFEntry.SetRange("Cash Flow Forecast No.", CashFlowForecastNo);
        CFEntry.SetRange("Source Type", CFEntry."Source Type"::Receivables);
        if CFEntry.FindSet() then
            repeat
                CustomerNo := GetCustomerNo(CFEntry);
                if CustomerNo <> '' then
                    if Customer.Get(CustomerNo) then
                        if Customer."Customer Group_Inc" = Customer."Customer Group_Inc"::"Private Hospital" then
                            if SalesInvHeader.Get(CFEntry."Document No.") then
                                case UpperCase(Format(SalesInvHeader."Item Payment Terms Type_Inc")) of
                                    'KISA VADE':
                                        SetPrivateHospitalGroup(CustomerNo, 12);
                                    'UZUN VADE':
                                        SetPrivateHospitalGroup(CustomerNo, 13);
                                    'KEYTRUDA':
                                        SetPrivateHospitalGroup(CustomerNo, 14);
                                end;
            until CFEntry.Next() = 0;
    end;

    local procedure SetPrivateHospitalGroup(pCustomerNo: Code[20]; pGroup: Integer)
    begin
        if PrivateHospitalGroups.ContainsKey(pCustomerNo) then
            PrivateHospitalGroups.Set(pCustomerNo, pGroup)
        else
            PrivateHospitalGroups.Add(pCustomerNo, pGroup);
    end;

    // Alacak hesapları: hem faturalar (+) hem ödemeler (-) gelebilir, işaretli tutar toplanır;
    // böylece ödeme aynı müşterinin faturasından düşülmüş olur. Grup, müşterinin Customer Group_Inc alanına göre belirlenir.
    // INC şirketinde sadece Ecza Depoları (9) ve İhracat (10) kullanılır.
    local procedure AddReceivableEntry(var pCFEntry: Record "Cash Flow Forecast Entry")
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
        AmountLCY: Decimal;
        Grp: Integer;
    begin
        CustomerNo := GetCustomerNo(pCFEntry);
        if CustomerNo = '' then
            exit;
        if not Customer.Get(CustomerNo) then
            exit;

        AmountLCY := GetEntryAmountLCY(pCFEntry);

        case Customer."Customer Group_Inc" of
            Customer."Customer Group_Inc"::DMO:
                Grp := 7;
            Customer."Customer Group_Inc"::"State Hospital",
            Customer."Customer Group_Inc"::"Univertsity Hospital":
                Grp := 8;
            Customer."Customer Group_Inc"::"Pharmaceutical Distributor":
                Grp := 9;
            Customer."Customer Group_Inc"::Pharmacy:
                Grp := 18; // Eczacı
            Customer."Customer Group_Inc"::Export:
                Grp := 10; // İhracat
            Customer."Customer Group_Inc"::"Group Company":
                Grp := 11;
            Customer."Customer Group_Inc"::"Private Hospital":
                if not PrivateHospitalGroups.Get(CustomerNo, Grp) then
                    exit;
        end;

        if Grp = 0 then
            exit;

        if (IsINCCompany = 1) and not (Grp in [9, 10]) then
            exit;

        AddToTempVLE(pCFEntry."Cash Flow Date", Grp, AmountLCY);
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

    // Vadesi rapor tarihinden küçük olanlar ilk satıra (Rapor tarihi - 1), diğerleri kendi gününe yazılır
    local procedure GetEntryNo(pDueDate: Date): Integer
    begin
        if pDueDate < ReportDate then
            exit(1);

        exit(pDueDate - StartDate + 1);
    end;

    // pGroup: 1 = Grup içi (Actual ACY), 2 = DBS (Expected), 3 = Açık Hesap (Actual),
    // 4 = Sipariş, 5 = Vergi+SGK, 6 = Maaş+Kira,
    // 7 = DMO, 8 = İhale, 9 = Ecza Deposu, 10 = İhracat, 11 = Grup İçi (müşteri),
    // 12 = Özel Hastane Kısa Vade, 13 = Özel Hastane Uzun Vade, 14 = Özel Hastane Keytruda,
    // 18 = Eczacı, 20 = Firma Çekleri, 21 = Müşteri Çekleri
    local procedure AddToTempVLE(pDueDate: Date; pGroup: Integer; pAmount: Decimal)
    var
        EntryNo: Integer;
    begin
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
            18:
                TempVLE."Cost per Unit" += pAmount;
            20:
                TempVLE."Cost Amount (Expected) (ACY)" += pAmount;
            21:
                TempVLE."Cost Amount (Non-Invtbl.)" += pAmount;
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

    var
        PrivateHospitalGroups: Dictionary of [Code[20], Integer];
        i: Integer;
        CashFlowForecastNo: Code[20];
        ReportDate: Date;
        ReportModeNo: Integer;
        IsINCCompany: Integer;
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
