report 70818 "Financial Statements Report"
{
    ApplicationArea = All;
    Caption = 'Financial Statements Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Financial Statements Report.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;

            column(GirisNo; "Entry No.")
            {
            }
            column(HesapNo; "Document No.")
            {
            }
            column(HesapNo_Ad; GetAccountName("Document No."))
            {
            }
            column(HesapNo2; "Source No.")
            {
            }
            column(HesapNo2_Ad; GetAccountName("Source No."))
            {
            }
            column(HesapNo3; "Job Task No.")
            {
            }
            column(HesapNo3_Ad; GetAccountName("Job Task No."))
            {
            }
            column(Bilanco_Gelir; "External Document No.")
            {
            }
            column(StartDate; "Posting Date")
            {
            }
            column(Yıl_Ay; "Item No.")
            {
            }
            column(Tutar; "Invoiced Quantity")
            {
            }
            column(Group2; "Job Task No.")
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
        var
            LUserSetup: Record "User Setup";
        begin
            StartDate := DMY2Date(1, 1, Date2DMY(Today, 3));
            EndDate := Today;


        end;
    }

    local procedure FillTempVLE()
    var
        LGLAccount: Record "G/L Account";
        LGLEntry: Record "G/L Entry";
        MonthStartDate: Date;
        MonthEndDate: Date;
        AccountTotals: Dictionary of [Code[20], Decimal];
        AccountNo: Code[20];
        Total: Decimal;
    begin
        Clear(TempVLE);

        if StartDate = 0D then
            error('Start Date cannot be empty. Please select a valid start date.');
        if EndDate = 0D then
            error('End Date cannot be empty. Please select a valid end date.');

        LGLAccount.Init();
        LGLAccount.SetFilter("No.", '1*|2*|3*|4*|5*');
        if LGLAccount.FindSet() then
            repeat
                TempVLE.Init();
                i += 1;
                TempVLE."Entry No." := i;

                if TempVLE."Source No." = TempVLE."Job Task No." then
                    TempVLE."Job Task No." := '1';
                // TempVLE.Description := LGLAccount.Name; //Hesap Hareke
                case CopyStr(LGLAccount."No.", 1, 1) of
                    '1':
                        TempVLE."External Document No." := 'AKTİF (VARLIKLAR)';
                    '2':
                        TempVLE."External Document No." := 'AKTİF (VARLIKLAR)';
                    '3':
                        TempVLE."External Document No." := 'PASİF (KAYNAKLAR)';
                    '4':
                        TempVLE."External Document No." := 'PASİF (KAYNAKLAR)';
                    '5':
                        TempVLE."External Document No." := 'PASİF (KAYNAKLAR)';
                end;

                if CopyStr(LGLAccount."No.", 1, 3) = '103' then begin
                    TempVLE."Document No." := '3'; //HesapNo1
                    TempVLE."Source No." := '30';//HesapNo2
                    TempVLE."Job Task No." := CopyStr(LGLAccount."No.", 1, 3);
                    TempVLE."External Document No." := 'PASİF (KAYNAKLAR)';
                end else begin
                    TempVLE."Document No." := CopyStr(LGLAccount."No.", 1, 1); //HesapNo1
                    TempVLE."Source No." := CopyStr(LGLAccount."No.", 1, 2);//HesapNo2
                    TempVLE."Job Task No." := CopyStr(LGLAccount."No.", 1, 3);
                end;
                TempVLE."Posting Date" := StartDate;
                TempVLE."Item No." := GetMonthYearText(StartDate);
                TempVLE."Invoiced Quantity" := 0;
                TempVLE.Insert();
            until LGLAccount.Next() = 0;


        MonthStartDate := StartDate;

        while MonthStartDate <= EndDate do begin
            // Bu ayın son günü (EndDate'i geçmeyecek şekilde)
            MonthEndDate := CalcDate('<CM>', MonthStartDate);
            if MonthEndDate > EndDate then
                MonthEndDate := EndDate;

            // Bu ay içindeki kayıtları G/L Account No.'ya göre topla
            Clear(AccountTotals);
            LGLEntry.Reset();
            LGLEntry.SetRange("Posting Date", MonthStartDate, MonthEndDate);
            LGLEntry.SetFilter("G/L Account No.", '1*|2*|3*|4*|5*');
            if LGLEntry.FindSet() then
                repeat
                    if AccountTotals.ContainsKey(LGLEntry."G/L Account No.") then
                        AccountTotals.Set(LGLEntry."G/L Account No.", AccountTotals.Get(LGLEntry."G/L Account No.") + LGLEntry.Amount)
                    else
                        AccountTotals.Add(LGLEntry."G/L Account No.", LGLEntry.Amount);
                until LGLEntry.Next() = 0;

            // Bu ay için hesaplanan her G/L Account toplamını TempVLE'ye yaz
            foreach AccountNo in AccountTotals.Keys() do begin
                Total := AccountTotals.Get(AccountNo);

                TempVLE.Init();
                i += 1;
                TempVLE."Entry No." := i;

                if TempVLE."Source No." = TempVLE."Job Task No." then
                    TempVLE."Job Task No." := '1';

                case CopyStr(AccountNo, 1, 1) of
                    '1':
                        TempVLE."External Document No." := 'AKTİF (VARLIKLAR)';
                    '2':
                        TempVLE."External Document No." := 'AKTİF (VARLIKLAR)';
                    '3':
                        TempVLE."External Document No." := 'PASİF (KAYNAKLAR)';
                    '4':
                        TempVLE."External Document No." := 'PASİF (KAYNAKLAR)';
                    '5':
                        TempVLE."External Document No." := 'PASİF (KAYNAKLAR)';
                end;
                if CopyStr(AccountNo, 1, 3) = '103' then begin
                    TempVLE."Document No." := '3';
                    TempVLE."Source No." := '30';
                    TempVLE."Job Task No." := CopyStr(AccountNo, 1, 3);
                    TempVLE."External Document No." := 'PASİF (KAYNAKLAR)';
                end else begin
                    TempVLE."Document No." := CopyStr(AccountNo, 1, 1);
                    TempVLE."Source No." := CopyStr(AccountNo, 1, 2);
                    TempVLE."Job Task No." := CopyStr(AccountNo, 1, 3);
                end;
                TempVLE."Posting Date" := MonthStartDate;
                TempVLE."Item No." := GetMonthYearText(MonthStartDate);
                TempVLE."Invoiced Quantity" := Total;
                TempVLE.Insert();
            end;
            // Bir sonraki ayın ilk gününe geç
            MonthStartDate := CalcDate('<CM+1D>', MonthStartDate);
        end;
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


    local procedure GetAccountName(AccountNo: Code[20]): Text[100]

    var
        LGLAccount: Record "G/L Account";
    begin
        if LGLAccount.Get(AccountNo) then
            exit(LGLAccount.Name);
        exit('');
    end;

    var
        i: Integer;
        StartDate: Date;
        EndDate: Date;

}