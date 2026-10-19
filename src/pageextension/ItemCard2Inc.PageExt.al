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
            Editable = CostsPostEditable;
            Visible = CostsPostVisible;
        }

        modify("Prices & Sales")
        {
            Editable = PricesSalesEditable;
            Visible = PricesSalesVisible;
        }

        modify(Replenishment)
        {
            Editable = ReplenishmentEditable;
            Visible = ReplenishmentVisible;
        }

        modify(Planning)
        {
            Editable = PlanningEditable;
            Visible = PlanningVisible;
        }

        modify(ItemTracking)
        {
            Editable = ItemTrackingEditable;
            Visible = ItemTrackingVisible;
        }

        modify(Warehouse)
        {
            Editable = WarehouseEditable;
            Visible = WarehouseVisible;
        }

        modify(InspectionB2F)
        {
            Editable = InspectionB2FEditable;
            Visible = InspectionB2FVisible;
        }

        modify(NewPropery_Inc)
        {
            Editable = NewPropertyEditable;
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
            CostsPostEditable := UserSetup."Cost Post. EditVisible_Inc";
            CostsPostVisible := UserSetup."Cost Post. Visible_Inc";//
            PricesSalesEditable := UserSetup."Prices Sales EditVisible_Inc";
            PricesSalesVisible := UserSetup."Prices Sales Visible_Inc";//
            ReplenishmentEditable := UserSetup."Replenishment EditVisible_Inc";
            ReplenishmentVisible := UserSetup."Replenishment Visible_Inc";//
            PlanningEditable := UserSetup."Planning EditVisible_Inc";
            PlanningVisible := UserSetup."Planning Visible_Inc";//
            ItemTrackingEditable := UserSetup."Item Tracking EditVisible_Inc";
            ItemTrackingVisible := UserSetup."Item Tracking Visible_Inc";//
            WarehouseEditable := UserSetup."Warehouse EditVisible_Inc";
            WarehouseVisible := UserSetup."Warehouse Visible_Inc"; //
            InspectionB2FEditable := UserSetup."Inspection B2F EditVisible_Inc";
            InspectionB2FVisible := UserSetup."Inspection B2F Visible_Inc";//
            NewPropertyEditable := UserSetup."New Property EditVisible_Inc";
            NewPropertyVisible := UserSetup."New Property Visible_Inc"; ///
            VademecumVisible := UserSetup."Vademecum EditVisible_Inc";
        end;
    end;

    var
        UserSetup: Record "User Setup";

        ItemGeneralEditable: Boolean;
        InventoryGroupEditable: Boolean;

        CostsPostEditable: Boolean;
        CostsPostVisible: Boolean;
        PricesSalesEditable: Boolean;
        PricesSalesVisible: Boolean;
        ReplenishmentEditable: Boolean;
        ReplenishmentVisible: Boolean;
        PlanningEditable: Boolean;
        PlanningVisible: Boolean;
        ItemTrackingEditable: Boolean;
        ItemTrackingVisible: Boolean;
        WarehouseEditable: Boolean;
        WarehouseVisible: Boolean;
        InspectionB2FEditable: Boolean;
        InspectionB2FVisible: Boolean;
        NewPropertyEditable: Boolean;
        NewPropertyVisible: Boolean;
        VademecumVisible: Boolean;
}