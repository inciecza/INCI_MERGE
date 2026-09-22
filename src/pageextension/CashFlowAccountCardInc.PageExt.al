pageextension 70819 "Cash Flow Account Card" extends "Cash Flow Account Card"
{
    layout
    {
        addlast(General)
        {
            field("Customer Group_Inc"; Rec."Customer Group_Inc")
            {
                ApplicationArea = All;
            }
        }
    }
}
