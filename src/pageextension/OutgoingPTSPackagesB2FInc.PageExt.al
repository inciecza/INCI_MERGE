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


                /*
                                trigger OnAction()
                                var
                                    LPTSPackageEntry: Record "Pts Package Entry-B2F";
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

                                    LPTSPackageEntry.Reset();
                                    LPTSPackageEntry.SetRange("Package Type", LPTSPackageEntry."Package Type"::"Outgoing PTS Package");

                                    if not LPTSPackageEntry.FindSet() then begin
                                        Message(NoFileMsg);
                                        exit;
                                    end;

                                    repeat
                                        LPTSPackageEntry.CalcFields("fileStream");

                                        if LPTSPackageEntry."fileStream".HasValue() then begin
                                            HasFile := true;

                                            // Kaydın ZIP dosyasını oku
                                            LPTSPackageEntry."fileStream".CreateInStream(InStr);

                                            // ZIP'i aç
                                            SourceDataCompression.OpenZipArchive(InStr, false);

                                            Clear(EntryList);
                                            SourceDataCompression.GetEntryList(EntryList);

                                            EntryNo := LPTSPackageEntry."Entry No.";

                                            // ZIP içindeki bütün dosyaları dolaş
                                            foreach EntryName in EntryList do begin

                                                // ZIP içindeki dosyayı Temp Blob'a çıkar
                                                Clear(SourceTempBlob);

                                                SourceDataCompression.ExtractEntry(
                                                    EntryName,
                                                    SourceTempBlob
                                                );

                                                // Yeni ZIP içerisindeki klasör yapısı
                                                NewEntryName :=
                                                    StrSubstNo(
                                                        '%1/%2',
                                                        Format(EntryNo),
                                                        EntryName
                                                    );

                                                // Çıkarılan dosyayı oku
                                                SourceTempBlob.CreateInStream(SourceInStr);

                                                // Ana ZIP'e ekle
                                                DataCompression.AddEntry(
                                                    SourceInStr,
                                                    NewEntryName
                                                );
                                            end;

                                            SourceDataCompression.CloseZipArchive();
                                        end;

                                    until LPTSPackageEntry.Next() = 0;

                                    if not HasFile then begin
                                        DataCompression.CloseZipArchive();
                                        Message(NoFileMsg);
                                        exit;
                                    end;

                                    // Ana ZIP'i kapat
                                    DataCompression.SaveZipArchive(OutStr);

                                    // Kullanıcıya indir
                                    TempBlob.CreateInStream(InStr);

                                    FileName := 'PTS_Packages.zip';

                                    DownloadFromStream(
                                        InStr,
                                        '',
                                        '',
                                        '',
                                        FileName
                                    );
                                end;

                                */
            }






        }
    }
}
