page 70806 "Bid Sales List_Inc"
{
    ApplicationArea = All;
    Caption = 'General Bid List';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "Bid Sales List Buffer_Inc";
    SourceTableTemporary = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    RefreshOnActivate = false;

    layout
    {
        area(Content)
        {
            group(Filtreler)
            {
                Caption = 'Filtreler', locked = true;

                field(BidClassFilterField; BidClassFilter)
                {
                    ApplicationArea = All;
                    Caption = 'İhale Durumu', locked = true;
                    ShowMandatory = true;
                    ToolTip = 'Zorunlu. Doğrudan Temin, Açık İhale, DMO veya DMO Kataloğu seçin.', locked = true;
                }
                field(StartDateFilterField; StartDateFilter)
                {
                    ApplicationArea = All;
                    Caption = 'İhale Başlangıç Tarihi', locked = true;
                    ShowMandatory = true;
                    ToolTip = 'Zorunlu. İhale tarihi bu tarihten itibaren listelenir.', locked = true;
                }
                field(EndDateFilterField; EndDateFilter)
                {
                    ApplicationArea = All;
                    Caption = 'İhale Bitiş Tarihi', locked = true;
                    ShowMandatory = true;
                    ToolTip = 'Zorunlu. İhale tarihi bu tarihe kadar (dahil) listelenir.', locked = true;
                }
                field(CustomerNoFilterField; CustomerNoFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Müşteri No.', locked = true;
                    TableRelation = Customer."No.";
                    ToolTip = 'İsteğe bağlı. Müşteri listesinden müşteri seçin.', locked = true;
                }
                field(CityFilterField; CityFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Şehir', locked = true;
                    ToolTip = 'İsteğe bağlı. Şehir adının tamamını veya bir kısmını yazın.', locked = true;
                }
            }

            repeater(General)
            {
                Editable = false;

                field(BidClass; Rec."Bid Class")
                {
                    ApplicationArea = All;
                }
                field(BidYear; Rec."Bid Year")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                }
                field(BidMonth; Rec."Bid Month")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                }
                field(BidRegistrationNo; Rec."Bid Registration No.")
                {
                    ApplicationArea = All;
                }
                field(BidDateHour; Rec."Bid Date-Hour")
                {
                    ApplicationArea = All;
                }
                field(CustomerNo; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                }
                field(CustomerName; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                }
                field(DocumentLineNo; Rec."Document Line No.")
                {
                    ApplicationArea = All;
                }
                field(ItemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                }
                field(GTIN; Rec.GTIN)
                {
                    ApplicationArea = All;
                }
                field(ItemDescription; Rec."Item Description")
                {
                    ApplicationArea = All;
                }
                field(ManufacturerName; Rec."Manufacturer Name")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field(UnitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
                field(DirectUnitCost; Rec."Direct Unit Cost")
                {
                    ApplicationArea = All;
                }
                field(BidTotalCost; Rec."Bid Total Cost")
                {
                    ApplicationArea = All;
                }
                field(LineAmount; Rec."Line Amount")
                {
                    ApplicationArea = All;
                }
                field(CompetitorName; Rec."Competitor Name")
                {
                    ApplicationArea = All;
                }
                field(CompetitorUnitPrice; Rec."Competitor Unit Price")
                {
                    ApplicationArea = All;
                }
                field(Won; Rec.Won)
                {
                    ApplicationArea = All;
                }
                field(ActiveIngredient; Rec."Active Ingredient")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetData)
            {
                ApplicationArea = All;
                Caption = 'Listele', locked = true;
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Seçilen filtrelere göre ihale satırlarını getirir.', locked = true;

                trigger OnAction()
                begin
                    GetBidData();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        StartDateFilter := CalcDate('<-CM>', Today);
        EndDateFilter := Today;
    end;

    var
        BidClassFilter: Enum "Bid Class-INC";
        StartDateFilter: Date;
        EndDateFilter: Date;
        CustomerNoFilter: Code[20];
        CityFilter: Text[30];
        MissingDatesErr: Label 'Lütfen İhale Başlangıç ve Bitiş Tarihi seçiniz.', locked = true;
        DateOrderErr: Label 'Başlangıç Tarihi, Bitiş Tarihinden büyük olamaz.', locked = true;

    local procedure GetBidData()
    var
        LBidHeader: Record "Bid Header-INC";
        LBidLine: Record "Bid Quote Line-INC";
        LComparison: Record "Bid Comparison-INC";
        LEntryNo: Integer;
        LHasCompetitor: Boolean;
    begin
        if (StartDateFilter = 0D) or (EndDateFilter = 0D) then
            Error(MissingDatesErr);
        if StartDateFilter > EndDateFilter then
            Error(DateOrderErr);

        Rec.Reset();
        Rec.DeleteAll();

        LBidHeader.SetRange("Bid Class", BidClassFilter);
        LBidHeader.SetFilter("Bid Date-Hour", '>=%1&<%2',
            CreateDateTime(StartDateFilter, 0T), CreateDateTime(EndDateFilter + 1, 0T));
        if CustomerNoFilter <> '' then
            LBidHeader.SetRange("Sell-to Customer No.", CustomerNoFilter);

        if LBidHeader.FindSet() then
            repeat
                LBidLine.Reset();
                LBidLine.SetRange("Bid No.", LBidHeader."No.");
                if CityFilter <> '' then
                    LBidLine.SetFilter(City, '@*%1*', CityFilter);
                if LBidLine.FindSet() then
                    repeat
                        LComparison.Reset();
                        LComparison.SetRange("Bid No.", LBidHeader."No.");
                        LComparison.SetRange("Bid Type", LBidHeader."Bid Class");
                        LComparison.SetRange("Item No.", LBidLine."Item No.");
                        LHasCompetitor := LComparison.FindSet();

                        // Rakip varsa her rakip için bir satır, yoksa rakipsiz tek satır
                        repeat
                            LEntryNo += 1;
                            FillBufferLine(LEntryNo, LBidHeader, LBidLine);
                            if LHasCompetitor then begin
                                Rec."Competitor Name" := LComparison."Comparison Competitor Name";
                                Rec."Competitor Unit Price" := LComparison."Competitor Unit Price";
                            end;
                            Rec.Insert();
                        until (not LHasCompetitor) or (LComparison.Next() = 0);
                    until LBidLine.Next() = 0;
            until LBidHeader.Next() = 0;

        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    local procedure FillBufferLine(pEntryNo: Integer; pBidHeader: Record "Bid Header-INC"; pBidLine: Record "Bid Quote Line-INC")
    begin
        Rec.Init();
        Rec."Entry No." := pEntryNo;
        Rec."Bid Class" := pBidHeader."Bid Class";
        if pBidHeader."Bid Date-Hour" <> 0DT then begin
            Rec."Bid Year" := Date2DMY(DT2Date(pBidHeader."Bid Date-Hour"), 3);
            Rec."Bid Month" := Date2DMY(DT2Date(pBidHeader."Bid Date-Hour"), 2);
        end;
        Rec."Bid Date-Hour" := pBidHeader."Bid Date-Hour";
        Rec."Bid Registration No." := pBidHeader."Bid Registration No.";
        Rec."Sell-to Customer No." := pBidHeader."Sell-to Customer No.";
        Rec."Sell-to Customer Name" := pBidHeader."Sell-to Customer Name";
        Rec.City := pBidLine.City;
        Rec."Document Line No." := pBidLine."Document Line No.";
        Rec."Item No." := pBidLine."Item No.";
        Rec.GTIN := pBidLine.GTIN;
        Rec."Item Description" := pBidLine."Item Description";
        Rec."Manufacturer Name" := GetManufacturerName(pBidLine."Item No.");
        Rec.Quantity := pBidLine.Quantity;
        Rec."Unit Price" := pBidLine."Unit Price";
        Rec."Direct Unit Cost" := pBidLine."Direct Unit Cost";
        Rec."Bid Total Cost" := pBidLine.Quantity * pBidLine."Direct Unit Cost";
        Rec."Line Amount" := pBidLine."Line Amount";
        Rec.Won := pBidLine.Won;
        Rec."Active Ingredient" := pBidLine."Active Ingredient";
    end;

    local procedure GetManufacturerName(pItemNo: Code[20]): Text[50]
    var
        LItem: Record Item;
        LManufacturer: Record Manufacturer;
    begin
        if LItem.Get(pItemNo) then
            if LManufacturer.Get(LItem."Manufacturer Code") then
                exit(LManufacturer.Name);
    end;
}
