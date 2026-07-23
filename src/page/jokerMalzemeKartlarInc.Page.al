page 70801 "jokerMalzemeKartlar_Inc"
{
    APIGroup = 'apiGroup';
    APIPublisher = 'publisherName';
    APIVersion = 'v1.0';
    ApplicationArea = All;
    Caption = 'jokerMalzemeKartlar';
    DelayedInsert = true;
    EntityName = 'Joker';
    EntitySetName = 'Malzeme_Kartlar';
    PageType = API;
    SourceTable = Item;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(gtin; Rec.GTIN)
                {
                    Caption = 'GTIN';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(manufacturerCode; Rec."Manufacturer Code")
                {
                    Caption = 'Manufacturer Code';
                }
            }
        }
    }
}
