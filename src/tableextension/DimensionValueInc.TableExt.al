tableextension 70804 "Dimension Value_Inc" extends "Dimension Value"
{
    fields
    {
        field(70800; "Dimension Report Descr_Inc"; Text[50])
        {
            Caption = 'Dimension Report Description';
            DataClassification = ToBeClassified;
        }
        field(70801; "Dimension Report Code_Inc"; Text[10])
        {
            Caption = 'Dimension Report Code';
            DataClassification = ToBeClassified;
        }
        field(70802; "Detail Description Type_Inc"; Option)
        {
            OptionMembers = "Description","Vehicle Code","Employee Code";
            OptionCaption = 'Description,Vehicle Code,Employee Code';
        }


    }
}
