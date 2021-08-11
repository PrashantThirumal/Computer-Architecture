Prashant Thirumal
ECE 3058
Lab 1
5 Feb 2021

TO RUN:
make clean
make
gtkwave and select mips.vcd to analyze the file

****
****

Lab 1 Explanation:
- waveform.png shows the initial waveform I ran prior to implementing any changes
- that .vcd file is lablled first_mips.vcd
-
- I used the slt instruction to compare the values between register 4 and register 9
- By default, $4 = 4, $9 = 9 so slt slt $8, $4, $9 would mean that the value stored in
- $8 = 1. Thus the waveform labelled slt working waveform.png shows mainly the register
- values.

****
****

Extra Credit:
- Tried as I might, I could not get the extra credit instruction working so I removed
- implementing them altogther
