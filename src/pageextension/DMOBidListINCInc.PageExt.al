pageextension 70818 "DMO Bid List-INC_Inc" extends "DMO Bid List-INC"
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("Bid Final Total_Inc"; Rec."Bid Final Total_Inc")
            {
            }
        }
    }
}
