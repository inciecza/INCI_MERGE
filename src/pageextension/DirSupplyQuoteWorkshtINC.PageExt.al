pageextension 70806 "Dir. Supply Quote Worksht.-INC" extends "Dir. Supply Quote Worksht.-INC"
{
    actions
    {
        addlast(Processing)
        {
            action(PurchaseOrderDT_Inc)
            {
                ApplicationArea = All;
                Caption = 'Bid Sales Quote DT';
                Image = Report;

                trigger OnAction()
                var
                    LBidSalesQuote: report "Bid Sales Quote DT_Inc";
                begin
                    Clear(LBidSalesQuote);
                    LBidSalesQuote.SetParameters(Rec."Bid No.", Rec."Sell-to Customer No.");
                    LBidSalesQuote.Run();

                end;
            }
        }
    }
}
