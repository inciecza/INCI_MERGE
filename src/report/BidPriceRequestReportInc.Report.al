report 70800 "Bid Price Request Report_Inc"
{
    ApplicationArea = All;
    Caption = 'Bid Price Request Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Bid Price Request Report.rdlc';
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
            column(BidLineNo; NewCreateBidLineNo("Bid Line No."))
            {
            }
            column(Barcode; Getbarcode(Barcode))
            {
            }
            column(PurchaseUnitofMeasure; "Purchase Unit of Measure")
            {
            }
            column(Quantity; Quantity)
            {
            }
            column(Item_Description; "Item Description")
            {
            }
            column(Item_Manufacturer; GetManufacturerName(BidPurchaseRequestLineINC."Item No."))
            {
            }
            dataitem("Bid Header-INC"; "Bid Header-INC")
            {
                DataItemLinkReference = BidPurchaseRequestLineINC;
                DataItemLink = "No." = FIELD("Bid No.");

                column(No_; "Bid Registration No.")
                {
                }
                column(Description; "Bid Name")
                {
                }
                column(Sell_to_Customer_Name; "Sell-to Customer Name")
                {

                }
                column(Bid_Date_Hour; "Bid Date-Hour")
                {
                }
                column(Price_Diff__Will_be_Applied; "Price Diff. Will be Applied")
                {

                }
                column(Shipping_Advice; "Shipping Advice")
                {

                }
                column(Sozlesme_Bitis; "Contract Ending Date")
                {

                }
                column(Gecikme_Cezası_Oranı; CreateText("Delay Penalty Rate"))
                {
                }

                column(DMO; DMO)
                {
                }

            }
            trigger OnPreDataItem()
            begin
                SetRange("Bid No.", GeneralBidNo);
                SetRange("Vendor No.", VendorNo);
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
    procedure SetBidNo(pBidNo: Code[20]; pVendorNo: Code[20]; pDMO: Integer)
    begin
        GeneralBidNo := pBidNo;
        VendorNo := pVendorNo;
        DMO := pDMO;
    end;

    local procedure GetManufacturerName(pNo: code[20]): Text[100]
    var
        LItem: record Item;
        LManufac: record "Manufacturer";
    begin
        Clear(LItem);
        if LItem.Get(pNo) then
            if LItem."Manufacturer Code" <> '' then begin
                if LManufac.Get(LItem."Manufacturer Code") then
                    exit(LManufac.Name);
            end;
        exit('');

    end;

    local procedure NewCreateBidLineNo(pInt: Integer): Integer
    begin
        if pInt <> 0 then
            pInt := pInt / 1000;
        exit(pInt);
    end;

    local procedure CreateText(pText: Text[100]) rtnvalue: Text[100]
    begin
        rtnvalue := 'Teslim Edilemeyen Kısım Üzerinden ' + pText;
    end;

    local procedure GetBarcode(pBarcode: text[50]): Text[50]
    begin
        exit(CopyStr(pBarcode, 2, 13));
    end;

    var
        GeneralBidNo: Code[20];
        GeneralBidName: Text[100];
        VendorNo: code[20];
        DMO: Integer;


}
