codeunit 70801 "InciGeneral2_Inc"
{
    Permissions = TableData 17 = rimd,
                  TableData 21 = rimd,
                  TableData 25 = rimd,
                  TableData 32 = rimd,
                  TableData 45 = rimd,
                  TableData 113 = rimd,
                  TableData 115 = rimd,
                  TableData 123 = rimd,
                  TableData 125 = rimd,
                  TableData 169 = rimd,
                  TableData 203 = rimd,
                  TableData 271 = rimd,
                  TableData 379 = rimd,
                  TableData 380 = rimd,
                  TableData 480 = rimd,
                  TableData 5601 = rimd,
                  TableData 5802 = rimd;

    procedure InsertDimSetEntryIfMissing(prmDimCode: Code[20]; prmDimValue: Code[20]; prmEntryNo: Integer; prmDimSetID: Integer): Boolean
    var
        recDimSetEntry: Record "Dimension Set Entry";
    begin
        IF recDimSetEntry.GET(prmDimSetID, prmDimCode) THEN
            EXIT(FALSE); //Bu Set ID'de bu boyut kodu zaten var, dokunma

        recDimSetEntry.INIT();
        recDimSetEntry."Dimension Set ID" := prmDimSetID;
        recDimSetEntry."Dimension Code" := prmDimCode;
        recDimSetEntry.VALIDATE("Dimension Value Code", prmDimValue);
        recDimSetEntry.INSERT(TRUE);
        EXIT(TRUE);
    end;

    procedure CreateSerialNoTxt(pEntryNo: Integer; PItemLedgerEntryType: Enum "Item Ledger Entry Type")
    var
        LSerialNoMaster: Record "Serial No. Master-B2F";
        LItem: Record Item;
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        LineTxt: Text;
        ExpDateTxt: Text;
        FileName: Text;
        HasLines: Boolean;
    begin
        LSerialNoMaster.SetRange("Last ILE Entry No.", pEntryNo);
        LSerialNoMaster.SetRange("Last Entry Type", PItemLedgerEntryType);

        if LSerialNoMaster.FindSet() then begin
            TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
            repeat
                LItem.Get(LSerialNoMaster."Item No.");

                // 31.01.2029 -> 290131 (YYMMDD)
                if LSerialNoMaster."Expiration Date" <> 0D then
                    ExpDateTxt := Format(LSerialNoMaster."Expiration Date", 0, '<Year,2><Month,2><Day,2>')
                else
                    ExpDateTxt := '';

                // 01 + GTIN + 21 + Serial + ;17 + SKT + 10 + Lot
                LineTxt :=
                    '01' + LItem.GTIN +
                    '21' + LSerialNoMaster."Serial No." +
                    ';17' + ExpDateTxt +
                    '10' + LSerialNoMaster."Lot No.";

                OutStr.WriteText(LineTxt);
                OutStr.WriteText(); // satır sonu (CRLF)
                HasLines := true;
            until LSerialNoMaster.Next() = 0;
        end;

        if HasLines then begin
            TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
            FileName := StrSubstNo('SerialNo_%1.txt', pEntryNo);
            DownloadFromStream(InStr, 'Seri No Txt', '', '', FileName);
        end;
    end;

}
