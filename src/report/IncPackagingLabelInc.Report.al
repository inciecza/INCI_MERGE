report 70824 "Inc Packaging Label_Inc"
{
    ApplicationArea = All;
    Caption = 'Inc Packaging Label';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/IncPackagingLabel_Inc.rdlc';

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
                column(ProductionDate; Format(ProductionDate, 0, '<Day,2>.<Month,2>.<Year4>')) { }
                column(ExpirationDate; Format(ItemLedgerEntry."Expiration Date", 0, '<Day,2>.<Month,2>.<Year4>')) { }
                column(BoxNo; Format(Number) + ' / ' + Format(BoxCount)) { }
                column(InnerQty; Format(InnerQty)) { }
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
            end;

            trigger OnAfterGetRecord()
            begin
                if not Item.Get("Item No.") then
                    Clear(Item);
                StorageConditionTxt := GetStorageCondition(Item."Warehouse Class Code");
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
                    field(ProductionDateField; ProductionDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Üretim Tarihi', Locked = true;
                        ToolTip = 'Specifies the production date printed on the label.';
                    }
                    field(BoxCountField; BoxCount)
                    {
                        ApplicationArea = All;
                        Caption = 'Koli Adedi', Locked = true;
                        MinValue = 1;
                        ToolTip = 'Specifies how many box labels are printed.';
                    }
                    field(InnerQtyField; InnerQty)
                    {
                        ApplicationArea = All;
                        Caption = 'Koli İç Adeti', Locked = true;
                        MinValue = 0;
                        DecimalPlaces = 0 : 5;
                        ToolTip = 'Specifies the quantity inside each box.';
                    }
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        BoxCount := 1;
    end;

    var
        Item: Record Item;
        ProductionDate: Date;
        BoxCount: Integer;
        InnerQty: Decimal;
        StorageConditionTxt: Text;
        EntryNoToPrint: Integer;
        DocCodeTxt: Label 'KG.PR.024.E34', Locked = true;
        EntryNoRequiredErr: Label 'Bu rapor Madde Hareketleri sayfasındaki butondan çalıştırılmalıdır.', Locked = true;

    procedure SetEntryNo(EntryNo: Integer)
    begin
        EntryNoToPrint := EntryNo;
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
