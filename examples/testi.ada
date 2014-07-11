   procedure Print_Roots is
      X: Float;
   begin
      Put("Roots of various numbers");
      New_Line(2);
      X := 1.0;
      mainloop: while X /= 0.0 loop
         Get(X);
         Put(" Root of ");
         Put(X);
         Put(" is ");
         if X < 0.0 then
            Put("not calculable");
         else
            Put(Sqrt(X));
         end if;
         New_Line;
      end loop mainloop;
      New_Line;
      Put("Program finished");
      New_Line;
   end Print_Roots;
