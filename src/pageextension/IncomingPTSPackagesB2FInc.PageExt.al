pageextension 70811 "Incoming PTS Packages-B2F_Inc" extends "Incoming PTS Packages-B2F"
{
    actions
    {
        modify(CreateWarehouseReceipt)
        {
            trigger OnBeforeAction()
            var
                LVendor: Record Vendor;
            begin

                Clear(LVendor);
                case rec.sourceGLN of
                    '8680406000020':
                        if LVendor.Get('ST00101001') then begin
                            LVendor.GLN := '8680406000020';
                            LVendor.Modify();
                            Commit();
                        end;
                    '8680406000037':
                        if LVendor.Get('ST00101002') then begin
                            LVendor.GLN := '8680406000037';
                            LVendor.Modify();
                            Commit();
                        end;
                end;
            end;
        }
    }
}
