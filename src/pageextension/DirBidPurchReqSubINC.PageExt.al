pageextension 70803 "Dir. Bid Purch.Req. Sub.-INC" extends "Dir. Bid Purch.Req. Sub.-INC"
{
    layout
    {

    }
    actions
    {
        addfirst(Processing)
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
        }
    }
}
