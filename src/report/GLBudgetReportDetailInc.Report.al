report 70821 "G/L Budget Report Detail_Inc"
{
    ApplicationArea = All;
    Caption = 'G/L Budget Report Detail';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/GL Budget Report Detail.rdlc';
    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;

            column(GirisNo; "Entry No.")
            {
            }
            column(Tarih; "Posting Date")
            {
            }
            column(Bütçe_Kodu; "Document No.")
            {
            }
            column(Bütçe_Ad; Description)
            {
            }
            column(Bütçe_Genel_Ad; "Item No.")
            {
            }
            column(Bütçe_Tutar; "Cost per Unit")
            {
            }
            column(Gerçekleşen_Tutar; "Cost per Unit (ACY)")
            {
            }
            column(Önceki_Yıl_Tutar; "Purchase Amount (Actual)")
            {
            }
            column(Rapor_Adı; "User ID")
            {
            }
            column(Ay_Yıl; "Job No.")
            {
            }
            column(Rapor_Kodu; "Job Task No.")
            {
            }
            column(Faaliyet_Gideri; "Cost Amount (Expected)")
            {
            }
            column(Detay_Açıklaması; "ITS Deacvt. Reason Desc.-B2F")
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

                    field(BudgetName; BudgetName)
                    {
                        ApplicationArea = All;
                        Caption = 'Budget Name';
                        ToolTip = 'Select the budget name to filter the report.';
                        TableRelation = "G/L Budget Name";
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
        var
            LUserSetup: Record "User Setup";
        begin
            ReportDate := 20260701D;
            BudgetName := 'INC BÜTÇE';


        end;
    }


    local procedure FillTempVLE()
    var
        LGLBudgetEntry: Record "G/L Budget Entry";
        LDimensionValue: Record "Dimension Value";
        LGLEntry: Record "G/L Entry";
        LAccount: Record "G/L Account";
        MonthHasRow: Dictionary of [Date, Boolean];
        CurrMonth: Date;
        LastMonth: Date;
        LDescription: Text;
    begin
        TempVLE.Reset();
        TempVLE.DeleteAll();
        i := 0;
        StartDate := CalcDate('<-CM>', ReportDate);
        EndDate := CalcDate('<CM>', ReportDate);

        if StartDate = 0D then
            Error('Start Date cannot be empty. Please select a valid start date.');
        if EndDate = 0D then
            Error('End Date cannot be empty. Please select a valid end date.');
        if StartDate > EndDate then
            Error('Start Date cannot be greater than End Date.');
        LastMonth := CalcDate('<-CM>', EndDate);
        LoadDimensionCache();
        LDimensionValue.SetRange("Dimension Code", 'BÜTÇE');
        LDimensionValue.SetRange(Blocked, false);
        if LDimensionValue.FindSet() then
            repeat
                LAccount.Init();
                LAccount.SetRange("Budget Code_Inc", LDimensionValue."Code");
                if LAccount.FindSet() then
                    repeat
                        Clear(MonthHasRow);
                        // G/L Entry bu bütçe kodu için TEK sorguyla okunur
                        LGLEntry.Reset();
                        LGLEntry.SetLoadFields("G/L Account No.", "Posting Date", Amount, Description);
                        LGLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                        LGLEntry.SetRange("G/L Account No.", LAccount."No.");
                        LGLEntry.SetRange("Posting Date", CalcDate('<-CM>', StartDate), CalcDate('<CM>', EndDate));

                        if LGLEntry.FindSet() then
                            repeat
                                CurrMonth := CalcDate('<-CM>', LGLEntry."Posting Date");
                                if not MonthHasRow.ContainsKey(CurrMonth) then
                                    MonthHasRow.Add(CurrMonth, true);

                                GetMonthYearText(CurrMonth);
                                LGLEntry.CalcFields("Shortcut Dimension 3 Code", "Shortcut Dimension 5 Code");
                                case LDimensionValue."Detail Description Type_Inc" of
                                    LDimensionValue."Detail Description Type_Inc"::Description:
                                        LDescription := LGLEntry.Description;
                                    LDimensionValue."Detail Description Type_Inc"::"Employee Code":
                                        LDescription := GetDimension(LGLEntry."Shortcut Dimension 5 Code", 1);
                                    LDimensionValue."Detail Description Type_Inc"::"Vehicle Code":
                                        LDescription := GetDimension(LGLEntry."Shortcut Dimension 3 Code", 2);
                                end;
                                if LDescription = '' then
                                    LDescription := LGLEntry.Description;
                                InsertActualRow(LDimensionValue, CurrMonth, LGLEntry.Amount, LDescription);
                            until LGLEntry.Next() = 0;

                        // Hareketi olmayan aylar için boş satır
                        CurrMonth := CalcDate('<-CM>', StartDate);
                        while CurrMonth <= LastMonth do begin
                            if not MonthHasRow.ContainsKey(CurrMonth) then begin
                                GetMonthYearText(CurrMonth);
                                InsertActualRow(LDimensionValue, CurrMonth, 0, '');
                            end;
                            CurrMonth := CalcDate('<+1M>', CurrMonth);
                        end;
                    until LAccount.Next() = 0;
            until LDimensionValue.Next() = 0;

        LGLBudgetEntry.SetRange("Budget Name", BudgetName);
        LGLBudgetEntry.SetRange("Date", StartDate, EndDate);
        if LGLBudgetEntry.FindSet() then
            repeat
                GetMonthYearText(LGLBudgetEntry."Date");

                TempVLE.Init();
                i += 1;
                TempVLE."Entry No." := i;
                TempVLE."Posting Date" := LGLBudgetEntry."Date";
                TempVLE."Document No." := LGLBudgetEntry."Budget Dimension 1 Code"; // Bütçe Kodu
                TempVLE.Description := CopyStr(
                    TempVLE."Document No." + '.' + GetBudgetDimensionDescriptionReport(LGLBudgetEntry."Budget Dimension 1 Code", 1),
                    1, MaxStrLen(TempVLE.Description));
                TempVLE."User ID" := CopyStr(GetBudgetDimensionDescription(LGLBudgetEntry."Budget Dimension 1 Code", 2),
                    1, MaxStrLen(TempVLE."User ID"));
                TempVLE."Item No." := LGLBudgetEntry."Budget Name"; // Bütçe Genel Adı
                TempVLE."Cost per Unit" := LGLBudgetEntry.Amount; // Bütçe Tutar
                TempVLE."Cost per Unit (ACY)" := 0; // Gerçekleşen Tutar
                TempVLE."Purchase Amount (Actual)" := 0; // Önceki Yıl Tutar
                TempVLE."Job No." := MonthYearText;
                TempVLE."Job Task No." := CopyStr(GetBudgetDimensionDescription(LGLBudgetEntry."Budget Dimension 1 Code", 3),
                    1, MaxStrLen(TempVLE."Job Task No."));
                TempVLE.Insert();
            until LGLBudgetEntry.Next() = 0;
    end;

    local procedure GetDimension(pDimensionValue: code[20]; pint: Integer) rtnvalue: Text
    var
        LDimensionValue: Record "Dimension Value";
    begin
        LDimensionValue.Init();
        case pint of
            1:
                LDimensionValue.SetRange("Dimension Code", 'PERSONEL');
            2:
                LDimensionValue.SetRange("Dimension Code", 'ARAÇ');
        end;
        LDimensionValue.SetRange(Code, pDimensionValue);
        if LDimensionValue.FindFirst() then
            rtnvalue := LDimensionValue.Name;
    end;

    local procedure InsertActualRow(var pDimensionValue: Record "Dimension Value"; pMonth: Date; pAmount: Decimal; pDescription: Text)
    begin
        TempVLE.Init();
        i += 1;
        TempVLE."Entry No." := i;
        TempVLE."Posting Date" := pMonth;
        TempVLE."Document No." := pDimensionValue."Code"; // Bütçe Kodu
        TempVLE.Description := CopyStr(
            TempVLE."Document No." + '.' + pDimensionValue.Name, 1, MaxStrLen(TempVLE.Description));
        TempVLE."User ID" := pDimensionValue."Dimension Report Descr_Inc";
        TempVLE."Item No." := pDimensionValue."Dimension Code"; // Bütçe Genel Adı
        TempVLE."Cost per Unit" := 0; // Bütçe Tutar
        TempVLE."Cost per Unit (ACY)" := pAmount; // Gerçekleşen Tutar
        TempVLE."Purchase Amount (Actual)" := 0; // Önceki Yıl Tutar
        TempVLE."Cost Amount (Expected)" := 647443.41;
        TempVLE."Job No." := MonthYearText;
        TempVLE."Job Task No." := pDimensionValue."Dimension Report Code_Inc";
        TempVLE."ITS Deacvt. Reason Desc.-B2F" := pDescription;
        TempVLE.Insert();
    end;

    local procedure LoadDimensionCache()
    var
        LDimensionValue: Record "Dimension Value";
    begin
        TempDimensionCache.Reset();
        TempDimensionCache.DeleteAll();

        LDimensionValue.SetRange("Dimension Code", 'BÜTÇE');
        if LDimensionValue.FindSet() then
            repeat
                TempDimensionCache := LDimensionValue;
                TempDimensionCache.Insert();
            until LDimensionValue.Next() = 0;
    end;

    local procedure GetBudgetDimensionDescriptionReport(pBudgetDimensionCode: Code[20]; pDescName: Integer): Text[100]
    begin
        if TempDimensionCache.Get('BÜTÇE', pBudgetDimensionCode) then
            case pDescName of
                1:
                    exit(TempDimensionCache.Name);
                2:
                    exit(TempDimensionCache."Dimension Report Descr_Inc");
                3:
                    exit(TempDimensionCache."Dimension Report Code_Inc");
            end;
        exit('');
    end;

    local procedure GetBudgetDimensionDescription(pBudgetDimensionCode: Code[20]; pDescName: Integer): Text[100]
    var
        LDimensionValue: Record "Dimension Value";
    begin
        LDimensionValue.Init();
        LDimensionValue.SetRange("Dimension Code", 'BÜTÇE');
        LDimensionValue.SetRange("Code", pBudgetDimensionCode);
        if LDimensionValue.FindFirst() then
            case pDescName of
                1:
                    exit(LDimensionValue.Name);
                2:
                    exit(LDimensionValue."Dimension Report Descr_Inc");
                3:
                    exit(LDimensionValue."Dimension Report Code_Inc");
            end;
        exit('');
    end;

    local procedure GetMonthYearText(pDate: Date)
    var
        LMonth: Integer;
        LYear: Text[2];
    begin
        LMonth := Date2DMY(pDate, 2);
        LYear := Format(Date2DMY(pDate, 3) MOD 100);

        case LMonth of
            1:
                MonthYearText := LYear + '.01-Ocak';
            2:
                MonthYearText := LYear + '.02-Şubat';
            3:
                MonthYearText := LYear + '.03-Mart';
            4:
                MonthYearText := LYear + '.04-Nisan';
            5:
                MonthYearText := LYear + '.05-Mayıs';
            6:
                MonthYearText := LYear + '.06-Haziran';
            7:
                MonthYearText := LYear + '.07-Temmuz';
            8:
                MonthYearText := LYear + '.08-Ağustos';
            9:
                MonthYearText := LYear + '.09-Eylül';
            10:
                MonthYearText := LYear + '.10-Ekim';
            11:
                MonthYearText := LYear + '.11-Kasım';
            12:
                MonthYearText := LYear + '.12-Aralık';
        end;

    end;

    local procedure DimensionGLEntryInsert(pDimensionValue: Code[20]; pAccountNo: Code[20]; pPostingDate: Date; var pDescription: Text[100]; pDetailDescription: Option "Description","Vehicle Code","Employee Code"): Decimal
    var
        LGLEntry: Record "G/L Entry";
    begin
        if pAccountNo = '' then
            LGLEntry.SetFilter("G/L Account No.", '7*' + pDimensionValue)
        else
            LGLEntry.SetRange("G/L Account No.", pAccountNo);
        LGLEntry.SetFilter("Posting Date", '..%1', pPostingDate);

        LGLEntry.CalcSums(Amount);
        exit(LGLEntry.Amount);
    end;

    local procedure GetLastBudgetEntry(pBudgetDimensionCode: Code[20]; pBudgetDate: date): Decimal
    var
        LLastBudgetEntry: Record "Last Budget Buffer Data_Inc";
        LDate: Date;
    begin
        LDate := CalcDate('<-1Y>', pBudgetDate);
        LLastBudgetEntry.Init();
        LLastBudgetEntry.SetRange("Dimension Code", pBudgetDimensionCode);
        LLastBudgetEntry.Setfilter("Posting Date", '%1..%2', CalcDate('<-CM>', LDate), CalcDate('<-CM>', LDate));
        if LLastBudgetEntry.FindSet() then begin
            LLastBudgetEntry.CalcSums(Amount);
            exit(LLastBudgetEntry.Amount);
        end else
            exit(0);
    end;

    var
        TempDimensionCache: Record "Dimension Value" temporary;
        i: Integer;
        StartDate: Date;
        EndDate: Date;
        ReportDate: Date;
        BudgetName: code[10];
        MonthYearText: Text[20];

}