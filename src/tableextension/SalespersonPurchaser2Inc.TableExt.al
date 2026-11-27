tableextension 70809 "Salesperson/Purchaser2_Inc" extends "Salesperson/Purchaser"
{
    fields
    {
        field(70800; "Customer Region Code_Inc"; Code[20])
        {
            Caption = 'Customer Region Code';
            DataClassification = ToBeClassified;
            TableRelation = "Customer Regions_Inc";
        }
    }
}
