report 70820 "Item Ledger Entry Report_Inc"
{
    ApplicationArea = All;
    Caption = 'Item Ledger Entry Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Item Ledger Entry Report.rdlc';

    dataset
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableView = sorting("Item No.", "Posting Date", "Entry No.");
            RequestFilterFields = "Item No.";

            column(CompanyName; CompanyName) { }
            column(StartDateText; StartDateText) { }
            column(EndDateText; EndDateText) { }
            column(LocationCodeText; LocationCode) { }
            column(ItemNo; "Item No.") { }
            column(ItemDescription; Description) { }
            column(PostingDateText; Format("Posting Date", 0, '<Day,2>.<Month,2>.<Year4>')) { }
            column(Quantity; Quantity) { }
            column(BalanceQty; BalanceQty) { }
            column(OpeningBalance; OpeningBalance) { }
            column(EntryTypeText; EntryTypeText) { }
            column(DocumentTypeText; DocumentTypeText) { }
            column(Description; "Source Description-B2F") { }

            trigger OnPreDataItem()
            begin
                if (StartDate <> 0D) and (EndDate <> 0D) then
                    SetRange("Posting Date", StartDate, EndDate)
                else
                    if StartDate <> 0D then
                        SetFilter("Posting Date", '%1..', StartDate)
                    else
                        if EndDate <> 0D then
                            SetFilter("Posting Date", '..%1', EndDate);

                if ItemNo <> '' then
                    Setfilter("Item No.", ItemNo);

                if LocationCode <> '' then
                    SetRange("Location Code", LocationCode);

                StartDateText := Format(StartDate, 0, '<Day,2>.<Month,2>.<Year4>');
                EndDateText := Format(EndDate, 0, '<Day,2>.<Month,2>.<Year4>');
                LastItemNo := '';
            end;

            trigger OnAfterGetRecord()
            begin
                // Ürün değiştiğinde devir bakiyesini (başlangıç tarihinden önceki hareketler) hesapla
                if "Item No." <> LastItemNo then begin
                    LastItemNo := "Item No.";
                    OpeningBalance := CalcOpeningBalance("Item No.");
                    BalanceQty := OpeningBalance;
                end;

                BalanceQty += Quantity;
                EntryTypeText := GetEntryTypeText("Entry Type");
                DocumentTypeText := GetDocumentTypeText("Document Type");
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Filtreler)
                {
                    Caption = 'Filtreler', locked = true;
                    field(ItemNoField; ItemNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Ürün No', locked = true;
                        ToolTip = 'Raporun getireceği ürün numarasını belirtir.', Locked = true;
                        TableRelation = Item;
                    }
                    field(StartDateField; StartDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Başlangıç Tarihi', locked = true;
                        ToolTip = 'Posting Date alanına uygulanacak başlangıç tarihini belirtir.', Locked = true;
                    }
                    field(EndDateField; EndDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Bitiş Tarihi', locked = true;
                        ToolTip = 'Posting Date alanına uygulanacak bitiş tarihini belirtir.', Locked = true;
                    }
                    field(LocationCodeField; LocationCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Konum Kodu', locked = true;
                        TableRelation = Location;
                        ToolTip = 'Raporun getireceği konum kodunu belirtir.', locked = true;
                    }
                }
            }
        }
    }



    local procedure CalcOpeningBalance(pItemNoToCalc: Code[20]): Decimal
    var
        ItemLedgerEntry2: Record "Item Ledger Entry";
    begin
        if StartDate = 0D then
            exit(0);

        ItemLedgerEntry2.SetCurrentKey("Item No.", "Posting Date");
        ItemLedgerEntry2.SetRange("Item No.", pItemNoToCalc);
        ItemLedgerEntry2.SetFilter("Posting Date", '<%1', StartDate);
        if LocationCode <> '' then
            ItemLedgerEntry2.SetRange("Location Code", LocationCode);
        ItemLedgerEntry2.CalcSums(Quantity);
        exit(ItemLedgerEntry2.Quantity);
    end;

    local procedure GetEntryTypeText(EntryType: Enum "Item Ledger Entry Type"): Text
    begin
        case EntryType of
            EntryType::Purchase:
                exit('Satınalma');
            EntryType::Sale:
                exit('Satış');
            EntryType::"Positive Adjmt.":
                exit('Pozitif Düzeltme');
            EntryType::"Negative Adjmt.":
                exit('Negatif Düzeltme');
            EntryType::Transfer:
                exit('Transfer');
            EntryType::Consumption:
                exit('Sarf');
            EntryType::Output:
                exit('Çıktı');
            EntryType::"Assembly Consumption":
                exit('Montaj Sarfı');
            EntryType::"Assembly Output":
                exit('Montaj Çıktısı');
        end;
        exit('');
    end;

    local procedure GetDocumentTypeText(DocumentType: Enum "Item Ledger Document Type"): Text
    begin
        case DocumentType of
            DocumentType::"Sales Shipment":
                exit('Satış Sevk İrsaliyesi');
            DocumentType::"Sales Invoice":
                exit('Satış Faturası');
            DocumentType::"Sales Return Receipt":
                exit('Satış İade İrsaliyesi');
            DocumentType::"Sales Credit Memo":
                exit('Satış İade Faturası');
            DocumentType::"Purchase Receipt":
                exit('Satınalma Alım İrsaliyesi');
            DocumentType::"Purchase Invoice":
                exit('Satınalma Faturası');
            DocumentType::"Purchase Return Shipment":
                exit('Satınalma İade Sevkiyatı');
            DocumentType::"Purchase Credit Memo":
                exit('Satınalma İade Faturası');
            DocumentType::"Transfer Shipment":
                exit('Transfer Sevkiyatı');
            DocumentType::"Transfer Receipt":
                exit('Transfer İrsaliyesi');
            DocumentType::"Service Shipment":
                exit('Servis Sevkiyatı');
            DocumentType::"Service Invoice":
                exit('Servis Faturası');
            DocumentType::"Service Credit Memo":
                exit('Servis İade Faturası');
            DocumentType::"Posted Assembly":
                exit('Kayıtlı Montaj');
            DocumentType::"Inventory Receipt":
                exit('Envanter İrsaliyesi');
            DocumentType::"Inventory Shipment":
                exit('Envanter Sevkiyatı');
            DocumentType::"Direct Transfer":
                exit('Doğrudan Transfer');
        end;
        exit('');
    end;

    var
        StartDate: Date;
        EndDate: Date;
        LocationCode: Code[10];
        StartDateText: Text;
        EndDateText: Text;
        LastItemNo: Code[20];
        OpeningBalance: Decimal;
        BalanceQty: Decimal;
        EntryTypeText: Text;
        DocumentTypeText: Text;
        ItemNo: Text[50];
}