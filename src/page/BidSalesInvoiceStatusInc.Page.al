page 70807 "Bid Sales Inv. Status_Inc"
{
    ApplicationArea = All;
    Caption = 'Bid Sales Invoices Statement';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "Sales Invoice Header";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    RefreshOnActivate = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Filters';

                field(StartDateFilterField; StartDateFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Start Date';
                    ToolTip = 'Specifies the first invoice date to include.';

                    trigger OnValidate()
                    begin
                        LoadData();
                    end;
                }
                field(EndDateFilterField; EndDateFilter)
                {
                    ApplicationArea = All;
                    Caption = 'End Date';
                    ToolTip = 'Specifies the last invoice date to include.';

                    trigger OnValidate()
                    begin
                        LoadData();
                    end;
                }
                field(StatusFilterField; StatusFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Transaction Status';
                    OptionCaption = 'All,Processed,Not Processed';
                    ToolTip = 'Specifies whether to show all invoices, only processed invoices or only invoices that are not processed yet.';

                    trigger OnValidate()
                    begin
                        LoadData();
                    end;
                }
                field(CustomerNoFilterField; CustomerNoFilter)
                {
                    ApplicationArea = All;
                    Caption = 'Customer No.';
                    ToolTip = 'Specifies the customer number to filter by. Leave empty to show all customers.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        LCustomer: Record Customer;
                    begin
                        LCustomer.SetFilter("Customer Group_Inc", '%1|%2',
                            LCustomer."Customer Group_Inc"::"State Hospital",
                            LCustomer."Customer Group_Inc"::"Univertsity Hospital");
                        if Page.RunModal(0, LCustomer) in [Action::LookupOK, Action::OK] then begin
                            CustomerNoFilter := LCustomer."No.";
                            Text := LCustomer."No.";
                            LoadData();
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        LoadData();
                    end;
                }
            }

            repeater(General)
            {
                field(Year; YearText)
                {
                    ApplicationArea = All;
                    Caption = 'Year';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
                field(Month; MonthText)
                {
                    ApplicationArea = All;
                    Caption = 'Month';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
                field(BidTransactionStatus; Rec."Bid Transaction Status_Inc")
                {
                    ApplicationArea = All;
                    Caption = 'Processed';
                    Editable = true;
                    StyleExpr = RowStyle;
                    ToolTip = 'Specifies whether the bid invoice has been processed. Use the Update Invoices action to write the changes to the posted sales invoices.';

                    trigger OnValidate()
                    begin
                        SetRowStyle();
                        CurrPage.Update(true);
                    end;
                }
                field(InvoiceDate; Rec."Posting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice Date';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
                field(InvoiceNo; Rec."External Document No.")
                {
                    ApplicationArea = All;
                    Caption = 'Invoice No.';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
                field(CustomerNo; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = All;
                    Caption = 'Customer No.';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
                field(CustomerName; Rec."Sell-to Customer Name")
                {
                    ApplicationArea = All;
                    Caption = 'Customer Name';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
                field(ShipToName; Rec."Ship-to Name")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to Name';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
                field(ShipToCity; Rec."Ship-to City")
                {
                    ApplicationArea = All;
                    Caption = 'Ship-to City';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
                field(Description; BidClassText)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
                field(TotalAmount; AmountValue)
                {
                    ApplicationArea = All;
                    Caption = 'Total Amount';
                    Editable = false;
                    AutoFormatType = 1;
                    StyleExpr = RowStyle;
                }
                field(RegionManager; RegionManagerName)
                {
                    ApplicationArea = All;
                    Caption = 'Region Manager';
                    Editable = false;
                    StyleExpr = RowStyle;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Reloads the invoices using the selected filters. Unsaved changes are discarded.';

                trigger OnAction()
                begin
                    LoadData();
                end;
            }
            action(UpdateInvoices)
            {
                ApplicationArea = All;
                Caption = 'Update Invoices';
                Image = Post;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Writes the Processed values shown on this page to the posted sales invoices.';

                trigger OnAction()
                begin
                    UpdateInvoiceHeaders();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        StartDateFilter := CalcDate('<-CM>', Today);
        EndDateFilter := Today;
        LoadData();
    end;

    trigger OnAfterGetRecord()
    var
        LBidHeader: Record "Bid Header-INC";
        LSalesPerson: Record "Salesperson/Purchaser";
    begin
        YearText := Format(Date2DMY(Rec."Posting Date", 3));
        MonthText := Format(Date2DMY(Rec."Posting Date", 2));

        if not Amounts.Get(Rec."No.", AmountValue) then
            AmountValue := 0;

        BidClassText := '';
        if LBidHeader.Get(Rec."Bid No.INC") then
            BidClassText := Format(LBidHeader."Bid Class");

        RegionManagerName := '';
        if LSalesPerson.Get(Rec."Salesperson Code") then
            RegionManagerName := LSalesPerson.Name;

        SetRowStyle();
    end;

    var
        Amounts: Dictionary of [Code[20], Decimal];
        StartDateFilter: Date;
        EndDateFilter: Date;
        StatusFilter: Option All,Processed,"Not Processed";
        CustomerNoFilter: Text[250];
        YearText: Text[4];
        MonthText: Text[2];
        BidClassText: Text[50];
        RegionManagerName: Text[50];
        AmountValue: Decimal;
        RowStyle: Text;
        DateOrderErr: Label 'Start Date cannot be greater than End Date.';
        UpdatedMsg: Label '%1 invoice(s) updated.';
        ConfirmUpdateQst: Label 'Do you want to update the Processed status of the posted sales invoices?';

    local procedure LoadData()
    var
        LHeader: Record "Sales Invoice Header";
        LCustomer: Record Customer;
    begin
        if (StartDateFilter <> 0D) and (EndDateFilter <> 0D) and (StartDateFilter > EndDateFilter) then
            Error(DateOrderErr);

        Rec.Reset();
        Rec.DeleteAll();
        Clear(Amounts);

        LHeader.SetRange(Cancelled, false);

        case true of
            (StartDateFilter <> 0D) and (EndDateFilter <> 0D):
                LHeader.SetRange("Posting Date", StartDateFilter, EndDateFilter);
            StartDateFilter <> 0D:
                LHeader.SetFilter("Posting Date", '%1..', StartDateFilter);
            EndDateFilter <> 0D:
                LHeader.SetFilter("Posting Date", '..%1', EndDateFilter);
        end;

        case StatusFilter of
            StatusFilter::Processed:
                LHeader.SetRange("Bid Transaction Status_Inc", true);
            StatusFilter::"Not Processed":
                LHeader.SetRange("Bid Transaction Status_Inc", false);
        end;

        if CustomerNoFilter <> '' then
            LHeader.SetFilter("Sell-to Customer No.", CustomerNoFilter);

        if LHeader.FindSet() then
            repeat
                if LCustomer.Get(LHeader."Sell-to Customer No.") then
                    if LCustomer."Customer Group_Inc" in [
                        LCustomer."Customer Group_Inc"::"State Hospital",
                        LCustomer."Customer Group_Inc"::"Univertsity Hospital"]
                    then begin
                        LHeader.CalcFields(Amount);
                        Amounts.Add(LHeader."No.", LHeader.Amount);
                        Rec := LHeader;
                        Rec.Insert();
                    end;
            until LHeader.Next() = 0;

        Rec.SetCurrentKey("Posting Date");
        Rec.Ascending(false);
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    local procedure UpdateInvoiceHeaders()
    var
        StatusMgt: Codeunit InciGeneral2_Inc;
        TempBookmark: Record "Sales Invoice Header" temporary;
        UpdatedCount: Integer;
    begin
        if not Confirm(ConfirmUpdateQst, false) then
            exit;

        TempBookmark.Copy(Rec, true);
        if TempBookmark.FindSet() then
            repeat
                if StatusMgt.SetBidTransactionStatus(TempBookmark."No.", TempBookmark."Bid Transaction Status_Inc") then
                    UpdatedCount += 1;
            until TempBookmark.Next() = 0;

        Message(UpdatedMsg, UpdatedCount);
        LoadData();
    end;

    local procedure SetRowStyle()
    begin
        // Processed            -> green
        // Not processed > 30 d -> red
        // Otherwise            -> standard
        if Rec."Bid Transaction Status_Inc" then
            RowStyle := 'Favorable'
        else
            if Today - Rec."Posting Date" > 30 then
                RowStyle := 'Unfavorable'
            else
                RowStyle := 'Standard';
    end;
}
