pageextension 70832 "Salespersons/Purchasers_Inc" extends "Salespersons/Purchasers"
{
    layout
    {
        addafter(Name)
        {
            field("Customer Region Code_Inc"; Rec."Customer Region Code_Inc")
            {
                ApplicationArea = All;
            }
        }
    }
}
