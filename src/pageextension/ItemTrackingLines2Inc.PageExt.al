pageextension 70830 "Item Tracking Lines2_Inc" extends "Item Tracking Lines"
{
    actions
    {
        // FunctionsSupply / FunctionsDemand grupları kaynak tipine göre gizlendiği için
        // buton doğrudan processing alanına eklendi; giriş ve çıkış satırlarında hep görünür.
        addlast(processing)
        {
            action(PackagingLabel_Inc)
            {
                ApplicationArea = All;
                Caption = 'Print Packaging Label';
                Image = Print;
                ToolTip = 'Prints the packaging label for the selected item tracking lines.';

                trigger OnAction()
                var
                    TempSelectedTrackingSpec: Record "Tracking Specification" temporary;
                    IncPackagingLabel: Report "Inc Packaging Label_Inc";
                begin
                    // Sayfanın geçici tablosunu paylaş, sadece seçili satırları filtrele
                    TempSelectedTrackingSpec.Copy(Rec, true);
                    CurrPage.SetSelectionFilter(TempSelectedTrackingSpec);
                    IncPackagingLabel.SetTrackingSpecification(TempSelectedTrackingSpec);
                    IncPackagingLabel.RunModal();
                end;
            }
        }
        // Ana sayfa area(Promoted) kullandığı için Promoted = true yerine actionref
        addlast(Category_Process)
        {
            actionref(PackagingLabel_Inc_Promoted; PackagingLabel_Inc)
            {
            }
        }
    }
}
