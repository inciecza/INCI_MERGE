pageextension 70807 "Open Bid Quote Worksheet-INC" extends "Open Bid Quote Worksheet-INC"
{
    actions
    {
        addlast(Processing)
        {
            action(PurchaseOrderDT_Inc)
            {
                ApplicationArea = All;
                Caption = 'Open Bid Sales Quote';
                Image = Report;

                trigger OnAction()
                var
                    LOpenBidSalesQuote: report "Open Bid Sales Quote_Inc";
                begin
                    Clear(LOpenBidSalesQuote);
                    LOpenBidSalesQuote.SetParameters(Rec."Bid No.", Rec."Sell-to Customer No.");
                    LOpenBidSalesQuote.Run();

                end;
            }
        }
    }


}
