pageextension 70821 "Dimension Values_Inc" extends "Dimension Values"
{
    layout
    {
        addafter(Name)
        {
            field("Dimension Report Code_Inc"; Rec."Dimension Report Code_Inc")
            {
                ApplicationArea = All;
            }

            field("Dimension Report Descr_Inc"; Rec."Dimension Report Descr_Inc")
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        addlast("F&unctions")
        {
            action(ActionName_Inc)
            {
                ApplicationArea = All;
                Caption = 'Dimension Update';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Dimensions;

                trigger OnAction()
                var
                    LInciGeneral2: Codeunit "InciGeneral2_Inc";
                    LDimensionValue: Record "Dimension Value";
                    LGLEntry: Record "G/L Entry";
                    LDate: Date;
                    LStartDate: Date;
                    LEndDate: Date;

                begin
                    LDate := 20260731D;
                    Clear(LStartDate);
                    Clear(LEndDate);
                    LStartDate := CalcDate('<-CM>', LDate);
                    LEndDate := CalcDate('<CM>', LDate);
                    LDimensionValue.Init();
                    LDimensionValue.SetRange("Dimension Code", Rec."Dimension Code");
                    LDimensionValue.SetFilter("Acc.No.for Prep.Exp/Rev.-B2F", '<>%1', '');
                    if LDimensionValue.FindSet() then
                        repeat
                            LGLEntry.Init();
                            LGLEntry.SetRange("G/L Account No.", LDimensionValue."Acc.No.for Prep.Exp/Rev.-B2F");
                            LGLEntry.SetRange("Posting Date", LStartDate, LEndDate);
                            if LGLEntry.FindSet() then
                                repeat
                                    Clear(LInciGeneral2);
                                    LInciGeneral2.InsertDimSetEntryIfMissing(LDimensionValue."Dimension Code", LDimensionValue."Code", LGLEntry."Entry No.", LGLEntry."Dimension Set ID");
                                until LGLEntry.Next() = 0;
                        until LDimensionValue.Next() = 0;

                    LDimensionValue.Init();
                    LDimensionValue.SetRange("Dimension Code", Rec."Dimension Code");
                    LDimensionValue.Setrange("Acc.No.for Prep.Exp/Rev.-B2F", '');
                    if LDimensionValue.FindSet() then
                        repeat
                            LGLEntry.Init();
                            LGLEntry.SetFilter("G/L Account No.", '7*%1', LDimensionValue."Acc.No.for Prep.Exp/Rev.-B2F");
                            LGLEntry.SetRange("Posting Date", LStartDate, LEndDate);
                            if LGLEntry.FindSet() then
                                repeat
                                    Clear(LInciGeneral2);
                                    LInciGeneral2.InsertDimSetEntryIfMissing(LDimensionValue."Dimension Code", LDimensionValue."Code", LGLEntry."Entry No.", LGLEntry."Dimension Set ID");
                                until LGLEntry.Next() = 0;
                        until LDimensionValue.Next() = 0;
                end;
            }
        }
    }

    var
        LDate: Date;
}
