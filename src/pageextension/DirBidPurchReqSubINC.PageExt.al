pageextension 70803 "Dir. Bid Purch.Req. Sub.-INC" extends "Dir. Bid Purch.Req. Sub.-INC"
{
    layout
    {

    }
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
                    LPurchaseReportDT: report "Bid Purchase Order DT_Inc";
                begin
                    Clear(LPurchaseReportDT);
                    LPurchaseReportDT.SetParameters(Rec."Bid No.", Rec."Vendor No.");
                    LPurchaseReportDT.Run();

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
