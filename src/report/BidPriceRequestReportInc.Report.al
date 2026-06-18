report 70800 "Bid Price Request Report_Inc"
{
    ApplicationArea = All;
    Caption = 'Bid Price Request Report';
    UsageCategory = ReportsAndAnalysis;
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
    local procedure SetParametres(pBidNo: Code[20])
    begin
        GeneralBidNo := pBidNo;
    end;


    var
        GeneralBidNo: Code[20];

}
