pageextension 70801 "Open Bid Card-INC" extends "Open Bid Card-INC"
{
    layout
    {

    }
    actions
    {
        addfirst(Navigation)
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