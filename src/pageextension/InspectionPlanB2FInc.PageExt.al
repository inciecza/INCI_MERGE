pageextension 70814 "Inspection Plan-B2F_Inc" extends "Inspection Plan-B2F"
{
    layout
    {
        modify(Status)
        {
            trigger OnAfterValidate()
            begin
                // Durum değişmediyse bir şey yapma
                if Rec.Status = xRec.Status then
                    exit;

                // Onaylandı'ya geçmeden önce Geliştiriliyor aşamasından geçmeli
                if Rec.Status = Rec.Status::Certified then
                    if not (xRec.Status = Rec.Status::"Under Development") then
                        Error(NeedUnderDevelopmentFirstErr);

                CheckStatusChangePermission();

                // Durum Geliştiriliyor / Onaylandı olduysa bildirim gönder
                case Rec.Status of
                    Rec.Status::"Under Development":
                        InciGeneral2.InspectionPlanStatusMailSend(Rec."No.", Rec.Description, 2);
                    Rec.Status::Certified:
                        InciGeneral2.InspectionPlanStatusMailSend(Rec."No.", Rec.Description, 3);
                end;
            end;
        }
        modify(Description)
        {
            trigger OnAfterValidate()
            begin
                // Durum Yeni iken açıklama değiştiyse bildirim gönder
                if (Rec.Description <> xRec.Description) and (Rec.Status = Rec.Status::New) then
                    InciGeneral2.InspectionPlanStatusMailSend(Rec."No.", Rec.Description, 1);
            end;
        }
    }

    local procedure CheckStatusChangePermission()
    var
        UserSetup: Record "User Setup";
        HasApprovedPermission: Boolean;
        HasDevelopingPermission: Boolean;
    begin
        // Kullanıcı User Setup'ta yoksa iki yetki de yok sayılır
        if UserSetup.Get(UserId()) then begin
            HasApprovedPermission := UserSetup."Inspection Approved_Inc";
            HasDevelopingPermission := UserSetup."Inspection Developing_Inc";
        end;

        // Onaylandı yapmak veya Onaylandı olan kaydı değiştirmek -> Onay yetkisi
        if (Rec.Status = Rec.Status::Certified) or (xRec.Status = xRec.Status::Certified) then
            if not HasApprovedPermission then begin
                if Rec.Status = Rec.Status::Certified then
                    Error(CertifiedNotAllowedErr)
                else
                    Error(ChangeCertifiedNotAllowedErr);
            end;

        // Geliştiriliyor yapmak -> Geliştirme yetkisi
        if Rec.Status = Rec.Status::"Under Development" then
            if not HasDevelopingPermission then
                Error(UnderDevelopmentNotAllowedErr);
    end;

    var
        InciGeneral2: Codeunit "InciGeneral2_Inc";
        NeedUnderDevelopmentFirstErr: Label 'İlk Önce Geliştiriliyor aşamasına almanız gerekiyor.';
        UnderDevelopmentNotAllowedErr: Label 'You are not allowed to change the status to Under Development.';
        CertifiedNotAllowedErr: Label 'You are not allowed to change the status to Certified.';
        ChangeCertifiedNotAllowedErr: Label 'You are not allowed to change the status of a Certified inspection plan.';
}
