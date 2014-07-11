procedure OISC is
        ip, OP1, OP2, DST, RES : integer;
begin
        ip := 0;
main:   while ip /= -1 loop
        OP1 := M(ip);
        OP2 := M(ip + 1);
        OP3 := M(ip + 2);
        ip := ip + 3;
        RES := OP1 - OP2;
        M(ip - 3) := RES;
        if RES < 0 then ip := OP3;
        end loop main;
end OISC;
