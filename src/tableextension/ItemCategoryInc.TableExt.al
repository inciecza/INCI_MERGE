tableextension 70801 "Item Category_Inc" extends "Item Category"
{
    fields
    {
        field(70800; "Private hospital_Inc"; Integer)
        {
            Caption = 'Private hospital';
            DataClassification = ToBeClassified;
        }
        field(70801; "DMO Bid_Inc"; Integer)
        {
            Caption = 'DMO Bid';
            DataClassification = ToBeClassified;
        }
        field(70802; "Open Bid_Inc"; Integer)
        {
            Caption = 'Open Bid';
            DataClassification = ToBeClassified;
        }
        field(70803; "Direct Supply Bid_Inc"; Integer)
        {
            Caption = 'Direct Supply Bid';
            DataClassification = ToBeClassified;
        }
    }
}
