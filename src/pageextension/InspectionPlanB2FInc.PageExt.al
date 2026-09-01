pageextension 70814 "Inspection Plan-B2F_Inc" extends "Inspection Plan-B2F"
{
    layout
    {
        modify(Status)
        {
            trigger OnAfterValidate()
            begin
                case Rec.Status of
                    Rec.Status::"Under Development":
                        RoutingCheckStatus(1);
                    Rec.Status::Certified:
                        RoutingCheckStatus(2);

                end;
            end;
        }
    }
    local procedure RoutingCheckStatus(StatusType: Integer)
    var
        LUserSetup: Record "User Setup";
    begin
        Clear(LUserSetup);
        if LUserSetup.Get(UserId) then
            case StatusType of
                1:
                    if LUserSetup."Inspection Approved_Inc" then
                        Error(Err01_Err);
                2:
                    if LUserSetup."Inspection Developing_Inc" then
                        Error(Err02_Err);
            end;
    end;

    var
        Err01_Err: Label 'You are not allowed to change the status to Under Development.';
        Err02_Err: Label 'You are not allowed to change the status to Approved.';
}
