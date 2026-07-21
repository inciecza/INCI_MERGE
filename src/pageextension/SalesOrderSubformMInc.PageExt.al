pageextension 70809 "Sales Order SubformM_Inc" extends "Sales Order Subform"
{
    actions
    {
        addafter("&Line")
        {
            action(ItemMiad2_Inc)
            {
                ApplicationArea = All;
                Caption = 'Item Miad Location Page';
                Image = Form;
                ShortcutKey = 'Ctrl+F8';

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

                        CurrPage.Update();
                    end;
                end;
            }
        }
    }
}
