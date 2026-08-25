pageextension 70808 "Outgoing E-Invoices-B2F_Inc" extends "Outgoing E-Invoices-B2F"
{
    actions
    {
        addlast(Processing)
        {
            action(DownloadFilteredHTMLInvoices_Inc)
            {
                ApplicationArea = All;
                Caption = 'Download Filtered HTML Invoices';
                Image = Download;

                trigger OnAction()
                var
                    LExportEInv: Report "Export EInvoice Documents_Inc";

                begin
                    Clear(LExportEInv);
                    LExportEInv.Run();
                end;
            }
        }
    }


}