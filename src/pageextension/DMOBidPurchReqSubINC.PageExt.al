pageextension 70805 "DMO Bid Purch.Req. Sub.-INC" extends "DMO Bid Purch.Req. Sub.-INC"
{
    actions
    {
        addlast(Processing)
        {
            action(PurchaseOrderDT_Inc)
            {
                ApplicationArea = All;
                Caption = 'Bid Purchase Order DT';
                Image = Report;

                trigger OnAction()
                var
                    LPurchaseReportOpenDMO: report "Bid Purchase Order Open-DMO";
                begin
                    Clear(LPurchaseReportOpenDMO);
                    LPurchaseReportOpenDMO.SetParameters(Rec."Bid No.", Rec."Vendor No.");
                    LPurchaseReportOpenDMO.Run();

                end;
            }
            action(PrintBidPriceRequestReport_Inc)
            {
                ApplicationArea = All;
                Caption = 'Print Bid Price Request Report';
                Image = Print;
                trigger OnAction()
                var
                    LBidPriceRequestReport: Report "Bid Price Request Report_Inc";
                begin
                    LBidPriceRequestReport.SetBidNo(Rec."Bid No.", Rec."Vendor No.");
                    LBidPriceRequestReport.Run();

                end;
            }
        }
    }
}
