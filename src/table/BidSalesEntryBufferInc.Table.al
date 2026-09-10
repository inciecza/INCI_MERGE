table 70802 "Bid Sales Entry Buffer_Inc"
{
    Caption = 'İhale Satış Hareketi', locked = true;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Sıra No.', locked = true;
        }
        field(2; "Order Year"; Integer)
        {
            Caption = 'Sipariş Yıl', locked = true;
        }
        field(3; "Order Month"; Integer)
        {
            Caption = 'Sipariş Ay', locked = true;
        }
        field(4; "Order Status"; Text[50])
        {
            Caption = 'Sipariş Durumu', locked = true;
        }
        field(5; "Document Date"; Date)
        {
            Caption = 'Fiş Tarihi', locked = true;
        }
        field(6; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Chs Ünvanı', locked = true;
        }
        field(7; "Ship-to Name"; Text[100])
        {
            Caption = 'Sevk Firma', locked = true;
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Ambar', locked = true;
            TableRelation = Location;
        }
        field(9; "Ship-to City"; Text[30])
        {
            Caption = 'Sevk Şehir', locked = true;
        }
        field(10; "Manufacturer Name"; Text[100])
        {
            Caption = 'Üretici', locked = true;
        }
        field(11; "Shrink Pack Qty"; Decimal)
        {
            Caption = 'Ambalaj İçi Miktarı', locked = true;
            DecimalPlaces = 0 : 5;
        }
        field(12; "Description 1"; Text[100])
        {
            Caption = 'Açıklama 1', locked = true;
        }
        field(13; GTIN; Code[20])
        {
            Caption = 'Barkod', locked = true;
        }
        field(14; "Item Description"; Text[100])
        {
            Caption = 'Stok Adı', locked = true;
        }
        field(15; "Order Total Qty"; Decimal)
        {
            Caption = 'Sipariş Toplamı', locked = true;
            DecimalPlaces = 0 : 5;
        }
        field(16; "Shipped Qty"; Decimal)
        {
            Caption = 'Sevk Edilen', locked = true;
            DecimalPlaces = 0 : 5;
        }
        field(17; "Outstanding Qty"; Decimal)
        {
            Caption = 'Bekleyen', locked = true;
            DecimalPlaces = 0 : 5;
        }
        field(18; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Birim', locked = true;
        }
        field(19; "Description 2"; Text[50])
        {
            Caption = 'Açıklama 2', locked = true;
        }
        field(20; "Bid Registration No."; Code[20])
        {
            Caption = 'İhale Kayıt No', locked = true;
        }
        field(21; "Delivery Date"; Date)
        {
            Caption = 'Teslim Tarihi', locked = true;
        }
        field(22; "Order Amount"; Decimal)
        {
            Caption = 'Sipariş Tutarı', locked = true;
            AutoFormatType = 1;
        }
        field(23; "Contract Ending Date"; Date)
        {
            Caption = 'Sözleşme Bitiş Tarihi', locked = true;
        }
        field(24; "Bid Date"; DateTime)
        {
            Caption = 'İhale Tarihi', locked = true;
        }
        field(25; "Payment Terms Code"; Code[10])
        {
            Caption = 'Vade', locked = true;
            TableRelation = "Payment Terms";
        }
        field(26; "Document No."; Text[100])
        {
            Caption = 'Belge No', locked = true;
        }
        field(27; "Unit Price"; Decimal)
        {
            Caption = 'Fiyat', locked = true;
            AutoFormatType = 2;
        }
        field(28; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Maliyet', locked = true;
            AutoFormatType = 2;
        }
        field(29; "Source Type"; Option)
        {
            Caption = 'Kaynak Tipi', locked = true;
            OptionMembers = " ",Order,Invoice;
        }
        field(30; "Source Document No."; Code[20])
        {
            Caption = 'Kaynak Belge No', locked = true;
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
