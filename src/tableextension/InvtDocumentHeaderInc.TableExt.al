tableextension 70806 "Invt. Document Header_Inc" extends "Invt. Document Header"
{
    fields
    {
        field(70800; "Invt Ship Acc. Mang. App._Inc"; Boolean)
        {
            Caption = 'Stock Inventory Account Manager Approve';
            DataClassification = ToBeClassified;
        }
        field(70801; "Invt Ship Mang. App._Inc"; Boolean)
        {
            Caption = 'Stock Inventory Manager Approve';
            DataClassification = ToBeClassified;
        }
    }
}
