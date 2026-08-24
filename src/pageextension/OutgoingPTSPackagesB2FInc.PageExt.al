pageextension 70813 "Outgoing PTS Packages-B2F_Inc" extends "Outgoing PTS Packages-B2F"
{
    actions
    {
        addlast(Processing)
        {

            action("Create PTS Packages_Inc")
            {
                ApplicationArea = All;
                Caption = 'Create PTS Packages';
                Image = Create;
                trigger OnAction()
                var
                    LReport: report "Download PTS Packages_Inc";
                begin
                    Clear(LReport);
                    LReport.Run();
                end;



            }






        }
    }
}
