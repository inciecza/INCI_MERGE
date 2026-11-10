report 70824 "Inc Packaging Label_Inc"
{
    ApplicationArea = All;
    Caption = 'Inc Packaging Label';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/IncPackagingLabel_Inc.rdlc';

    dataset
    {
        // Item Tracking Lines sayfası geçici (temporary) Tracking Specification kayıtlarıyla çalışır.
        // Satırlar SetTrackingSpecification ile rapora kopyalanır, Integer üzerinden döngü kurulur.
        dataitem(TrackingSpecLoop; Integer)
        {
            DataItemTableView = sorting(Number);

            dataitem(BoxLoop; Integer)
            {
                DataItemTableView = sorting(Number);

                column(DocCode; DocCodeTxt) { }
                column(ItemNo; Item."No.") { }
                column(ItemDescription; Item.Description) { }
                column(LotNo; TempTrackingSpecification."Lot No.") { }
                column(ProductionDate; Format(ProductionDate, 0, '<Day,2>.<Month,2>.<Year4>')) { }
                column(ExpirationDate; Format(TempTrackingSpecification."Expiration Date", 0, '<Day,2>.<Month,2>.<Year4>')) { }
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
                if TempTrackingSpecification.IsEmpty() then
                    Error(TrackingSpecRequiredErr);
                SetRange(Number, 1, TempTrackingSpecification.Count());
            end;

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempTrackingSpecification.FindFirst()
                else
                    TempTrackingSpecification.Next();

                if not Item.Get(TempTrackingSpecification."Item No.") then
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
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        ProductionDate: Date;
        BoxCount: Integer;
        InnerQty: Decimal;
        StorageConditionTxt: Text;
        DocCodeTxt: Label 'KG.PR.024.E34', Locked = true;
        TrackingSpecRequiredErr: Label 'Bu rapor Madde İzleme Satırları sayfasındaki butondan çalıştırılmalıdır.', Locked = true;

    procedure SetTrackingSpecification(var SourceTrackingSpecification: Record "Tracking Specification" temporary)
    begin
        TempTrackingSpecification.Reset();
        TempTrackingSpecification.DeleteAll();
        if SourceTrackingSpecification.FindSet() then
            repeat
                TempTrackingSpecification := SourceTrackingSpecification;
                TempTrackingSpecification.Insert();
            until SourceTrackingSpecification.Next() = 0;
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
