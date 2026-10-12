pageextension 70826 "G/L Account Card_Inc" extends "G/L Account Card"
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
