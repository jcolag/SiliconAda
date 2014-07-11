--   with Sqrt, Simple_IO;
   procedure Print_Roots is
--      use Simple_IO;
      X: Float;
   begin
--      Put("Roots of various numbers");
      New_Line(2);
      mainloop: loop
         Get(X);
         exit when X = 0.0;
--         Put(" Root of ");
         Put(X);
--         Put(" is ");
         if X < 0.0 then
--            Put("not calculable");
                null;
         else
            Put(Sqrt(X));
         end if;
         New_Line;
      end loop mainloop;
      New_Line;
--      Put("Program finished");
      New_Line;
   end Print_Roots;
