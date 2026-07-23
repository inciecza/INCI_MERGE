table 70800 "Separate Invoice Creation_Inc"
{
    Caption = 'Separate Invoice Creation';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Entry No"; Integer)
        {
            Caption = 'Entry No';
            AutoIncrement = true;
        }
        field(2; "Document Type"; Code[20])
        {
            Caption = 'Document Type';
            TableRelation = "Order/Document Type-B2F"
        where(Area = const(Sales));
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            OptionMembers = "Item","Vendor","Warehouse Class";
        }
        field(4; "Type No"; Code[20])
        {
            Caption = 'Type No';
        }
        field(5; "Type Description"; Text[100])
        {
            Caption = 'Type Description';
        }
    }
    keys
    {
        key(PK; "Entry No")
        {
            Clustered = true;
        }
    }
    trigger OnInsert()
    var
        pcode: Code[20];
    begin
        //SalesLine."Order/Document Type-B2F"::
    end;

    var
        SalesLine: Record "Sales Line";

}
