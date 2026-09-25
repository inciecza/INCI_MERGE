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


}
