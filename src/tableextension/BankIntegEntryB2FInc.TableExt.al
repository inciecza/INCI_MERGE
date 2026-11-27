tableextension 70808 "Bank Integ. Entry-B2F_Inc" extends "Bank Integ. Entry-B2F"
{
    fields
    {
        field(70800; "Customer No._Inc"; Code[20])
        {
            Caption = 'Customer No.';
            DataClassification = ToBeClassified;
            TableRelation = Customer;
            editable = true;
        }
        field(70801; "Vendor No._Inc"; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = ToBeClassified;
            TableRelation = Vendor;
            editable = true;
        }
        field(70802; "Customer Iban_Inc"; boolean)
        {
            Caption = 'CustomerIBAN';
            DataClassification = ToBeClassified;
            editable = false;
        }
        field(70803; "Vendor Iban_Inc"; Boolean)
        {
            Caption = 'Vendor IBAN';
            DataClassification = ToBeClassified;
            editable = false;
        }

    }
}
