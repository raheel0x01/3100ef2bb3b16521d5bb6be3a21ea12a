This is just a small engine, but I'm sure it can be very useful.
  
What is the engine does? Splitts the current file into 3-10 byte
chunks and creates a merge file (called start.bat).

To understand it's purpose, you should read my article called
"Over-File Splitting".

What could you do with the splitted files?
  - You could make an archive (via own routing, possible installed WinZIP/RAR
    or use the WinME+ preinstalled function [C:\WINDOWS\System32\zipfldr.dll,-10195]
    to compress files.) This file now could be send out via eMail.
    The advantage: No file is infected with an virus - but all together they are.

  - you can save all files in a directory (Windir, system32, whatever) and
    call the join file at each startup. What could it be? 
	Virus / Worm works as follows: computer, but no files are infected
	
  - You can think your own way to use this technique. Lazy!


How to compile:
  - Use flat assembler 1.73.27
