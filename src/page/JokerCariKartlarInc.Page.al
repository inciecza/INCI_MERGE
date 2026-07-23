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

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(customerOldCodeInc; Rec."Customer Old Code_Inc")
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
}
