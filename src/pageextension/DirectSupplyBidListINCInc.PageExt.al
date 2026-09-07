pageextension 70816 "Direct Supply Bid List-INC_Inc" extends "Direct Supply Bid List-INC"
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
