pageextension 70820 "Cash Flow Worksheet_Inc" extends "Cash Flow Worksheet"
{
    layout
    {
        addafter("Cash Flow Date")
        {
            field("Document Date_Inc"; Rec."Document Date")
            {
                ApplicationArea = All;
            }

        }
    }
}
