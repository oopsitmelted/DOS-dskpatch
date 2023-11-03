AS      = nasm
LD 		= wlink
AFLAGS  = -t -f obj
LDFLAGS = FORMAT dos com OP map

comma:=,
empty:=
space:= $(empty) $(empty)

dskpatch.com : dskpatch.o cursor.o disk_io.o disp_sec.o dispatch.o editor.o kbd_io.o phantom.o video_io.o
	$(LD) $(LDFLAGS) N $@ F $(subst $(space),$(comma),$^)

.PHONY : all clean test

clean :
	$(RM) *.com
	$(RM) *.o
	$(RM) *.lst *.map

%.o : %.s
	$(AS) $(AFLAGS) -l $^.lst -o $@ $<
