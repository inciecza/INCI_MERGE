pageextension 70824 "Serial No. Entry-B2F_Inc" extends "Serial No. Entry-B2F"
{
    actions
    {
        addafter(ImportFromFile)
        {
            action(ImportGS1File_Inc)
            {
                Caption = 'Import QR code';
                Image = ImportCodes;
                ApplicationArea = All;
                ToolTip = 'Import serial numbers from a GS1 text file (01<GTIN>21<Serial No.>;17<YYMMDD>10<Lot No.>). Serial No., expiration date and lot no. are read from each line.';
                trigger OnAction()
                var
                    GS1Importer: Codeunit "Serial Importer_Inc";
                    TempShare: Record "Serial No. Set Entry-B2F" temporary;
                begin
                    TempShare.Copy(Rec, true); // share the page's temporary buffer
                    if GS1Importer.ImportToBuffer(
                        TempShare, SetIDFilter, SourceTypeFilter,
                        ItemNoFilter, VariantCodeFilter, ExpectedQty) > 0
                    then
                        HasChanges := true; // otherwise CommitAndGetSetID keeps the original set
                    UpdateSummary();
                    CurrPage.Update(false);
                end;
            }
        }
    }
    local procedure UpdateSummary()
    begin
        EnteredQty := GetCurrentPendingCount();
        if EnteredQty = 0 then
            EnteredQtyStyle := 'None'
        else
            if EnteredQty < ExpectedQty then
                EnteredQtyStyle := 'Unfavorable'
            else
                if EnteredQty = ExpectedQty then
                    EnteredQtyStyle := 'Favorable'
                else
                    EnteredQtyStyle := 'Ambiguous';
    end;

    local procedure GetCurrentPendingCount(): Integer
    var
        TempCount: Record "Serial No. Set Entry-B2F" temporary;
    begin
        TempCount.Copy(Rec, true);
        TempCount.Reset();
        TempCount.SetRange("Status", TempCount."Status"::Pending);
        exit(TempCount.Count());
    end;

    var
        ExpectedQty: Decimal;

        SetIDFilter: Integer;
        HasChanges: Boolean;
        SourceTypeFilter: Enum "Serial No. Source Type-B2F";
        ItemNoFilter: Code[20];
        VariantCodeFilter: Code[10];
        LotNoFilter: Code[50];
        LocationCodeFilter: Code[10];
        EnteredQty: Decimal;
        EnteredQtyStyle: Text;
        OriginalSetID: Integer;
}
