pageextension 70808 "Outgoing PTS Packages-B2F_Inc" extends "Outgoing PTS Packages-B2F"
{
    layout
    {
        addlast(Content)
        {
            group(Filter_Inc)
            {
                field(Sdate_Inc; Sdate)
                {
                    ApplicationArea = All;
                    Caption = 'Start Date';
                }
                field(Edate_Inc; Edate)
                {
                    ApplicationArea = All;
                    Caption = 'End Date';
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(Generate_Inc)
            {
                ApplicationArea = All;
                Caption = 'XML Downloand';
                Image = XMLFile;
                trigger OnAction()
                var

                begin

                end;
            }
        }
    }


    var

        Sdate: Date;
        Edate: Date;
}
