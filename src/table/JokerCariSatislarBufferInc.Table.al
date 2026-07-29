// =============================================================
// Table: Joker Cari Satislar Buffer
// Amaç : API Page'in geçici (temporary) veri kaynağı.
//        Sales Invoice Header + Line tablolarından okunan
//        veriler burada aylık pivot olarak tutulur.
// ID   : 50100
// =============================================================
table 70801 "Joker Cari Satislar Buffer_Inc"
{
    Caption = 'Joker Cari Satislar Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        // ── Birincil anahtar ─────────────────────────────────
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }

        // ── Boyutlar ─────────────────────────────────────────
        field(2; Yil; Integer)
        {
            Caption = 'Yıl';
            DataClassification = CustomerContent;
        }
        field(3; "Malzeme Adi"; Text[250])
        {
            // Sales Invoice Line."Description"
            Caption = 'Malzeme Adı';
            DataClassification = CustomerContent;
        }
        field(4; "Malzeme Kodu"; Code[20])
        {
            // Sales Invoice Line."No."  (Item No.)
            Caption = 'Malzeme Kodu';
            DataClassification = CustomerContent;
        }
        field(5; "Hastane Adi"; Text[100])
        {
            // Sales Invoice Header."Ship-to Name"  [(GB) ekisi temizlenerek]
            // Boşsa: Sales Invoice Header."Sell-to Customer Name"
            Caption = 'Hastane Adı';
            DataClassification = CustomerContent;
        }
        field(6; "Hastane Kodu"; Code[20])
        {
            // Sales Invoice Header."Sell-to Customer No."
            // Not: Kendi uygulamanızda başka bir alan kullanılıyorsa
            //      (örn. Ship-to Code) burası düzenlenebilir.
            Caption = 'Hastane Kodu';
            DataClassification = CustomerContent;
        }

        // ── Özet miktar ──────────────────────────────────────
        field(7; "Toplam Satis Miktari"; Decimal)
        {
            Caption = 'Toplam Satış Miktarı';
            DataClassification = CustomerContent;
        }

        // ── Aylık pivot alanları ─────────────────────────────
        field(8; Ocak; Decimal)
        {
            Caption = 'Ocak';
            DataClassification = CustomerContent;
        }
        field(9; Subat; Decimal)
        {
            Caption = 'Şubat';
            DataClassification = CustomerContent;
        }
        field(10; Mart; Decimal)
        {
            Caption = 'Mart';
            DataClassification = CustomerContent;
        }
        field(11; Nisan; Decimal)
        {
            Caption = 'Nisan';
            DataClassification = CustomerContent;
        }
        field(12; Mayis; Decimal)
        {
            Caption = 'Mayıs';
            DataClassification = CustomerContent;
        }
        field(13; Haziran; Decimal)
        {
            Caption = 'Haziran';
            DataClassification = CustomerContent;
        }
        field(14; Temmuz; Decimal)
        {
            Caption = 'Temmuz';
            DataClassification = CustomerContent;
        }
        field(15; Agustos; Decimal)
        {
            Caption = 'Ağustos';
            DataClassification = CustomerContent;
        }
        field(16; Eylul; Decimal)
        {
            Caption = 'Eylül';
            DataClassification = CustomerContent;
        }
        field(17; Ekim; Decimal)
        {
            Caption = 'Ekim';
            DataClassification = CustomerContent;
        }
        field(18; Kasim; Decimal)
        {
            Caption = 'Kasım';
            DataClassification = CustomerContent;
        }
        field(19; Aralik; Decimal)
        {
            Caption = 'Aralık';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        // Birincil anahtar
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        // Gruplama araması için bileşik anahtar
        key(GroupKey; "Yil", "Malzeme Kodu", "Hastane Kodu") { }
        // Sıralama: Toplam Miktara göre DESC (SP ile uyumlu)
        key(SortKey; "Toplam Satis Miktari") { }
    }
}
