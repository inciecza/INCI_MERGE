pageextension 70828 "Chart of Accounts_Inc" extends "Chart of Accounts"
{
    layout
    {
        addafter(Name)
        {
            field("Budget Code_Inc"; Rec."Budget Code_Inc")
            {
                ApplicationArea = All;
            }
        }
    }
}
