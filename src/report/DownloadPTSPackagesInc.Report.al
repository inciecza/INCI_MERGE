report 70809 "Download PTS Packages_Inc"
{
    Caption = 'Download PTS Packages';
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                FindItems();
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
                    field(ItemNo; ItemNo)
                    {
                        Caption = 'Item No.';
                        ToolTip = 'Select the item number to filter the report.';
                        ApplicationArea = All;
                        TableRelation = Item;
                    }

                    field(StartDate; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Start Date';
                        ToolTip = 'Select the start date to filter the report.';
                    }

                    field(EndDate; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                        ToolTip = 'Select the end date to filter the report.';
                    }
                    field(SendSMTP; SendSMTP)
                    {
                        Caption = 'Send SMTP';
                        ApplicationArea = All;
                        ToolTip = 'Select whether to send the report via SMTP.';
                    }

                }
            }
        }

        actions
        {
            area(Processing)
            {
            }
        }
    }

    local procedure FindItems()
    var
        LSalesInvoiceLine: Record "Sales Invoice Line";
        LSalesShipmentLine: Record "Sales Shipment Line";
        LPostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        LPTSPackageEntry: Record "Pts Package Entry-B2F";
    begin
        if StartDate = 0D then
            Error('Start date must be filled.');

        if EndDate = 0D then
            Error('End date must be filled.');

        if ItemNo = '' then
            Error('Item No. must be filled.');

        // ---------------------------------------------------------
        // PTS Package Entry recordunu bir kere resetliyoruz.
        // Bundan sonra RESET KULLANMIYORUZ.
        // Çünkü RESET mark'ları temizler.
        // ---------------------------------------------------------
        LPTSPackageEntry.Reset();

        Clear(LSalesInvoiceLine);
        LSalesInvoiceLine.SetRange(
            Type,
            LSalesInvoiceLine.Type::Item
        );
        LSalesInvoiceLine.SetRange(
            "Posting Date",
            StartDate,
            EndDate
        );
        LSalesInvoiceLine.SetRange(
            "No.",
            ItemNo
        );

        if LSalesInvoiceLine.FindSet() then
            repeat

                Clear(LSalesShipmentLine);
                LSalesShipmentLine.SetRange(
                    Type,
                    LSalesShipmentLine.Type::Item
                );
                LSalesShipmentLine.SetRange(
                    "Order No.",
                    LSalesInvoiceLine."Order No."
                );
                LSalesShipmentLine.SetRange(
                    "Order Line No.",
                    LSalesInvoiceLine."Order Line No."
                );

                if LSalesShipmentLine.FindSet() then
                    repeat

                        Clear(LPostedWhseShipmentLine);
                        LPostedWhseShipmentLine.SetRange(
                            "Source Type",
                            37
                        );
                        LPostedWhseShipmentLine.SetRange(
                            "Source No.",
                            LSalesShipmentLine."Order No."
                        );
                        LPostedWhseShipmentLine.SetRange(
                            "Source Line No.",
                            LSalesShipmentLine."Order Line No."
                        );
                        LPostedWhseShipmentLine.SetRange(
                            "Item No.",
                            LSalesShipmentLine."No."
                        );

                        if LPostedWhseShipmentLine.FindSet() then
                            repeat

                                // -------------------------------------------------
                                // DİKKAT:
                                // BURADA RESET YOK!
                                // SetRange mevcut filtreleri değiştiriyor,
                                // ancak daha önce yapılan MARK'ları koruyor.
                                // -------------------------------------------------

                                LPTSPackageEntry.SetRange(
                                    "Package Type",
                                    LPTSPackageEntry."Package Type"::"Outgoing PTS Package"
                                );

                                LPTSPackageEntry.SetRange(
                                    documentNumber,
                                    LPostedWhseShipmentLine."No."
                                );

                                if LPTSPackageEntry.FindSet() then
                                    repeat
                                        // Kaydı işaretle
                                        LPTSPackageEntry.Mark(true);
                                    until LPTSPackageEntry.Next() = 0;

                            until LPostedWhseShipmentLine.Next() = 0;

                    until LSalesShipmentLine.Next() = 0;

            until LSalesInvoiceLine.Next() = 0;

        // ---------------------------------------------------------
        // ARTIK SADECE MARK EDİLMİŞ KAYITLAR
        // ---------------------------------------------------------

        LPTSPackageEntry.MarkedOnly(true);

        if LPTSPackageEntry.FindSet() then
            CreatePTSPackages(LPTSPackageEntry);
    end;


    local procedure CreatePTSPackages(
        var pPTSPackageEntry: Record "Pts Package Entry-B2F"
    )
    var
        DataCompression: Codeunit "Data Compression";
        SourceDataCompression: Codeunit "Data Compression";
        TempBlob: Codeunit "Temp Blob";
        SourceTempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        SourceInStr: InStream;
        FileName: Text;
        EntryName: Text;
        NewEntryName: Text;
        EntryList: List of [Text];
        EntryNo: Integer;
        HasFile: Boolean;
        NoFileMsg: Label 'No package files were found.';
    begin
        // Ana ZIP için Temp Blob
        TempBlob.CreateOutStream(OutStr);

        // Ana ZIP'i oluştur
        DataCompression.CreateZipArchive();

        // Buraya gelen Record zaten MarkedOnly filtresine sahip.
        if not pPTSPackageEntry.FindSet() then begin
            DataCompression.CloseZipArchive();
            Message(NoFileMsg);
            exit;
        end;

        repeat

            pPTSPackageEntry.CalcFields("fileStream");

            if pPTSPackageEntry."fileStream".HasValue() then begin

                HasFile := true;

                // Kaydın ZIP dosyasını oku
                pPTSPackageEntry."fileStream".CreateInStream(InStr);

                // ZIP'i aç
                SourceDataCompression.OpenZipArchive(
                    InStr,
                    false
                );

                Clear(EntryList);

                SourceDataCompression.GetEntryList(
                    EntryList
                );

                EntryNo := pPTSPackageEntry."Entry No.";

                foreach EntryName in EntryList do begin

                    Clear(SourceTempBlob);

                    SourceDataCompression.ExtractEntry(
                        EntryName,
                        SourceTempBlob
                    );

                    // XML dosyasını ZIP'in ana dizinine ekle
                    NewEntryName := EntryName;

                    SourceTempBlob.CreateInStream(
                        SourceInStr
                    );

                    DataCompression.AddEntry(
                        SourceInStr,
                        NewEntryName
                    );
                end;

                SourceDataCompression.CloseZipArchive();
            end;

        until pPTSPackageEntry.Next() = 0;

        if not HasFile then begin
            DataCompression.CloseZipArchive();
            Message(NoFileMsg);
            exit;
        end;

        // Ana ZIP'i kapat
        DataCompression.SaveZipArchive(
            OutStr
        );

        // Kullanıcıya indir
        TempBlob.CreateInStream(
            InStr
        );

        FileName := 'PTS_Packages.zip';

        DownloadFromStream(
            InStr,
            '',
            '',
            '',
            FileName
        );
    end;


    var
        ItemNo: Code[20];
        StartDate: Date;
        EndDate: Date;
        SendSMTP: Boolean;
}