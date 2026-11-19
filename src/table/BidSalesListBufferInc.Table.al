table 70804 "Bid Sales List Buffer_Inc"
{
    Caption = 'General Bid List';
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Sıra No.', locked = true;
        }
        field(2; "Bid Class"; Enum "Bid Class-INC")
        {
            Caption = 'İhale Durumu', locked = true;
        }
        field(3; "Bid Year"; Integer)
        {
            Caption = 'Yıl', locked = true;
        }
        field(4; "Bid Month"; Integer)
        {
            Caption = 'Ay', locked = true;
        }
        field(5; "Bid Registration No."; Text[50])
        {
            Caption = 'İhale Kayıt No', locked = true;
        }
        field(6; "Bid Date-Hour"; DateTime)
        {
            Caption = 'İhale Tarihi', locked = true;
        }
        field(7; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Ünite Adı', locked = true;
        }
        field(8; City; Text[30])
        {
            Caption = 'Şehir', locked = true;
        }
        field(9; "Document Line No."; Integer)
        {
            Caption = 'Sıra No', locked = true;
        }
        field(10; "Item No."; Code[20])
        {
            Caption = 'Stok Kodu', locked = true;
        }
        field(11; GTIN; Code[14])
        {
            Caption = 'Barkod', locked = true;
        }
        field(12; "Item Description"; Text[100])
        {
            Caption = 'Stok Adı', locked = true;
        }
        field(13; "Manufacturer Name"; Text[50])
        {
            Caption = 'Üretici', locked = true;
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Miktar', locked = true;
        }
        field(15; "Unit Price"; Decimal)
        {
            Caption = 'Verilen Fiyat', locked = true;
        }
        field(16; "Direct Unit Cost"; Decimal)
        {
            Caption = 'İhale Birim Maliyet', locked = true;
        }
        field(17; "Bid Total Cost"; Decimal)
        {
            Caption = 'İhale Toplam Maliyet', locked = true;
        }
        field(18; "Line Amount"; Decimal)
        {
            Caption = 'Tutar', locked = true;
        }
        field(19; "Competitor Name"; Text[100])
        {
            Caption = 'Rakip Firma', locked = true;
        }
        field(20; "Competitor Unit Price"; Decimal)
        {
            Caption = 'Rakip Fiyat', locked = true;
        }
        field(21; Won; Boolean)
        {
            Caption = 'Kaldı Kalmadı', locked = true;
        }
        field(22; "Active Ingredient"; Text[250])
        {
            Caption = 'Ekap Etken Madde', locked = true;
        }
        field(23; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Müşteri No.', locked = true;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
