report 70804 "Bid Sales Quote DT_Inc"
{
    ApplicationArea = All;
    Caption = 'Bid Sales Quote DT';
    UsageCategory = ReportsAndAnalysis;
    DefaultLayout = RDLC;
    RDLCLayout = './src/layout/Bid Sales Quote DT.rdlc';
    dataset
    {
        dataitem(BidQuoteLine; "Bid Quote Line-INC")
        {
            column(SelltoCustomerName; "Sell-to Customer Name")
            {
            }
            column(SelltoCustomerName2; '')
            {
            }
            column(SelltoCity; city)
            {
            }
            column(CompanyInfAddres; CompanyInformation.Address)
            { }
            column(CompanyInfAddres2; CompanyInformation."Address 2")
            { }
            column(CompanyInfPhone; CompanyInformation."Phone No.")
            { }
            column(CompanyInfFax; CompanyInformation."Fax No.")
            { }
            column(CompanyInfEMail; CompanyInfEMail)
            { }
            column(Description; "Item Description")
            { }

            column(Unit_of_Measure_Code; "Bid Unit of Measure")
            { }
            column(Quantity; Quantity)
            { }
            column(Unit_Price; "Unit Price")
            { }
            column(Amount; "Line Amount")
            { }

            column(ManufacturerCode; ManufacturerCode)
            { }
            column(ItemBarcode; ItemBarcode)
            { }
            column(LineNo; LineNo)
            { }
            dataitem("Bid Header-INC"; "Bid Header-INC")
            {
                DataItemLinkReference = BidQuoteLine;
                DataItemLink = "No." = FIELD("Bid No.");

                column(InciEczaID; "No.")
                { }
                column(IsinAdi; "Bid Name")
                { }
                column(AlımTuru; "Bid Type")
                { }
                column(HastaAdi; "Patient Name")
                { }

            }
            trigger OnPreDataItem()
            begin
                SetRange("Bid No.", GeneralBidNo);
                SetRange("Sell-to Customer No.", CustomerNo);
            end;

            trigger OnAfterGetRecord()
            var
                LItem: Record Item;
                LVendor: Record Vendor;
            begin
                Clear(ManufacturerCode);
                Clear(ItemBarcode);
                Clear(LItem);
                Clear(LineNo);
                LItem.SetLoadFields("No.", "GTIN");
                if LItem.Get("Item No.") then begin
                    LineNo += 1;
                    ItemBarcode := LItem.GTIN;
                    Clear(LVendor);
                    if LVendor.get(LItem."Vendor No.") then
                        ManufacturerCode := LVendor.Name;
                end;
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
    trigger OnPreReport()
    begin
        Clear(CompanyInformation);
        CompanyInformation.get();
        CompanyInfEMail := 'ihale@incieczadeposu.com';
    end;

    procedure SetParameters(pBidNo: Code[20]; pCustomer: Code[20])
    begin
        GeneralBidNo := pBidNo;
        CustomerNo := pCustomer;
    end;

    var
        CompanyInformation: Record "Company Information";
        CompanyInfEMail: Text[50];
        ManufacturerCode: Text[100];
        ItemBarcode: code[50];
        LineNo: Integer;
        GeneralBidNo: Code[20];
        CustomerNo: Code[20];
}
