pageextension 70815 "Item Card2_Inc" extends "Item Card"
{
    layout
    {
        modify("Item")
        {
            Editable = ItemGeneralEditable;
        }

        modify(InventoryGrp)
        {
            Editable = InventoryGroupEditable;
        }

        modify("Costs & Posting")
        {
            Visible = CostsPostVisible;
        }

        modify("Prices & Sales")
        {
            Visible = PricesSalesVisible;
        }

        modify(Replenishment)
        {
            Visible = ReplenishmentVisible;
        }

        modify(Planning)
        {
            Visible = PlanningVisible;
        }

        modify(ItemTracking)
        {
            Visible = ItemTrackingVisible;
        }

        modify(Warehouse)
        {
            Visible = WarehouseVisible;
        }

        modify(InspectionB2F)
        {
            Visible = InspectionB2FVisible;
        }

        modify(NewPropery_Inc)
        {
            Visible = NewPropertyVisible;
        }

        modify(VademecmProperty_Inc)
        {
            Visible = VademecumVisible;
        }
    }

    trigger OnOpenPage()
    begin
        Clear(UserSetup);

        if UserSetup.Get(UserId) then begin
            ItemGeneralEditable := UserSetup."Item General EditVisible_Inc";
            InventoryGroupEditable := UserSetup."Inventory Gr. EditVisible_Inc";
            CostsPostVisible := UserSetup."Cost Post. EditVisible_Inc";
            PricesSalesVisible := UserSetup."Prices Sales EditVisible_Inc";
            ReplenishmentVisible := UserSetup."Replenishment EditVisible_Inc";
            PlanningVisible := UserSetup."Planning EditVisible_Inc";
            ItemTrackingVisible := UserSetup."Item Tracking EditVisible_Inc";
            WarehouseVisible := UserSetup."Warehouse EditVisible_Inc";
            InspectionB2FVisible := UserSetup."Inspection B2F EditVisible_Inc";
            NewPropertyVisible := UserSetup."New Property EditVisible_Inc";
            VademecumVisible := UserSetup."Vademecum EditVisible_Inc";
        end;
    end;

    var
        UserSetup: Record "User Setup";

        ItemGeneralEditable: Boolean;
        InventoryGroupEditable: Boolean;

        CostsPostVisible: Boolean;
        PricesSalesVisible: Boolean;
        ReplenishmentVisible: Boolean;
        PlanningVisible: Boolean;
        ItemTrackingVisible: Boolean;
        WarehouseVisible: Boolean;
        InspectionB2FVisible: Boolean;
        NewPropertyVisible: Boolean;
        VademecumVisible: Boolean;
}