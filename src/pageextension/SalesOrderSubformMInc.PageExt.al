pageextension 70809 "Sales Order SubformM_Inc" extends "Sales Order Subform"
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

        addafter("&Line")
        {
            action(ItemDataExport2_Inc)
            {
                ApplicationArea = All;
                Caption = 'Item Data Export Report';
                Image = Export;

                trigger OnAction()
                var
                    LSalesQuoteReport: Report "Sales Quote Export Report2_Inc";
                begin
                    Clear(LSalesQuoteReport);
                    LSalesQuoteReport.SetParameters(Rec."Sell-to Customer No.", Rec."Document No.", 1);
                    LSalesQuoteReport.Run();
                end;
            }
            action(ItemMiad2_Inc)
            {
                ApplicationArea = All;
                Caption = 'Item Miad Location Page';
                Image = Form;
                ShortcutKey = 'Ctrl+F11';

                trigger OnAction()
                var
                    LItemMiadPage: Page "Item Miad Location Page_Inc";
                    LValueEntry: Record "Value Entry";
                begin
                    Clear(LItemMiadPage);

                    LItemMiadPage.SetParameters(Rec."No.", Rec.Description);
                    LItemMiadPage.LookupMode(true);

                    if LItemMiadPage.RunModal() = Action::LookupOK then begin
                        Clear(LValueEntry);
                        LItemMiadPage.GetRecord(LValueEntry);

                        Rec.Validate("No.", LValueEntry."Item No.");
                        Rec."Requested Exp. Date-B2F" := LValueEntry."Document Date";
                        Rec."Location Code" := LValueEntry."Location Code";
                        CurrPage.Update();
                    end;
                end;
            }
        }
    }
}