procedure testcase is
	x: integer;
begin
 Put ("Enter a value for x:  ");
 Get (x);

 case x*3+1 is
	when 4 => Put ("It's 1");
	when 7 | 16 => Put ("It's 2 or 5");
	when 10 | 13 => Put ("It's 3 or 4");
 end case;
 New_Line;
end testcase;
