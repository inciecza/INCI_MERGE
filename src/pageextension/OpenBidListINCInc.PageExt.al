pageextension 70817 "Open Bid List-INC_Inc" extends "Open Bid List-INC"
{
    layout
    {
        addafter("Sell-to Customer Name")
        {
            field("Bid Final Total_Inc"; Rec."Bid Final Total_Inc")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Bid Final Total field.';
            }
        }
    }
}
