pageextension 70831 "Bank Integ. Entries-B2F_Inc" extends "Bank Integ. Entries-B2F"
{
    //editable = true;
    //Editable kısmı açılacak alan bazında editable eklenecek
    //İki tane buton eklenecek birincisi Customer ve Vendor tablolarınına bağlı banka hesaplarını kontrol edip boolean alanı dolduracak.
    //Diğer buton ise durumu yeni olan kayıtlara bakacak, Müşteri ve Atıcı seçilen satırları kontrol edecek. Müşteri doluysa o müşteriye ait banka hesabı oluşturup iban bilgisini
    //Eğer satıcı seçili ise Satıcıya ait banka hesabı oluşturup iban bilgisini dolduracak.
    layout
    {
        addafter(IBAN)
        {
            field("Customer Iban_Inc"; Rec."Customer Iban_Inc")
            {
                ApplicationArea = All;
            }
            field("Customer No._Inc"; Rec."Customer No._Inc")
            {
                ApplicationArea = All;
            }
            field("Vendor No._Inc"; Rec."Vendor No._Inc")
            {
                ApplicationArea = All;
            }
            field("Vendor Iban_Inc"; Rec."Vendor Iban_Inc")
            {
                ApplicationArea = All;
            }
        }

    }
}
