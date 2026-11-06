pageextension 70829 "General Ledger Entries2_Inc" extends "General Ledger Entries"
{
    layout
    {
        addafter("Document No.")
        {
            field("Source Description-B2F_Inc"; Rec."Source Description-B2F")
            {
                ApplicationArea = All;
            }

        }
    }
}
