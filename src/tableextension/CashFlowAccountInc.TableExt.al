tableextension 70803 "Cash Flow Account_Inc" extends "Cash Flow Account"
{
    fields
    {
        field(70800; "Customer Group_Inc"; Option)
        {
            Caption = 'Customer Group';
            OptionMembers = " ","Private Hospital","State Hospital","Univertsity Hospital","Pharmaceutical Distributor","Pharmacy","Companies","Export","Group Company","Foundation",DMO;
            OptionCaption = ' ,Private Hospital,State Hospital,Univertsity Hospital,Pharmaceutical Distributor,Pharmacy,Companies,Export,Group Company,Foundation,DMO';
            //OptionCaption = ' ,Özel Hastane,Devlet Hastanesi,Üniversite Hastanesi,Ecza Deposu,Eczane,Firmalar,İhracat,Grup İçi';
            DataClassification = CustomerContent;
        }

    }
}
