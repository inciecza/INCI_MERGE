pageextension 70827 "Invt. Shipment_Inc" extends "Invt. Shipment"
{
    layout
    {
        addafter(Status)
        {
            field("Invt Ship Acc. Mang. App._Inc"; Rec."Invt Ship Acc. Mang. App._Inc")
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    PermissionControl(1);
                end;
            }
            field("Invt Ship Mang. App._Inc"; Rec."Invt Ship Mang. App._Inc")
            {
                ApplicationArea = All;
                trigger OnValidate()
                begin
                    PermissionControl(2);
                end;
            }
        }
    }
    actions
    {
        modify("Re&lease")
        {
            trigger OnBeforeAction()
            begin
                FieldControl();
            end;
        }
        modify("P&ost")
        {
            trigger OnBeforeAction()
            begin
                FieldControl();
            end;
        }
        modify("Post and &Print")
        {
            trigger OnBeforeAction()
            begin
                FieldControl();
            end;
        }
    }
    local procedure FieldControl()
    begin
        if not (rec."Invt Ship Mang. App._Inc") or not (rec."Invt Ship Acc. Mang. App._Inc") then begin
            Error('Muhasebe ve Yönetici Onayı Gereklidir');
        end;
    end;

    local procedure PermissionControl(PermissionType: Integer)
    var
        LUserSetup: Record "User Setup";
    begin
        LUserSetup.Init();
        if LUserSetup.Get(UserId) then begin
            case PermissionType of
                1:
                    if not LUserSetup."Invt Ship Acc. Mang. App._Inc" then
                        Error('Muhasebe yetkiniz bulunmamaktadır');
                2:
                    if not LUserSetup."Invt Ship Mang. App._Inc" then
                        Error('Yönetici yetkiniz bulunmamaktadır');
            end;
        end;

    end;

    var

}
