pageextension 70800 "Direct Supply Bid Card-INC_Inc" extends "Direct Supply Bid Card-INC"
{
    layout
    {

    }
    actions
    {
        addlast(Navigation)
        {
            action(PrintBidPriceRequestReport_Inc)
            {
                ApplicationArea = All;
                Caption = 'Print Bid Price Request Report';
                Image = Print;
                trigger OnAction()
                var
                    LBidPriceRequestReport: Report "Bid Price Request Report_Inc";
                begin
                    LBidPriceRequestReport.SetBidNo(Rec."No.");
                    LBidPriceRequestReport.Run();

                end;
            }
        }
    }
}
