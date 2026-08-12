pageextension 70812 "Sales Quote Subform2_Inc" extends "Sales Quote Subform"
{
    actions
    {
        modify(ItemDataImport_Inc)
        {
            trigger OnAfterAction()
            var
                LSalesLine: Record "Sales Line";
                LInciGenSetup: Record "Inci General Setup_Inc";
            begin
                Clear(LInciGenSetup);
                LInciGenSetup.Get();
                Clear(LSalesLine);
                LSalesLine.SetRange("Document Type", Rec."Document Type");
                LSalesLine.SetRange("Document No.", Rec."Document No.");
                LSalesLine.SetRange("No.", LInciGenSetup."Cust Quote Template Default No");
                if LSalesLine.FindSet() then
                    repeat
                        LSalesLine.LostINC := true;
                        LSalesLine."Reason CodeINC" := '2';
                        LSalesLine.Modify();
                    until LSalesLine.Next() = 0;
                CurrPage.Update();
            end;
        }
        modify(ItemDataExport_Inc)
        {
            trigger OnAfterAction()
            var
                LSalesQuoteReport: Report "Sales Quote Export Report2_Inc";
            begin
                Clear(LSalesQuoteReport);
                LSalesQuoteReport.SetParameters(Rec."Sell-to Customer No.", Rec."Document No.", 1);
                LSalesQuoteReport.Run();
            end;
        }

    }
}
