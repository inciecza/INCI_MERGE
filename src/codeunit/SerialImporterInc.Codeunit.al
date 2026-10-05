codeunit 70802 "Serial Importer_Inc"
{
    var
        ImportDialogLbl: Label 'Import GS1 Serial Numbers';
        ImportFilterLbl: Label 'Text Files (*.txt)|*.txt|CSV Files (*.csv)|*.csv|All Files (*.*)|*.*';
        EmptyFileMsg: Label 'The file contains no serial number lines.';
        ImportResultMsg: Label '%1 serial number(s) imported (%2 already present were skipped). Expected: %3.', Comment = '%1 = imported count; %2 = skipped count; %3 = expected qty';
        ExceedsExpectedQst: Label 'The file contains %1 serial number(s). Together with the %2 already entered this exceeds the expected quantity %3. Do you want to continue?', Comment = '%1 = file count; %2 = entered count; %3 = expected qty';
        InvalidLineErr: Label 'Line %1 could not be read: %2\\Line content: %3', Comment = '%1 = line no.; %2 = reason; %3 = line text';
        UnknownAIErr: Label 'unknown GS1 application identifier "%1"', Comment = '%1 = AI';
        FieldIncompleteErr: Label 'GS1 field %1 is incomplete', Comment = '%1 = AI';
        ValueTooLongErr: Label '%1 is longer than %2 characters', Comment = '%1 = field caption; %2 = max length';
        MissingSerialErr: Label 'no serial number (AI 21) found';
        InvalidDateErr: Label 'invalid expiration date "%1"', Comment = '%1 = date text';

    procedure ImportToBuffer(var TempSetEntry: Record "Serial No. Set Entry-B2F" temporary; SetID: Integer; SourceType: Enum "Serial No. Source Type-B2F"; ItemNo: Code[20]; VariantCode: Code[10]; ExpectedQty: Decimal): Integer
    var
        TempParsed: Record "Serial No. Set Entry-B2F" temporary;
        InStr: InStream;
        FileName: Text;
        LineText: Text;
        LineNo: Integer;
        NextNo: Integer;
        PendingCount: Integer;
        Imported: Integer;
        Skipped: Integer;
    begin
        if not UploadIntoStream(ImportDialogLbl, '', ImportFilterLbl, FileName, InStr) then
            exit(0);

        // Pass 1: parse and validate every line into a private buffer.
        while not InStr.EOS() do begin
            InStr.ReadText(LineText);
            LineNo += 1;
            LineText := CleanLine(LineText);
            if LineText <> '' then begin
                TempParsed.Init();
                TempParsed."Entry No." := LineNo;
                TempParsed."Set ID" := SetID;
                TempParsed."Source Type" := SourceType;
                TempParsed."Item No." := ItemNo;
                TempParsed."Variant Code" := VariantCode;
                TempParsed."Status" := TempParsed."Status"::Pending;
                ParseGS1Line(LineText, LineNo, TempParsed);
                TempParsed.Validate("Serial No.");
                TempParsed.Insert(false);
            end;
        end;

        if TempParsed.IsEmpty() then begin
            Message(EmptyFileMsg);
            exit(0);
        end;

        PendingCount := CountPending(TempSetEntry);
        if PendingCount + TempParsed.Count() > ExpectedQty then
            if not Confirm(ExceedsExpectedQst, false, TempParsed.Count(), PendingCount, ExpectedQty) then
                exit(0);

        // Pass 2: append to the page buffer, skipping serials that are already pending.
        TempSetEntry.Reset();
        NextNo := 1;
        if TempSetEntry.FindLast() then
            NextNo := TempSetEntry."Entry No." + 1;

        TempParsed.FindSet();
        repeat
            if IsAlreadyPending(TempSetEntry, TempParsed."Serial No.") then
                Skipped += 1
            else begin
                TempSetEntry := TempParsed;
                TempSetEntry."Entry No." := NextNo; // temporary PK is not auto-assigned
                NextNo += 1;
                TempSetEntry.Insert(true);
                Imported += 1;
            end;
        until TempParsed.Next() = 0;

        Message(ImportResultMsg, Imported, Skipped, ExpectedQty);
        exit(Imported);
    end;

    local procedure ParseGS1Line(LineText: Text; LineNo: Integer; var TempParsed: Record "Serial No. Set Entry-B2F" temporary)
    var
        GS: Char;
        Segment: Text;
        AI: Text;
        Value: Text;
        Pos: Integer;
    begin
        if LineText.StartsWith(']d2') then // scanner symbology prefix
            LineText := CopyStr(LineText, 4);
        GS := 29;
        LineText := LineText.Replace(Format(GS), ';');

        foreach Segment in LineText.Split(';') do begin
            Pos := 1;
            while Pos <= StrLen(Segment) do begin
                AI := CopyStr(Segment, Pos, 2);
                Pos += 2;
                case AI of
                    '01': // GTIN - fixed 14 digits, not used
                        begin
                            if StrLen(Segment) < Pos + 13 then
                                Error(InvalidLineErr, LineNo, StrSubstNo(FieldIncompleteErr, AI), LineText);
                            Pos += 14;
                        end;
                    '17': // expiration date - fixed 6 digits, YYMMDD
                        begin
                            if StrLen(Segment) < Pos + 5 then
                                Error(InvalidLineErr, LineNo, StrSubstNo(FieldIncompleteErr, AI), LineText);
                            TempParsed."Expiration Date" := ParseGS1Date(CopyStr(Segment, Pos, 6), LineNo, LineText);
                            Pos += 6;
                        end;
                    '21', '10': // serial / lot - variable length, runs to the end of the segment
                        begin
                            Value := CopyStr(Segment, Pos);
                            if Value = '' then
                                Error(InvalidLineErr, LineNo, StrSubstNo(FieldIncompleteErr, AI), LineText);
                            if AI = '21' then
                                TempParsed."Serial No." := CheckLength(Value, MaxStrLen(TempParsed."Serial No."), TempParsed.FieldCaption("Serial No."), LineNo, LineText)
                            else
                                TempParsed."Lot No." := CheckLength(Value, MaxStrLen(TempParsed."Lot No."), TempParsed.FieldCaption("Lot No."), LineNo, LineText);
                            Pos := StrLen(Segment) + 1;
                        end;
                    else
                        Error(InvalidLineErr, LineNo, StrSubstNo(UnknownAIErr, AI), LineText);
                end;
            end;
        end;

        if TempParsed."Serial No." = '' then
            Error(InvalidLineErr, LineNo, MissingSerialErr, LineText);
    end;

    // YYMMDD -> 20YY. Per GS1, DD = 00 means the last day of the month.
    local procedure ParseGS1Date(DateText: Text; LineNo: Integer; LineText: Text): Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
        LastDay: Integer;
    begin
        if not Evaluate(Year, CopyStr(DateText, 1, 2)) or
           not Evaluate(Month, CopyStr(DateText, 3, 2)) or
           not Evaluate(Day, CopyStr(DateText, 5, 2))
        then
            Error(InvalidLineErr, LineNo, StrSubstNo(InvalidDateErr, DateText), LineText);
        if (Month < 1) or (Month > 12) or (Day < 0) then
            Error(InvalidLineErr, LineNo, StrSubstNo(InvalidDateErr, DateText), LineText);

        Year += 2000;
        LastDay := Date2DMY(CalcDate('<CM>', DMY2Date(1, Month, Year)), 1);
        if Day = 0 then
            Day := LastDay;
        if Day > LastDay then
            Error(InvalidLineErr, LineNo, StrSubstNo(InvalidDateErr, DateText), LineText);
        exit(DMY2Date(Day, Month, Year));
    end;

    local procedure CheckLength(Value: Text; MaxLen: Integer; Caption: Text; LineNo: Integer; LineText: Text): Text
    begin
        if StrLen(Value) > MaxLen then
            Error(InvalidLineErr, LineNo, StrSubstNo(ValueTooLongErr, Caption, MaxLen), LineText);
        exit(Value);
    end;

    local procedure CleanLine(LineText: Text): Text
    var
        CR: Char;
        LF: Char;
        Tab: Char;
    begin
        CR := 13;
        LF := 10;
        Tab := 9;
        exit(DelChr(LineText, '<>', ' ' + Format(CR) + Format(LF) + Format(Tab)));
    end;

    local procedure CountPending(var TempSetEntry: Record "Serial No. Set Entry-B2F" temporary): Integer
    var
        TempCount: Record "Serial No. Set Entry-B2F" temporary;
    begin
        TempCount.Copy(TempSetEntry, true);
        TempCount.Reset();
        TempCount.SetRange("Status", TempCount."Status"::Pending);
        exit(TempCount.Count());
    end;

    local procedure IsAlreadyPending(var TempSetEntry: Record "Serial No. Set Entry-B2F" temporary; SerialNo: Code[50]): Boolean
    var
        TempCheck: Record "Serial No. Set Entry-B2F" temporary;
    begin
        TempCheck.Copy(TempSetEntry, true);
        TempCheck.Reset();
        TempCheck.SetRange("Serial No.", SerialNo);
        TempCheck.SetRange("Status", TempCheck."Status"::Pending);
        exit(not TempCheck.IsEmpty());
    end;
}
