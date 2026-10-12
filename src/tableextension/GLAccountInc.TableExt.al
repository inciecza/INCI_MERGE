tableextension 70805 "G/L Account_Inc" extends "G/L Account"
{
    fields
    {
        field(70800; "Budget Code_Inc"; Code[20])
        {
            Caption = 'Budget Code';
            DataClassification = ToBeClassified;
        }
    }
}
