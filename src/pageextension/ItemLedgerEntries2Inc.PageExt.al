pageextension 70825 "Item Ledger Entries2_Inc" extends "Item Ledger Entries"
{
    actions
    {
        addfirst("Ent&ry")
        {
            action(QRCode_Inc)
            {
                ApplicationArea = All;
                Caption = 'Download QR Code List';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = CreateSerialNo;
                trigger OnAction()
                var
                    InciGeneral2Inc: Codeunit "InciGeneral2_Inc";
                begin
                    Clear(InciGeneral2Inc);
                    InciGeneral2Inc.CreateSerialNoTxt(Rec."Entry No.", Rec."Entry Type");
                end;
            }
            action(PackagingLabel_Inc)
            {
                ApplicationArea = All;
                Caption = 'Print Packaging Label';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Print;
                trigger OnAction()
                var
                    IncPackagingLabel: Report "Inc Packaging Label_Inc";
                begin
                    IncPackagingLabel.SetEntryNo(Rec."Entry No.");
                    IncPackagingLabel.RunModal();
                end;
            }
            action(ItemIdentificationLabel_Inc)
            {
                ApplicationArea = All;
                Caption = 'Print Item Identification Label';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Print;
                trigger OnAction()
                var
                    IncItemIdentLabel: Report "Inc Item Identification Label";
                begin
                    IncItemIdentLabel.SetEntryNo(Rec."Entry No.");
                    IncItemIdentLabel.RunModal();
                end;
            }
        }
    }
}
