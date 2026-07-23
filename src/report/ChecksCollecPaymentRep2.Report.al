report 70807 "Checks Collec. Payment Rep2"
{
    ApplicationArea = all;
    Caption = 'Checks Collec. Payment Rep2';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/ChecksCollectionPaymentReport.rdlc';

    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;
            column(GirisNo; "Entry No.") { }
            column(VadeTarihi; "Posting Date") { }
            column(Bank_No; "Order No.") { }
            column(Musteri_No; "Document No.") { }
            column(Musteri_Ad; Description) { }
            column(Banka_Ad; "External Document No.") { }
            column(Tutar; "Sales Amount (Actual)") { }
            column(Doviz_Cinsi; "Location Code") { }
            column(Rapor_Tipi; ReportName) { }
            column(Sirket; "Job Task No.") { }
            column(Cek_No; "Gen. Bus. Posting Group") { }
            column(Konsolice; Consolide) { }
            column(SuankiDurum_No; "User ID") { }
            trigger OnPreDataItem()
            begin
                FillTempVLE();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(GroupName)
                {
                    field(ReportType; ReportType)
                    {
                        Caption = 'Report Type';
                        ApplicationArea = All;
                    }
                    field(StartDate; StartDate)
                    {
                        Caption = 'Start Date';
                        ApplicationArea = All;

                    }
                    field(EndDate; EndDate)
                    {
                        Caption = 'End Date';
                        ApplicationArea = All;
                    }

                    field(Consolide; Consolide)
                    {
                        Caption = 'Consolide Company';
                        ApplicationArea = All;
                    }
                }
            }
        }
        actions
        {
            area(Processing) { }
        }

        trigger OnOpenPage()
        begin
            StartDate := Today;
            EndDate := Today;
        end;

    }

    local procedure FillTempVLE()
    begin
        // Mevcut şirketi her zaman doldur
        FillDataForCompany(CompanyName);

        // Consolide seçiliyse diğer şirketi de ekle
        if Consolide then begin
            if CompanyName = 'INC' then
                FillDataForCompany('İnci Ecza')
            else
                FillDataForCompany('INC');
        end;
    end;

    local procedure FillDataForCompany(pCompanyName: Text)
    var
        // LBank: Record "Bank Account";
        LCheque: Record "Cheque-B2F";
        LBank: Record "Bank-B2F";
        LPorfolio: Record "Portfolio-B2F";
        LCustomer: Record Customer;
    begin
        // Şirket değiştir
        LCheque.ChangeCompany(pCompanyName);
        // Banka hareketleri
        Clear(LCheque);
        case ReportType of
            ReportType::"Müşteri-Tahsil Edilecek":
                begin
                    LCheque.SetRange("Our Cheque", false);
                    LCheque.Setfilter("Cheque Number", '<>%1', '');
                    LCheque.Setfilter("Due Date", '<>%1', 0D);
                    LCheque.Setfilter(Amount, '<>%1', 0);
                    LCheque.Setfilter("Customer No.", '<>%1', '');
                    LCheque.SetRange("Present Location Type", LCheque."Present Location Type"::Portfolio);
                    LCheque.SetRange("Exists in unposted document", false);
                    LCheque.Setfilter("Transaction Standard Type", '<>%1&<>%2', LCheque."Transaction Standard Type"::Payment, LCheque."Transaction Standard Type"::Paid);
                end;
            ReportType::"Firma-Ödenecek":
                begin
                    LCheque.SetRange("Our Cheque", true);
                    LCheque.Setfilter("Cheque Number", '<>%1', '');
                    LCheque.Setfilter("Bank Account Code", '<>%1', '');
                    LCheque.Setfilter("Due Date", '<>%1', 0D);
                    LCheque.Setfilter(Amount, '<>%1', 0);
                    LCheque.SetRange("Exists in unposted document", false);
                    LCheque.Setfilter("Transaction Standard Type", '<>%1&<>%2', LCheque."Transaction Standard Type"::Payment, LCheque."Transaction Standard Type"::Paid);
                end;
            ReportType::"Müşteri-Tahsil Edildi":
                begin
                    LCheque.SetRange("Our Cheque", false);
                    LCheque.Setfilter("Cheque Number", '<>%1', '');
                    LCheque.Setfilter("Due Date", '<>%1', 0D);
                    LCheque.Setfilter(Amount, '<>%1', 0);
                    LCheque.SetRange("Exists in unposted document", false);
                    LCheque.SetRange("Transaction Standard Type", LCheque."Transaction Standard Type"::Receipt);
                    LCheque.SetRange("Due Date", StartDate, EndDate);
                end;
            ReportType::"Firma Ödendi":
                begin
                    LCheque.SetRange("Our Cheque", true);
                    LCheque.Setfilter("Cheque Number", '<>%1', '');
                    LCheque.Setfilter("Bank Account Code", '<>%1', '');
                    LCheque.Setfilter("Due Date", '<>%1', 0D);
                    LCheque.Setfilter(Amount, '<>%1', 0);
                    LCheque.SetRange("Exists in unposted document", false);
                    LCheque.SetRange("Transaction Standard Type", LCheque."Transaction Standard Type"::Paid);

                end;
        end;
        if LCheque.FindSet() then
            repeat
                TempVLE.Init();
                i += 1;
                TempVLE."Entry No." := i;
                TempVLE."Posting Date" := LCheque."Due Date"; // Vade tarihi
                TempVLE."Order No." := LCheque."Bank Account No."; //bank No
                TempVLE."Document No." := LCheque."Customer No."; // Müşteri No
                LCheque.CalcFields(LCheque."Customer Name");
                TempVLE.Description := LCheque."Customer Name"; // Müşteri Ad
                Clear(LBank);
                if LBank.Get(LCheque."Bank Code") then
                    TempVLE."External Document No." := LBank."Bank Name"; //Bank ad
                TempVLE."Sales Amount (Actual)" := LCheque."Amount"; //Tutar
                TempVLE."Gen. Bus. Posting Group" := LCheque."Cheque Number";
                Clear(LPorfolio);
                if LPorfolio.Get(LCheque."Present Location No.") then
                    TempVLE."User ID" := LPorfolio.Name;

                if LCheque."Currency Code" = '' then
                    TempVLE."Location Code" := 'TL'
                else
                    TempVLE."Location Code" := LCheque."Currency Code";

                case ReportType of
                    ReportType::"Müşteri-Tahsil Edilecek":
                        ReportName := 'TAHSİL EDİLECEK ÇEKLER';
                    ReportType::"Firma-Ödenecek":
                        ReportName := 'ÖDENECEK ÇEKLER';
                    ReportType::"Müşteri-Tahsil Edildi":
                        ReportName := 'TAHSİL EDİLENLER';
                    ReportType::"Firma Ödendi":
                        ReportName := 'ÖDENEN ÇEKLER';
                end;
                if pCompanyName = 'INC' then
                    TempVLE."Job Task No." := 'INC'
                else
                    TempVLE."Job Task No." := 'İnci Ecza';

                TempVLE.Insert();
            until LCheque.Next() = 0;
    end;

    /*
        local procedure GetBankName(pBankCode: Code[20];
    pCompanyName: Text) rtnvalue: Text
        var
            LBank: Record "Bank Account";
        begin
            LBank.ChangeCompany(pCompanyName);
            LBank.SetLoadFields("No.", Name);
            if LBank.Get(pBankCode) then
                rtnvalue := LBank."Report Name_Inc";
        end;
        */



    var
        i: Integer;
        StartDate: Date;
        EndDate: Date;
        Consolide: Boolean;
        ReportName: Text[30];
        ReportType: Option "Müşteri-Tahsil Edilecek","Müşteri-Tahsil Edildi","Firma-Ödenecek","Firma Ödendi";
}