pageextension 70822 "PTS Whse Rcpt Lines-B2F_Inc" extends "PTS Whse Rcpt Lines-B2F"
{

    actions
    {
        addafter(CreateReceipt)
        {
            action(RemoveSelected_Inc)
            {
                ApplicationArea = All;
                Caption = 'Remove Selected';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = RemoveLine;
                trigger OnAction()
                begin
                    Rec.Reset();
                    Rec.SetRange(Selected, true);
                    if Rec.FindSet() then
                        repeat
                            Rec.Selected := false;
                            Rec.Modify();
                        until Rec.Next() = 0;
                    CurrPage.Update();
                end;
            }
        }
    }
}
