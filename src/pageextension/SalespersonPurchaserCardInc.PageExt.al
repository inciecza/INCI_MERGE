pageextension 70833 "Salesperson/Purchaser Card_Inc" extends "Salesperson/Purchaser Card"
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
