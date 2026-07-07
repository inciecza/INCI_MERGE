report 70802 "Bid Purchase Order DT_Inc"
{
    ApplicationArea = All;
    Caption = 'Bid Purchase Order DT';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Bid Purchase Order DT.rdlc';
    dataset
    {
        dataitem(BidPurchaseRequestLineINC; "Bid Purchase Request Line-INC")
        {
            column(Vendor_No_; "Vendor No.")
            {
            }
            column(Vendor_Name; "Vendor Name")
            {
            }
            column(IhaleSıraNo; "Bid Line No.")
            {
            }
            column(Barcode; Barcode)
            {
            }
            column(Birimi; "Purchase Unit of Measure")
            {
            }
            column(SiparisMiktari; Quantity)
            {
            }
            column(IlacAdi; "Item Description")
            {
            }
            column(Item_Manufacturer; GetManufacturerName(BidPurchaseRequestLineINC."Item No."))
            {
            }
            column(MaliyetFiyatı; "Line Amount")
            {
            }
            column(CompanyLogo; CompanyInformation.Picture)
            {
            }
            column(TeslimatDeposu; GetShipLocation())
            {

            }
            column(SiparisNo; GetOrderNo(GeneralBidNo, "Line No."))
            {

            }
            dataitem("Bid Header-INC"; "Bid Header-INC")
            {
                DataItemLinkReference = BidPurchaseRequestLineINC;
                DataItemLink = "No." = FIELD("Bid No.");

                column(No_; "No.")
                {
                }
                column(IhaleKayitNo; "Bid Registration No.")
                { }
                column(Description; '')
                {
                }
                column(IhaleYapan; "Sell-to Customer Name")
                {

                }
                column(IhaleTarih; "Bid Date-Hour")
                {
                }
                column(SonTeslimTarihi; "Last Delivery Date")
                {

                }
                column(Price_Diff__Will_be_Applied; "Price Diff. Will be Applied")
                {

                }
                column(Shipping_Advice; "Shipping Advice")
                {

                }

                column(Kullanici; GetUserName(UserId))
                {

                }


            }
            trigger OnPreDataItem()
            begin
                SetRange("Bid No.", GeneralBidNo);
                SetRange("Vendor No.", VendorNo);
                CompanyInformation.Get();
                CompanyInformation.CalcFields(Picture);
            end;
        }

    }
    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                }
            }
        }
        actions
        {
            area(Processing)
            {
            }
        }
    }
    procedure SetParameters(pBidNo: Code[20]; pVendorNo: Code[20])
    begin
        GeneralBidNo := pBidNo;
        VendorNo := pVendorNo;
    end;

    local procedure GetManufacturerName(pNo: code[20]): Text[100]
    var
        LItem: record Item;
    begin
        Clear(LItem);
        if LItem.Get(pNo) then
            exit(LItem."Manufacturer Code");

    end;

    local procedure GetOrderNo(pBidNo: code[20]; pLineNo: Integer): Text
    var
        LBidLineNo: Record "Bid Line-INC";
    begin
        Clear(LBidLineNo);
        LBidLineNo.SetRange("Bid No.", pBidNo);
        LBidLineNo.SetRange("Bid Line No.", pLineNo);
        if LBidLineNo.FindFirst() then
            exit(LBidLineNo."Customer Order No.");

    end;

    local procedure GetShipLocation(): Text
    var
        LBidFAsses: Record "Bid Final-Assessment Line-INC";
    begin

    end;

    local procedure GetUserName(pUserName: Text): Text
    var
        User: Record User;
        UserSecurityId: Guid;
    begin
        if pUserName = '' then
            exit('');
        User.SetRange("User Name", pUserName);
        if User.FindFirst() then
            if User."Full Name" <> '' then
                exit(User."Full Name")
            else
                exit(User."User Name");

        exit('');
    end;

    var
        CompanyInformation: Record "Company Information";
        GeneralBidNo: Code[20];
        VendorNo: Code[20];
        GeneralBidName: Text[100];


}
