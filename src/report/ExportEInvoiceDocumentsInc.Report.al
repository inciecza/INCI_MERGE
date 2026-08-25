report 70813 "Export EInvoice Documents_Inc"
{
    Caption = 'Export EInvoice Documents';
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
                    }

                    field(EndDate; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'End Date';
                    }
                }
            }
        }
    }

    local procedure FindItems()
    var
        LSalesInvLine: Record "Sales Invoice Line";
        LTempBlob: Codeunit "Temp Blob";
        LInStream: InStream;
        LOutStream: OutStream;
        LFileName: Text;
    begin
        Clear(DownloadedCount);
        Clear(SkippedCount);
        Clear(LastDocumentNo);

        Clear(DataCompression);
        DataCompression.CreateZipArchive();

        Clear(LSalesInvLine);
        LSalesInvLine.SetRange("No.", ItemNo);
        LSalesInvLine.SetRange("Posting Date", StartDate, EndDate);
        LSalesInvLine.SetCurrentKey("Document No.");

        if LSalesInvLine.FindSet() then
            repeat
                // Aynı faturayı tekrar ZIP'e ekleme
                if LastDocumentNo <> LSalesInvLine."Document No." then begin
                    LastDocumentNo := LSalesInvLine."Document No.";

                    AddHTMLInvoiceToZip(
                        LSalesInvLine."Document No.");
                end;
            until LSalesInvLine.Next() = 0;

        if DownloadedCount = 0 then begin
            DataCompression.CloseZipArchive();
            Message('No HTML E-Invoice documents were found.');
            exit;
        end;

        // ZIP'i Temp Blob'a yaz
        LTempBlob.CreateOutStream(LOutStream);
        DataCompression.SaveZipArchive(LOutStream);

        // ZIP'i kapat
        DataCompression.CloseZipArchive();

        // ZIP'i indir
        LTempBlob.CreateInStream(LInStream);

        LFileName := StrSubstNo(
            'EInvoice_HTML_%1.zip',
            Format(Today, 0, '<Year4><Month,2><Day,2>'));

        DownloadFromStream(
            LInStream,
            'Download E-Invoice HTML Documents',
            '',
            'ZIP Files (*.zip)|*.zip',
            LFileName);

        Message(
            '%1 HTML E-Invoice document(s) exported to ZIP.\%2 document(s) were skipped because HTML was not found.',
            DownloadedCount,
            SkippedCount);
    end;

    local procedure AddHTMLInvoiceToZip(pDocumentNo: Code[20])
    var
        LEInvoiceEntry: Record "E-Invoice Entry-B2F";
        LInStream: InStream;
        LZipEntryName: Text;
    begin
        LEInvoiceEntry.Reset();
        LEInvoiceEntry.SetRange(
            "Posted Document No.",
            pDocumentNo);

        if not LEInvoiceEntry.FindFirst() then begin
            SkippedCount += 1;
            exit;
        end;

        LEInvoiceEntry.CalcFields("E-Document (HTML)");

        if not LEInvoiceEntry."E-Document (HTML)".HasValue() then begin
            SkippedCount += 1;
            exit;
        end;

        LEInvoiceEntry."E-Document (HTML)".CreateInStream(LInStream);

        LZipEntryName := GetHTMLFileName(
            LEInvoiceEntry,
            pDocumentNo);

        DataCompression.AddEntry(
            LInStream,
            LZipEntryName);

        DownloadedCount += 1;
    end;

    local procedure GetHTMLFileName(
        pEInvoiceEntry: Record "E-Invoice Entry-B2F";
        pDocumentNo: Code[20]): Text
    begin
        if pDocumentNo <> '' then
            exit(pDocumentNo + '.html');

        if pEInvoiceEntry."E-Document ID" <> '' then
            exit(pEInvoiceEntry."E-Document ID" + '.html');

        exit(
            StrSubstNo(
                'EInvoice_%1.html',
                pEInvoiceEntry."Entry No."));
    end;

    var
        ItemNo: Code[20];
        StartDate: Date;
        EndDate: Date;

        LastDocumentNo: Code[20];

        DownloadedCount: Integer;
        SkippedCount: Integer;

        DataCompression: Codeunit "Data Compression";
}