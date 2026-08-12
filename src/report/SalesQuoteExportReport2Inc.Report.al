report 70808 "Sales Quote Export Report2_Inc"
{
    Caption = 'Sales Quote Export Report2_Inc';
    ApplicationArea = All;
    UsageCategory = ReportsAndAnalysis;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Integer; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            trigger OnAfterGetRecord()
            begin
                ExportExcel();
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

    procedure ExportExcel()
    var
        TempBlob: Codeunit "Temp Blob";
        ExcelBuffer: Record "Excel Buffer" temporary;
        InS: InStream;
        OutS: OutStream;
        DownloadInS: InStream;
        SheetName: Text[250];
        FileName: Text;
        CurrentRow: Integer;
    begin
        // 1. Blob alanını hesapla
        CustomerDataTransfer.CalcFields("Excel File");

        if not CustomerDataTransfer."Excel File".HasValue() then
            Error('Bu müşteri için Excel şablonu bulunamadı.');

        // 2. Blob'daki Excel dosyasını TempBlob'a kopyala
        CustomerDataTransfer."Excel File".CreateInStream(InS);
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, InS);

        // 3. Sheet adını al
        TempBlob.CreateInStream(InS);
        SheetName := ExcelBuffer.SelectSheetsNameStream(InS);

        if SheetName = '' then
            Error('Excel içerisinde çalışma sayfası bulunamadı.');

        // 4. Mevcut Excel şablonunu güncelleme modunda aç (true = mevcut verileri koru)
        TempBlob.CreateInStream(InS);
        ExcelBuffer.UpdateBookStream(InS, SheetName, true);

        // 5. Satırları yaz
        CurrentRow := CustomerDataTransfer."Start Line";

        if SalesLine.FindSet() then
            repeat
                WriteLineToExcel(ExcelBuffer, CurrentRow);
                CurrentRow += 1;
            until SalesLine.Next() = 0;

        // 6. Buffer'daki verileri sheet'e yaz
        ExcelBuffer.WriteAllToCurrentSheet(ExcelBuffer);

        // 7. Kitabı kapat ve stream'e kaydet
        ExcelBuffer.CloseBook();

        // 8. ÖNEMLİ: Yeni bir TempBlob oluştur, SaveToStream ile doldur
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        ExcelBuffer.SaveToStream(OutS, true);

        // 9. Dosya adını belirle
        FileName := CustomerDataTransfer."Excel File Name";
        if FileName = '' then
            FileName := 'SalesQuote_' + CustomerDataTransfer."Customer No" + '.xlsx';

        if StrPos(LowerCase(FileName), '.xlsx') = 0 then
            FileName += '.xlsx';

        // 10. İndir
        TempBlob.CreateInStream(DownloadInS);
        DownloadFromStream(DownloadInS, '', '', '', FileName);
    end;

    local procedure WriteCell(
        var ExcelBuffer: Record "Excel Buffer" temporary;
        RowNo: Integer;
        ColumnLetter: Text[3];
        CellValue: Variant)
    var
        ColumnNo: Integer;
    begin
        // Sütun tanımlanmamışsa yaz
        if ColumnLetter = '' then
            exit;

        ColumnNo := ColLetterToNumber(ColumnLetter);

        if ColumnNo = 0 then
            Error('Geçersiz Excel sütun değeri: %1', ColumnLetter);

        ExcelBuffer.EnterCell(
            ExcelBuffer,
            RowNo,
            ColumnNo,
            CellValue,
            false,
            false,
            false);
    end;

    local procedure WriteLineToExcel(var ExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer)
    var
        LItem: record Item;
        LInciGeneral: codeunit InciGeneral_Inc;
    begin
        LItem.Get(SalesLine."No.");
        WriteCell(
            ExcelBuffer,
            RowNo,
            CustomerDataTransfer."Customer Item Name",
            SalesLine."Customer Request. ItemName_Inc");

        if CustomerDataTransfer."Item Name" <> '' then begin
            WriteCell(
                ExcelBuffer,
                RowNo,
                CustomerDataTransfer."Item Name",
                SalesLine.Description);
        end;
        if CustomerDataTransfer.Quantity <> '' then begin
            WriteCell(
                ExcelBuffer,
                RowNo,
                CustomerDataTransfer.Quantity,
                Format(SalesLine.Quantity));
        end;

        if CustomerDataTransfer."Unit of Measure" <> '' then begin
            WriteCell(
                ExcelBuffer,
                RowNo,
                CustomerDataTransfer."Unit of Measure",
                SalesLine."Customer Unit Measure_Inc");
        end;


        if CustomerDataTransfer."Divide by Box Quantity" then begin
            if SalesLine."Customer Unit Measure_Inc" = 'ADET' then
                if LItem."Quantity per BoxINC" <> 0 then begin
                    WriteCell(
                ExcelBuffer,
                RowNo,
                CustomerDataTransfer."Quote Price",
                Format(SalesLine."Unit Price" / LItem."Quantity per BoxINC"));
                end
                else
                    WriteCell(
               ExcelBuffer,
               RowNo,
               CustomerDataTransfer."Quote Price",
               Format(SalesLine."Unit Price"))


            else
                WriteCell(
              ExcelBuffer,
              RowNo,
              CustomerDataTransfer."Quote Price",
              Format(SalesLine."Unit Price"));

        end
        else
            WriteCell(
                ExcelBuffer,
                RowNo,
                CustomerDataTransfer."Quote Price",
                Format(SalesLine."Unit Price"));

        if CustomerDataTransfer."Quote Miad" <> '' then begin
            WriteCell(
                ExcelBuffer,
                RowNo,
                CustomerDataTransfer."Quote Miad",
                LInciGeneral.GetMiadDataMaltepeBagcilar(SalesLine."No."));
        end;
        if CustomerDataTransfer.Inventory <> '' then begin
            WriteCell(
                ExcelBuffer,
                RowNo,
                CustomerDataTransfer.Inventory,
                LInciGeneral.GetStock(SalesLine."No.", ''));
        end;

        if CustomerDataTransfer."Line No" <> '' then begin
            WriteCell(
                ExcelBuffer,
                RowNo,
                CustomerDataTransfer."Line No",
                format(SalesLine."Customer Line No._Inc"));
        end;
        if CustomerDataTransfer.Barcode <> '' then begin
            WriteCell(
                ExcelBuffer,
                RowNo,
                CustomerDataTransfer.Barcode,
                SalesLine.GTIN_Inc);
        end;
    end;

    local procedure ColLetterToNumber(ColumnLetter: Text[3]): Integer
    var
        Letter: Char;
        Position: Integer;
        Factor: Integer;
        ColumnNo: Integer;
    begin
        ColumnLetter := UpperCase(DelChr(ColumnLetter, '=', ' '));

        if ColumnLetter = '' then
            exit(0);

        Factor := 1;

        for Position := StrLen(ColumnLetter) downto 1 do begin
            Letter := ColumnLetter[Position];

            if (Letter < 'A') or (Letter > 'Z') then
                exit(0);

            ColumnNo += Factor * ((Letter - 'A') + 1);
            Factor *= 26;
        end;

        exit(ColumnNo);
    end;

    procedure SetParameters(pCustomerNo: Code[20]; pSalesDocumentNo: Code[20]; pSalesDocType: Integer)
    begin
        Clear(CustomerDataTransfer);
        if not CustomerDataTransfer.Get(pCustomerNo) then
            Error('Customer Data Transfer kaydı bulunamadı. Müşteri No: %1', pCustomerNo);

        Clear(SalesLine);
        SalesLine.SetRange("Document No.", pSalesDocumentNo);
        case pSalesDocType of
            1:
                SalesLine.SetRange("Document Type", SalesLine."Document Type"::Quote);
            2:
                SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        end;
    end;

    var
        CustomerDataTransfer: Record "Customer Data Transfr Temp_Inc";
        SalesLine: Record "Sales Line";
}