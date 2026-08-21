report 70811 "Qr Code List Report_Inc"
{
    ApplicationArea = All;
    Caption = 'Qr Code List Report';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Qr Code List Report.rdlc';

    dataset
    {
        dataitem(TempVLE; "Value Entry")
        {
            UseTemporary = true;
            column(Ürün_No; "Item No.") { }
            column(Ürün_Ad; "Item Description") { }
            column(QRBarkod; Description) { }
            column(Seri_No; "User ID") { }
            column(SKT; "Document Date") { }
            column(Parti_No; "Job No.") { }
            column(GTIN; "Item Charge No.") { }
            column(Islem_Tarihi; "Posting Date") { }
            column(Lokasyon; "Location Code") { }
            column(GLN; "Job Task No.") { }
            column(İl; "Source No.") { }
            column(İlçe; "Order No.") { }
            column(Müşteri_Ad; "External Document No.") { }
            trigger OnPreDataItem()
            begin
                FillTempVLE();
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
                    field(StartDate; StartDate)
                    {
                        Caption = 'Start Date';
                        ApplicationArea = All;

                    }
                    field(EndDate; EndDate)
                    {
                        Caption = 'End Date';
                        ApplicationArea = All;

                    }
                    field(CustomerNo; CustomerNo)
                    {
                        Caption = 'Customer No.';
                        ApplicationArea = All;
                        TableRelation = Customer."No.";
                    }
                    field(ItemNo; ItemNo)
                    {
                        Caption = 'Item No.';
                        ApplicationArea = All;
                        tableRelation = Item."No.";
                    }
                    field(SKT; SKT)
                    {
                        Caption = 'SKT';
                        ApplicationArea = All;
                    }
                    field(PartyNo; PartyNo)
                    {
                        Caption = 'Party No.';
                        ApplicationArea = All;
                    }
                    field(SeriNo; SeriNo)
                    {
                        Caption = 'Seri No.';
                        ApplicationArea = All;
                    }
                }
            }
        }
        actions
        {
            area(Processing) { }
        }

        trigger OnOpenPage()
        begin
            StartDate := Today;
            EndDate := Today;
        end;
    }

    local procedure FillTempVLE()
    var
        LSerialNoList: Record "Serial No. Master-B2F";
        LItem: Record Item;
        LCustomer: Record Customer;
        LSalesShipmnt: Record "Sales Shipment Header";
        LDateTxt: Text[20];
    begin
        Clear(LSerialNoList);
        LSerialNoList.SetRange("Last Posting Date", StartDate, EndDate);
        LSerialNoList.SetRange(Status, LSerialNoList.Status::Shipped);
        if CustomerNo <> '' then
            LSerialNoList.SetRange("Customer No.", CustomerNo);
        if ItemNo <> '' then
            LSerialNoList.SetRange("Item No.", ItemNo);
        if SKT <> 0D then
            LSerialNoList.SetRange("Expiration Date", SKT);
        if PartyNo <> '' then
            LSerialNoList.SetRange("Lot No.", PartyNo);
        if SeriNo <> '' then
            LSerialNoList.SetRange("Serial No.", SeriNo);
        if LSerialNoList.FindSet() then
            repeat
                i += 1;
                TempVLE.Init();
                tempVLE."Entry No." := i;
                TempVLE."Item No." := LSerialNoList."Item No.";
                TempVLE."User ID" := LSerialNoList."Serial No."; //SeriNo --
                TempVLE."Job No." := CopyStr(LSerialNoList."Lot No.", 1, 20); //LotNo --
                TempVLE."Document Date" := LSerialNoList."Expiration Date"; //SKT --
                TempVLE."Location Code" := LSerialNoList."Location Code"; //Lokasyon--
                TempVLE."Posting Date" := LSerialNoList."Last Posting Date"; // Tarih--
                Clear(LItem);
                if LItem.Get(LSerialNoList."Item No.") then
                    TempVLE."Item Charge No." := LItem.GTIN; //GTIN**
                Clear(LCustomer);
                if LCustomer.Get(LSerialNoList."Customer No.") then begin
                    TempVLE."Job Task No." := LCustomer.GLN;  //GLN
                    TempVLE."External Document No." := CopyStr(LCustomer.Name, 1, 35); //Müşteri Adı
                end;
                Clear(LSalesShipmnt);
                if LSalesShipmnt.Get(LSerialNoList."Last Document No.") then begin
                    TempVLE."Source No." := CopyStr(LSalesShipmnt."Ship-to City", 1, 20); //Şehir --
                    TempVLE."Order No." := CopyStr(LSalesShipmnt."Ship-to County", 1, 20); //İlçe
                end;
                Clear(LDateTxt);
                LDateTxt := DelChr(Format(TempVLE."Document Date", 0, '<Day,2>.<Month,2>.<Year>'), '=', '.');
                TempVLE.Description := '01' + TempVLE."Item Charge No." + '21' + TempVLE."User ID" + ';17' + LDateTxt; //QrBarcode--
                TempVLE.Insert();
            until LSerialNoList.Next() = 0;
    end;



    var
        i: Integer;
        StartDate: Date;
        EndDate: Date;
        CustomerNo: Code[20];
        ItemNo: Code[20];
        SKT: Date;
        PartyNo: Code[30];
        SeriNo: Code[30];

}