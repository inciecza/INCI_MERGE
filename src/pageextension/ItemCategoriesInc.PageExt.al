pageextension 70810 "Item Categories_Inc" extends "Item Categories"
{
    layout
    {
        addafter(Description)
        {
            field("Private hospital_Inc"; Rec."Private hospital_Inc")
            {
                ApplicationArea = All;
            }
            field("DMO Bid_Inc"; Rec."DMO Bid_Inc")
            {
                ApplicationArea = All;
            }

            field("Open Bid_Inc"; Rec."Open Bid_Inc")
            {
                ApplicationArea = All;
            }
            field("Direct Supply Bid_Inc"; Rec."Direct Supply Bid_Inc")
            {
                ApplicationArea = All;
            }

        }
    }
}
