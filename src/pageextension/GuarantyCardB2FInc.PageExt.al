pageextension 70801 "Guaranty Card-B2F" extends "Guaranty Card-B2F"
{
    layout
    {
        addafter("Actual Amount (LCY)")
        {
            field("Bid Guaranty_Inc"; REc."Bid Guaranty_Inc")
            {
                ApplicationArea = All;
            }

        }
    }
}
