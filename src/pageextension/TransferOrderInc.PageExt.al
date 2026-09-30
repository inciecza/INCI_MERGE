pageextension 70823 "Transfer Order_Inc" extends "Transfer Order"
{
    actions
    {
        modify("Create Whse. S&hipment")
        {
            trigger OnAfterAction()
            var
                LInciJobQueueEntryMang2Inc: Codeunit "Inci Job Queue Entry Mang2_Inc";
            begin
                Clear(LInciJobQueueEntryMang2Inc);
                LInciJobQueueEntryMang2Inc.UpdateWHSH();
            end;
        }

    }
}
