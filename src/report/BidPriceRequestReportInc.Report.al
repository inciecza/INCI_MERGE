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
            column(BidLineNo; "Bid Line No.")
            {
            }
            column(Barcode; Barcode)
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

                column(No_; "No.")
                {
                }
                column(Description; '')
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
    procedure SetBidNo(pBidNo: Code[20]; pVendorNo: Code[20])
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

    var
        GeneralBidNo: Code[20];
        GeneralBidName: Text[100];
        VendorNo: code[20];


}
