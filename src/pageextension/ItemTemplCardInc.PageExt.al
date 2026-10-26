pageextension 70828 "Item Templ. Card_Inc" extends "Item Templ. Card"
{
    layout
    {
        addafter("Item Category Code")
        {
            field("Include In ITS Integration-INC_Inc"; Rec."Include In ITS Integration-INC")
            {
                ApplicationArea = All;
            }
            field("ITS Item Type-INC_Inc"; Rec."ITS Item Type-INC")
            {
                ApplicationArea = All;
            }


        }
        addafter("Item Tracking Code")
        {
            field("Serial Tracking-INC_Inc"; Rec."Serial Tracking-INC")
            {
                ApplicationArea = All;
            }

        }
    }
}
