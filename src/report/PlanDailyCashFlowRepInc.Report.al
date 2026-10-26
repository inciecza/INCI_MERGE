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

        EURRate := GetExchangeRate('EUR', ReportDate - 1);
        USDRate := GetExchangeRate('USD', ReportDate - 1);

        TempVLE.Reset();
        TempVLE.DeleteAll();
        i := 0;


        EndDate := CalcDate('<+5M>', ReportDate) - 1;

        for CurrDate := ReportDate to EndDate do begin
            TempVLE.Init();
            i += 1;
            TempVLE."Entry No." := i;
            TempVLE."Posting Date" := CurrDate;
            TempVLE."Location Code" := Format(Date2DWY(CurrDate, 2)) + '.Hafta';
            TempVLE."Order No." := GetMonthYearText(CurrDate);
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
            TempVLE."Purchase Amount (Expected)" := 0;
            TempVLE."Expected Cost Posted to G/L" := 0;
            TempVLE."Exp. Cost Posted to G/L (ACY)" := 0;

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

        CustLedgEntry.SetRange("Document Type", CustLedgEntry."Document Type"::Invoice);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetFilter("Due Date", '>%1', Today);
        if CustLedgEntry.FindSet() then
            repeat
                AddCustLedgerToTempVLE(CustLedgEntry);
            until CustLedgEntry.Next() = 0;

        AddReleasedPurchOrdersToTempVLE();
        AddManualExpensesToTempVLE();

    end;

    local procedure GetAmountLCY(var pVLE: Record "Vendor Ledger Entry"): Decimal
    begin
        pVLE.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        case pVLE."Currency Code" of
            '':
                exit(-pVLE."Remaining Amount");
            'USD':
                exit(-pVLE."Remaining Amount" * USDRate);
            'EUR':
                exit(-pVLE."Remaining Amount" * EURRate);
            else
                exit(-pVLE."Remaining Amt. (LCY)");
        end;
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
        case pCLE."Currency Code" of
            '':
                AmountLCY := pCLE."Remaining Amount";
            'USD':
                AmountLCY := pCLE."Remaining Amount" * USDRate;
            'EUR':
                AmountLCY := pCLE."Remaining Amount" * EURRate;
            else
                AmountLCY := pCLE."Remaining Amt. (LCY)";
        end;

        case Customer."Customer Group_Inc" of
            Customer."Customer Group_Inc"::DMO:
                AddToTempVLE(pCLE."Due Date", 7, AmountLCY);
            Customer."Customer Group_Inc"::"State Hospital",
            Customer."Customer Group_Inc"::"Univertsity Hospital":
                AddToTempVLE(pCLE."Due Date", 8, AmountLCY);
            Customer."Customer Group_Inc"::"Pharmaceutical Distributor":
                AddToTempVLE(pCLE."Due Date", 9, AmountLCY);
            Customer."Customer Group_Inc"::Pharmacy,
            Customer."Customer Group_Inc"::Export:
                AddToTempVLE(pCLE."Due Date", 10, AmountLCY);
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
        case pCheque."Currency Code" of
            '':
                AmountLCY := pCheque.Amount;
            'USD':
                AmountLCY := pCheque.Amount * USDRate;
            'EUR':
                AmountLCY := pCheque.Amount * EURRate;
            else
                AmountLCY := pCheque.Amount;
        end;

        if pCheque."Due Date" < ReportDate then
            EntryNo := 1 // rapor tarihindeki satır
        else
            EntryNo := pCheque."Due Date" - ReportDate + 1;

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

    // pGroup: 1 = Grupiçi (Actual ACY), 2 = DBS (Expected), 3 = DBS Dışı (Actual),
    // 4 = Sipariş, 5 = Vergi+SGK, 6 = Maaş+Kira,
    // 7 = DMO, 8 = İhale, 9 = Ecza Deposu, 10 = Eczane+İhracat, 11 = Grup İçi (müşteri),
    // 12 = Özel Hastane Kısa Vade, 13 = Özel Hastane Uzun Vade, 14 = Özel Hastane Keytruda
    local procedure AddToTempVLE(pDueDate: Date; pGroup: Integer; pAmount: Decimal)
    var
        TargetDate: Date;
        EntryNo: Integer;
    begin
        if pDueDate > ReportDate then
            TargetDate := pDueDate
        else
            TargetDate := ReportDate; // Rapor tarihi ve öncesi, rapor tarihinde toplanır

        EntryNo := TargetDate - ReportDate + 1;
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
        end;
        TempVLE.Modify();
    end;

    local procedure GetExchangeRate(pCurrencyCode: Code[10]; pDate: Date): Decimal
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        CurrExchRate.SetRange("Currency Code", pCurrencyCode);
        CurrExchRate.SetFilter("Starting Date", '..%1', pDate);
        if CurrExchRate.FindLast() then
            exit(CurrExchRate."Relational Exch. Rate Amount");

        exit(0);
    end;

    local procedure AddReleasedPurchOrdersToTempVLE()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        OutstandingAmt: Decimal;
        AmountLCY: Decimal;
    begin
        PurchHeader.SetRange("Document Type", PurchHeader."Document Type"::Order);
        PurchHeader.SetRange(Status, PurchHeader.Status::Released);
        if PurchHeader.FindSet() then
            repeat
                OutstandingAmt := 0;
                AmountLCY := 0;

                PurchLine.Reset();
                PurchLine.SetRange("Document Type", PurchHeader."Document Type");
                PurchLine.SetRange("Document No.", PurchHeader."No.");
                if PurchLine.FindSet() then
                    repeat
                        OutstandingAmt += PurchLine."Outstanding Amount";
                        // Diğer dövizler için kur tanımı yok, satırın LCY tutarı kullanılır
                        if not (PurchHeader."Currency Code" in ['', 'USD', 'EUR']) then
                            AmountLCY += PurchLine."Outstanding Amount (LCY)";
                    until PurchLine.Next() = 0;

                case PurchHeader."Currency Code" of
                    '':
                        AmountLCY := OutstandingAmt;
                    'USD':
                        AmountLCY := OutstandingAmt * USDRate;
                    'EUR':
                        AmountLCY := OutstandingAmt * EURRate;
                end;

                if AmountLCY <> 0 then
                    // Rapor tarihi ve öncesi rapor tarihinde toplanır, sonrası kendi gününe yazılır (AddToTempVLE bunu zaten yapıyor)
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
        ManualExpense.SetFilter("Ending Date", '>%1', ReportDate);
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


    var
        i: Integer;
        ReportDate: Date;
        EURRate: Decimal;
        USDRate: Decimal;

}