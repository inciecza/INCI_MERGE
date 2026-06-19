pageextension 70802 "DMO Bid Card-INC_Inc" extends "DMO Bid Card-INC"
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