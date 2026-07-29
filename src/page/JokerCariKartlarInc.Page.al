page 70800 "Joker_Cari_Kartlar_Inc"
{
    APIGroup = 'apiGroup';
    APIPublisher = 'InciEcza';
    APIVersion = 'v1.0';
    ApplicationArea = All;
    Caption = 'jokerCariKartlar';
    DelayedInsert = true;
    EntityName = 'Joker';
    EntitySetName = 'Cari_Kartlar';
    PageType = API;
    SourceTable = Customer;
    Permissions = TableData Customer = R;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(customerOldCodeInc; CustomerOldCodeIncValue)
                {
                    Caption = 'Customer Old Code';
                }
                field(name2; Rec."Name 2")
                {
                    Caption = 'Name 2';
                }
                field(city; Rec.City)
                {
                    Caption = 'City';
                }
                field(gln; Rec.GLN)
                {
                    Caption = 'GLN';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec."Customer Old Code_Inc" = '' then
            CustomerOldCodeIncValue := Rec."No."
        else
            CustomerOldCodeIncValue := Rec."Customer Old Code_Inc";
    end;

    var
        CustomerOldCodeIncValue: Code[20];
}