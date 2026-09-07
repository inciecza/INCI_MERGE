tableextension 70802 "Bid Header-INC_Inc" extends "Bid Header-INC"
{
    fields
    {
        field(70800; "Bid Final Total_Inc"; Decimal)
        {
            Caption = 'Bid Final Total';
            FieldClass = FlowField;
            calcformula = Sum("Bid Final-Assessment Line-INC"."Total Quote" where("Bid No." = field("No.")));
        }
    }
}
