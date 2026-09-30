table 70803 "Last Budget Buffer Data_Inc"
{
    Caption = 'Last Budget Buffer Data';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(4; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(5; "Entry No"; Integer)
        {
            Caption = 'Entry No';
            AutoIncrement = true;
        }
    }
    keys
    {
        key(PK; "Entry No")
        {
            Clustered = true;
        }
    }
}
