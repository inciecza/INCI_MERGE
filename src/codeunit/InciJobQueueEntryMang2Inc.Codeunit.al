codeunit 70800 "Inci Job Queue Entry Mang2_Inc"
{

    TableNo = "Job Queue Entry";
    trigger OnRun()
    begin

        case Rec."Parameter String" of
            'sendmiadreport':
                SendMiadReport();
        end;
    end;



    local procedure SendMiadReport()
    var
        LStartDate: Date;
        LEndDate: Date;
    begin
        LStartDate := Today;
        LEndDate := CalcDate('<+6M>', LStartDate);
        if CheckMiadData(LStartDate, LEndDate) then
            SendMiadReportData(LStartDate, LEndDate);

    end;

    local procedure CheckMiadData(pStartDate: Date; pEndDate: Date): Boolean
    var
        LItemLedgerEntry: Record "Item Ledger Entry";
        LIncGenSetup: Record "Inci General Setup_Inc";
        LCompany: Record "Company";
    begin


        Clear(LIncGenSetup);
        LIncGenSetup.Get();

        LItemLedgerEntry.Reset();
        LItemLedgerEntry.SetCurrentKey("Expiration Date");
        LItemLedgerEntry.SetAscending("Expiration Date", true);

        LItemLedgerEntry.Setfilter("Item No.", '');
        LItemLedgerEntry.Setfilter("Location Code", '%1|%2', LIncGenSetup."Private Hospital Bagc.Location", LIncGenSetup."Private Hospital Malt.Location");
        LItemLedgerEntry.Setfilter("Remaining Quantity", '>0');
        Clear(LCompany);
        if LCompany.Get(CompanyName) then
            if LCompany.Name = 'INC' then
                LItemLedgerEntry.Setfilter("Item Category Code", 'BİTMİŞ ÜRÜN');
        LItemLedgerEntry.SetRange("Expiration Date", pStartDate, pEndDate);

        if LItemLedgerEntry.FindSet() then
            exit(true);
        exit(false);
    end;

    procedure SendMiadReportData(pStartDate: Date; pEndDate: Date): Boolean
    var
        LMailingGroup: Record "Mailing Group";
        LReport: Report "Miad Stock Report_Inc";
        BodyBlob: Codeunit "Temp Blob";
        BodyBlob2: Codeunit "Temp Blob";
        LInciGeneralSetup: codeunit InciGeneral_Inc;
        AttchInStream: InStream;
        Instrm: InStream;
        AttchOutStream: OutStream;
        BodyStream: OutStream;
        body: Text;
        lBCCTo: List of [Text];
        lCCTo: List of [Text];
        lSendTo: List of [Text];
        lBCCtoAdd: Text;
        lCCtoAdd: Text;
        lsendToAdd: Text;
        FileName: Text[250];
        LMailSubject: Text[250];
        Text_Body1_Lbl: Label 'Merhaba,';
        Text_Body2_Lbl: Label 'Süresi yaklaşan stok kalemleri ektedir.';
        Text_Body3_Lbl: Label 'Saygılarımızla.';
        Text_MailSubject: Label 'Miad Stok Bilgilendirme Raporu';
        LText_FileName_Lbl: Label 'Miad Stok Raporu';
    begin
        if not LMailingGroup.Get('MIADR') then
            exit(false);

        lSendTo := LMailingGroup.TO_Inc.Split(';');
        lCCTo := LMailingGroup.CC_Inc.Split(';');
        lBCCTo := LMailingGroup.BCC_Inc.Split(';');

        LMailSubject := Text_MailSubject;

        // Body
        BodyBlob.CreateOutStream(BodyStream, TEXTENCODING::UTF8);
        BodyStream.WriteText(Text_Body1_Lbl + '<br><br>');
        BodyStream.WriteText(Text_Body2_Lbl + '<br><br>');
        BodyStream.WriteText(Text_Body3_Lbl);
        BodyBlob.CreateInStream(Instrm, TEXTENCODING::UTF8);
        Instrm.ReadText(body);

        // Attachment
        BodyBlob2.CreateOutStream(AttchOutStream);
        LReport.SetParameters(pStartDate, pEndDate);
        LReport.SaveAs('', ReportFormat::Excel, AttchOutStream);
        BodyBlob2.CreateInStream(AttchInStream);

        FileName :=
            Format(Date2DMY(Today, 3)) + '.' +
            Format(Date2DMY(Today, 2)) + '.' +
            Format(Date2DMY(Today, 1)) + '-' +
            LText_FileName_Lbl + '.xlsx';

        exit(
            LInciGeneralSetup.SendEmailviaSMTP(
                lSendTo,
                lCCTo,
                lBCCTo,
                LMailSubject,
                body,
                AttchInStream,
                FileName
            )

        );
    end;
}