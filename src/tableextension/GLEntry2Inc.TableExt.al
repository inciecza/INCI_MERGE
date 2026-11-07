tableextension 70807 "G/L Entry2_Inc" extends "G/L Entry"
{
    fields
    {
        field(70800; "Budget Code_Inc"; Code[20])
        {
            Caption = 'Budget Code';
            FieldClass = FlowField;
            CalcFormula = lookup("G/L Account"."Budget Code_Inc" where("No." = field("G/L Account No.")));
        }
    }
}
