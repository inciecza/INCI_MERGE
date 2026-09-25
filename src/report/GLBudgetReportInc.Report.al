report 70819 "G/L Budget Report_Inc"
{
    ApplicationArea = All;
    Caption = 'G/L Budget Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/GL Budget Report.rdlc';
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
            StartDate := 20260701D;
            EndDate := 20260731D;
            BudgetName := 'INC BÜTÇE';


        end;
    }


    local procedure FillTempVLE()
    var
        LGLBudgetEntry: Record "G/L Budget Entry";
        LDimensionValue: Record "Dimension Value";
        CurrMonth: Date;
        LastMonth: Date;
    begin
        Clear(TempVLE);
        if StartDate = 0D then
            error('Start Date cannot be empty. Please select a valid start date.');
        if EndDate = 0D then
            error('End Date cannot be empty. Please select a valid end date.');

        CurrMonth := CalcDate('<-CM>', StartDate); // StartDate'in ayının 1'i
        LastMonth := CalcDate('<-CM>', EndDate);   // EndDate'in ayının 1'i

        LDimensionValue.Init();
        LDimensionValue.SetRange("Dimension Code", 'BÜTÇE');
        LDimensionValue.SetRange(Blocked, false);
        if LDimensionValue.FindSet() then
            repeat
                CurrMonth := CalcDate('<-CM>', StartDate);
                while CurrMonth <= LastMonth do begin
                    TempVLE.Init();
                    i += 1;
                    TempVLE."Entry No." := i;
                    TempVLE."Posting Date" := CurrMonth;
                    TempVLE."Document No." := LDimensionValue."Code"; //Bütçe Kodu
                    TempVLE.Description := TempVLE."Document No." + '.' + LDimensionValue.Name;
                    TempVLE."User ID" := LDimensionValue."Dimension Report Descr_Inc";
                    TempVLE."Item No." := LDimensionValue."Dimension Code"; //Bütçe Genel Adı
                    TempVLE."Cost per Unit" := 0; // Bütçe Tutar
                    TempVLE."Cost per Unit (ACY)" := 0; // Gerçekleşen Tutar
                    TempVLE."Purchase Amount (Actual)" := 0; // Önceki Yıl Tutar
                    TempVLE."Cost Amount (Expected)" := 647443.41;
                    TempVLE."Job No." := GetMonthYearText(CurrMonth);
                    TempVLE.Insert();

                    CurrMonth := CalcDate('<1M>', CurrMonth); // sonraki ayın 1'i
                end;
            until LDimensionValue.Next() = 0;

        LGLBudgetEntry.Init();
        LGLBudgetEntry.SetRange("Budget Name", BudgetName);
        LGLBudgetEntry.SetRange("Date", StartDate, EndDate);
        if LGLBudgetEntry.FindSet() then
            repeat
                TempVLE.Init();
                i += 1;
                TempVLE."Entry No." := i;
                TempVLE."Posting Date" := LGLBudgetEntry."Date";
                TempVLE."Document No." := LGLBudgetEntry."Budget Dimension 1 Code"; //Bütçe Kodu
                TempVLE.Description := TempVLE."Document No." + '.' + GetBudgetDimensionDescription(LGLBudgetEntry."Budget Dimension 1 Code", 1);
                TempVLE."User ID" := GetBudgetDimensionDescription(LGLBudgetEntry."Budget Dimension 1 Code", 2);
                TempVLE."Item No." := LGLBudgetEntry."Budget Name";//Bütçe Genel Adı
                TempVLE."Cost per Unit" := LGLBudgetEntry.Amount; // Bütçe Tutar
                TempVLE."Cost per Unit (ACY)" := 0; // Gerçekleşen Tutar
                TempVLE."Purchase Amount (Actual)" := 0; // Önceki Yıl Tutar
                TempVLE."Job No." := GetMonthYearText(LGLBudgetEntry."Date");
                TempVLE."Job Task No." := GetBudgetDimensionDescription(LGLBudgetEntry."Budget Dimension 1 Code", 3);

                /*TempVLE."User ID" := CopyStr(LGLBudgetEntry."User ID", 1, 50);
                TempVLE."Invoiced Quantity" := LGLBudgetEntry."Quantity"; // Miktar
                TempVLE."Purchase Amount (Actual)" := LGLBudgetEntry."Amount"; // Tutar Kdv Hariç
                TempVLE."External Document No." := CopyStr(LGLBudgetEntry."Responsibility Center", 1, maxStrLen(LGLBudgetEntry."Responsibility Center"));
                */
                TempVLE.Insert();
            until LGLBudgetEntry.Next() = 0;
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
        i: Integer;
        StartDate: Date;
        EndDate: Date;
        BudgetName: code[10];

}