// =============================================================
// Page : Joker Cari Satislar API_Inc_Inc_Inc_Inc
// Tip  : API Page (OData / REST)
// ID   : 50100
//
// Endpoint (örnek):
//   GET https://<bc-host>/api/joker/satislar/v1.0/
//          companies(<companyId>)/cariSatislar
//
// Yıl parametresi (OData $filter):
//   ?$filter=yil eq 2025        → 2025 yılı verisi
//   (filtre yoksa → mevcut yıl kullanılır)
//
// Kaynak tablolar (BC standart):
//   - "Sales Invoice Header"  (Table 112) — IRSTARIH, SEVKUNITE, SEVKUNITECODE
//   - "Sales Invoice Line"    (Table 113) — CODE, NAME, ADETMIKTAR (Quantity)
//
// (GB) mantığı:
//   SP'deki UNION mantığını birebir taklit eder:
//   Ship-to Name içinde "(GB)" varsa ek silinir, yoksa aynen alınır.
//   Her iki durumda da kayıt dahil edilir.
//
// Gruplama anahtarı: Yil + MalzemeKodu + HastaneKodu
// Sıralama         : ToplamSatisMiktari DESC  (ORDER BY Miktar DESC ile uyumlu)
// =============================================================
//
page 70802 "Joker Cari Satislar API"
{
    PageType = API;
    APIPublisher = 'joker';
    APIGroup = 'satislar';
    APIVersion = 'v1.0';
    EntityName = 'cariSatis';
    EntitySetName = 'cariSatislar';

    SourceTable = "Joker Cari Satislar Buffer_Inc";
    SourceTableTemporary = true;
    //ODataKeyFields = "Entry No.";

    Caption = 'Joker Cari Satislar API';
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(yil; Rec."Yil")
                {
                    Caption = 'yil';
                    ApplicationArea = All;
                }
                field(malzemeAdi; Rec."Malzeme Adi")
                {
                    Caption = 'malzemeAdi';
                    ApplicationArea = All;
                }
                field(malzemeKodu; Rec."Malzeme Kodu")
                {
                    Caption = 'malzemeKodu';
                    ApplicationArea = All;
                }
                field(hastaneAdi; Rec."Hastane Adi")
                {
                    Caption = 'hastaneAdi';
                    ApplicationArea = All;
                }
                field(hastaneKodu; Rec."Hastane Kodu")
                {
                    Caption = 'hastaneKodu';
                    ApplicationArea = All;
                }
                field(toplamSatisMiktari; Rec."Toplam Satis Miktari")
                {
                    Caption = 'toplamSatisMiktari';
                    ApplicationArea = All;
                }
                field(ocak; Rec."Ocak")
                {
                    Caption = 'ocak';
                    ApplicationArea = All;
                }
                field(subat; Rec."Subat")
                {
                    Caption = 'subat';
                    ApplicationArea = All;
                }
                field(mart; Rec."Mart")
                {
                    Caption = 'mart';
                    ApplicationArea = All;
                }
                field(nisan; Rec."Nisan")
                {
                    Caption = 'nisan';
                    ApplicationArea = All;
                }
                field(mayis; Rec."Mayis")
                {
                    Caption = 'mayis';
                    ApplicationArea = All;
                }
                field(haziran; Rec."Haziran")
                {
                    Caption = 'haziran';
                    ApplicationArea = All;
                }
                field(temmuz; Rec."Temmuz")
                {
                    Caption = 'temmuz';
                    ApplicationArea = All;
                }
                field(agustos; Rec."Agustos")
                {
                    Caption = 'agustos';
                    ApplicationArea = All;
                }
                field(eylul; Rec."Eylul")
                {
                    Caption = 'eylul';
                    ApplicationArea = All;
                }
                field(ekim; Rec."Ekim")
                {
                    Caption = 'ekim';
                    ApplicationArea = All;
                }
                field(kasim; Rec."Kasim")
                {
                    Caption = 'kasim';
                    ApplicationArea = All;
                }
                field(aralik; Rec."Aralik")
                {
                    Caption = 'aralik';
                    ApplicationArea = All;
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────
    // OnOpenPage: API çağrıldığında tetiklenir.
    // OData filtresi varsa önce okunur, sonra buffer doldurulur.
    // ─────────────────────────────────────────────────────────
    trigger OnOpenPage()
    begin
        PopulateBuffer();
    end;

    // ─────────────────────────────────────────────────────────
    // PopulateBuffer
    // Sales Invoice Header (Posting Date yıla göre) üzerinde
    // döner; her başlık için Item tipindeki satırları okur,
    // gruplama + pivot hesabını yapar ve sonucu Rec'e yazar.
    // ─────────────────────────────────────────────────────────
    local procedure PopulateBuffer()
    var
        SalesInvHeader: Record "Sales Invoice Header";
        SalesInvLine: Record "Sales Invoice Line";
        Buf: Record "Joker Cari Satislar Buffer_Inc" temporary;
        YilFilterTxt: Text;
        FilterYil: Integer;
        StartDate: Date;
        EndDate: Date;
        PostingMonth: Integer;
        NormalizedName: Text[100];
        EntryNo: Integer;
    begin
        // ── 1. Yıl filtresini belirle ─────────────────────────
        // Kullanıcı ?$filter=yil eq 2025 gönderirse BC bu filtreyi
        // OnOpenPage'den önce Rec üzerine SetFilter ile uygular.
        YilFilterTxt := Rec.GetFilter(Rec."Yil");
        if YilFilterTxt <> '' then begin
            if not Evaluate(FilterYil, YilFilterTxt) then
                FilterYil := Date2DMY(Today, 3);   // parse hatasında mevcut yıl
        end else
            FilterYil := Date2DMY(Today, 3);        // filtre yoksa mevcut yıl

        StartDate := DMY2Date(1, 1, FilterYil);
        EndDate := DMY2Date(31, 12, FilterYil);
        // ── 2. Sales Invoice Header'ları yıla göre filtrele ──
        // (Tüm satırları taramak yerine sadece ilgili yıl okunur → performans)
        SalesInvHeader.SetRange("Posting Date", StartDate, EndDate);
        if not SalesInvHeader.FindSet() then
            exit;

        repeat
            PostingMonth := Date2DMY(SalesInvHeader."Posting Date", 2);

            // ── 3. (GB) normalizasyonu ────────────────────────
            // SP mantığı:
            //   REPLACE(SEVKUNITE, '(GB)', '')  → (GB) eki silinir
            //   Her iki UNION kolu da dahil edilir (filtre yok, sadece isim normalize edilir)
            NormalizedName :=
                CopyStr(
                    SalesInvHeader."Ship-to Name".Replace('(GB)', '').TrimEnd(),
                    1, MaxStrLen(Buf."Hastane Adi")
                );

            // Ship-to Name boşsa Sell-to Customer Name kullan
            if NormalizedName = '' then
                NormalizedName := CopyStr(
                    SalesInvHeader."Sell-to Customer Name",
                    1, MaxStrLen(Buf."Hastane Adi")
                );

            // ── 4. Fatura satırlarını oku (sadece Malzeme) ────
            SalesInvLine.SetRange("Document No.", SalesInvHeader."No.");
            SalesInvLine.SetRange(Type, SalesInvLine.Type::Item);
            SalesInvLine.SetFilter("No.", '<>%1', '');

            if SalesInvLine.FindSet() then
                repeat

                    // ── 5. Buffer'da mevcut grup var mı? ──────
                    // Gruplama anahtarı: Yil + MalzemeKodu + HastaneKodu
                    Buf.Reset();
                    Buf.SetRange("Yil", FilterYil);
                    Buf.SetRange("Malzeme Kodu", SalesInvLine."No.");
                    Buf.SetRange("Hastane Kodu", SalesInvHeader."Sell-to Customer No.");
                    //
                    // Not: HastaneKodu için "Sell-to Customer No." kullanıldı.
                    // Uygulamanızda "Ship-to Code" veya özel bir alan
                    // (örn. SalesInvHeader."VAT Registration No.") kullanılıyorsa
                    // aşağıdaki satırı ve alanı güncelleyin.
                    //

                    if not Buf.FindFirst() then begin
                        // Yeni grup → Insert
                        EntryNo += 1;
                        Buf.Init();
                        Buf."Entry No." := EntryNo;
                        Buf."Yil" := FilterYil;
                        Buf."Malzeme Kodu" := SalesInvLine."No.";
                        Buf."Malzeme Adi" := CopyStr(SalesInvLine.Description, 1, MaxStrLen(Buf."Malzeme Adi"));
                        Buf."Hastane Adi" := NormalizedName;
                        Buf."Hastane Kodu" := SalesInvHeader."Sell-to Customer No.";
                        Buf.Insert();
                    end;

                    // ── 6. Aylık pivot: ilgili aya miktar ekle ─
                    AddMonthlyQty(Buf, PostingMonth, SalesInvLine.Quantity);

                    // Toplam da güncelle
                    Buf."Toplam Satis Miktari" += SalesInvLine.Quantity;
                    Buf.Modify();

                until SalesInvLine.Next() = 0;

        until SalesInvHeader.Next() = 0;

        // ── 7. Buffer → Rec aktarımı (Toplam DESC sıralı) ────
        // ORDER BY Miktar DESC  → SP ile uyumlu
        Buf.Reset();
        Buf.SetCurrentKey("Toplam Satis Miktari");
        Buf.Ascending(false);
        if Buf.FindSet() then
            repeat
                Rec := Buf;
                Rec.Insert();
            until Buf.Next() = 0;
    end;

    // ─────────────────────────────────────────────────────────
    // AddMonthlyQty
    // Verilen ay numarasına göre buffer kaydının ilgili alanına
    // miktarı ekler. CASE WHEN Ay = N THEN Miktar mantığı.
    // ─────────────────────────────────────────────────────────
    local procedure AddMonthlyQty(
        var Buf: Record "Joker Cari Satislar Buffer_Inc" temporary;
        Month: Integer;
        Qty: Decimal)
    begin
        case Month of
            1:
                Buf."Ocak" += Qty;
            2:
                Buf."Subat" += Qty;
            3:
                Buf."Mart" += Qty;
            4:
                Buf."Nisan" += Qty;
            5:
                Buf."Mayis" += Qty;
            6:
                Buf."Haziran" += Qty;
            7:
                Buf."Temmuz" += Qty;
            8:
                Buf."Agustos" += Qty;
            9:
                Buf."Eylul" += Qty;
            10:
                Buf."Ekim" += Qty;
            11:
                Buf."Kasim" += Qty;
            12:
                Buf."Aralik" += Qty;
        end;
    end;
}
