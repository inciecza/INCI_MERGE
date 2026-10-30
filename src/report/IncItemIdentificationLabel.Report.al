report 70825 "Inc Item Identification Label"
{
    ApplicationArea = All;
    Caption = 'Inc Item Identification Label';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Inc Item Identification Label.rdlc';

    dataset
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.");

            dataitem(BoxLoop; Integer)
            {
                DataItemTableView = sorting(Number);

                column(DocCode; DocCodeTxt) { }
                column(ItemNo; Item."No.") { }
                column(ItemDescription; Item.Description) { }
                column(LotNo; ItemLedgerEntry."Lot No.") { }
                column(ManufacturerName; ManufacturerName) { }
                column(ManufacturerLotNo; ItemLedgerEntry."Manufacturer Lot No.-INC") { }
                column(EntryDate; Format(EntryDate, 0, '<Day,2>.<Month,2>.<Year4>')) { }
                column(ExpirationDate; Format(ExpirationDate, 0, '<Day,2>.<Month,2>.<Year4>')) { }
                column(RetestDate; '') { }
                column(QuantityTxt; GetBoxQuantityTxt(Number)) { }
                column(BoxNo; Format(Number) + ' / ' + Format(BoxCount)) { }
                column(StorageCondition; StorageConditionTxt) { }

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, BoxCount);
                end;
            }

            trigger OnPreDataItem()
            begin
                if EntryNoToPrint = 0 then
                    Error(EntryNoRequiredErr);
                SetRange("Entry No.", EntryNoToPrint);
                if BoxCount < 1 then
                    Error(BoxCountErr);
            end;

            trigger OnAfterGetRecord()
            begin
                if not Item.Get("Item No.") then
                    Clear(Item);
                StorageConditionTxt := GetStorageCondition(Item."Warehouse Class Code");
                CheckQuantities();
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ManufacturerNameField; ManufacturerName)
                    {
                        ApplicationArea = All;
                        Caption = 'Üretici Adı';
                        ToolTip = 'Specifies the manufacturer name printed on the label.';
                    }
                    field(EntryDateField; EntryDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Giriş Tarihi';
                        ToolTip = 'Specifies the entry date printed on the label.';
                    }
                    field(ExpirationDateField; ExpirationDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Son Kullanma Tarihi';
                        ToolTip = 'Specifies the expiration date printed on the label.';
                    }
                    field(BoxCountField; BoxCount)
                    {
                        ApplicationArea = All;
                        Caption = 'Ambalaj Adedi';
                        MinValue = 1;
                        ToolTip = 'Specifies how many labels are printed.';
                    }
                    field(FirstBoxQtyField; FirstBoxQty)
                    {
                        ApplicationArea = All;
                        Caption = 'İlk Koli Miktar';
                        MinValue = 0;
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies the quantity on the first label.';
                    }
                    field(LastBoxQtyField; LastBoxQty)
                    {
                        ApplicationArea = All;
                        Caption = 'Son Koli Miktar';
                        MinValue = 0;
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies the quantity on the last label. The boxes in between share the remainder equally.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            if EntryDate = 0D then
                EntryDate := Today();
            if BoxCount < 1 then
                BoxCount := 1;
        end;
    }

    var
        Item: Record Item;
        ManufacturerName: Text[100];
        EntryDate: Date;
        ExpirationDate: Date;
        BoxCount: Integer;
        FirstBoxQty: Decimal;
        LastBoxQty: Decimal;
        StorageConditionTxt: Text;
        EntryNoToPrint: Integer;
        EntryNoRequiredErr: Label 'Bu rapor Madde Hareketleri sayfasındaki butondan çalıştırılmalıdır.', Locked = true;
        DocCodeTxt: Label 'KG.PR.024.EK01.00', Locked = true;
        BoxCountErr: Label 'Ambalaj Adedi must be at least 1.';
        QtyMismatchErr: Label 'İlk ve son koli miktarı toplamı (%1) madde hareketi miktarını (%2) aşıyor.', Comment = '%1 = first + last box quantity, %2 = entry quantity';

    procedure SetEntryNo(EntryNo: Integer)
    begin
        EntryNoToPrint := EntryNo;
    end;

    local procedure CheckQuantities()
    begin
        if BoxCount <= 2 then
            exit;
        if FirstBoxQty + LastBoxQty > Abs(ItemLedgerEntry.Quantity) then
            Error(QtyMismatchErr, FirstBoxQty + LastBoxQty, Abs(ItemLedgerEntry.Quantity));
    end;

    local procedure GetBoxQuantityTxt(BoxNo: Integer): Text
    var
        BoxQty: Decimal;
    begin
        case true of
            BoxCount = 1:
                BoxQty := Abs(ItemLedgerEntry.Quantity);
            BoxNo = 1:
                BoxQty := FirstBoxQty;
            BoxNo = BoxCount:
                BoxQty := LastBoxQty;
            else
                BoxQty := (Abs(ItemLedgerEntry.Quantity) - FirstBoxQty - LastBoxQty) / (BoxCount - 2);
        end;
        exit(Format(BoxQty) + ' ' + ItemLedgerEntry."Unit of Measure Code");
    end;

    local procedure GetStorageCondition(WarehouseClassCode: Code[10]): Text
    begin
        case UpperCase(WarehouseClassCode) of
            'DONDURUCU':
                exit('-25°C ila -15°C Saklama Koşulu');
            'SERIN_ODA':
                exit('8-15°C Saklama Koşulu');
            'SOGUK_ODA':
                exit('2-8°C Saklama Koşulu');
            '':
                exit('20-25°C Saklama Koşulu');
        end;
        exit('');
    end;
}
