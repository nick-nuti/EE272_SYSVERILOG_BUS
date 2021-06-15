# EE272_SYSVERILOG_BUS

___General Readme will be added in future file___

*** NOTE: This project was designed based on testbench requirements. It is synthesizeable but it not optimized; it's designed for simulation ***

******NOTE THIS PROJECT WAS IMPLEMENTED + TESTED IN VCS THEN WAS TESTED AGAIN USING VIVADO 2020.2; IF YOU SEE WEIRD RESULTS IT'S DUE TO VERSION DIFFERENCES******

***Easiest way to run the project:***
1. Download every file in this repo
2. Open Vivado -> File -> Project -> New
3. Next -> ***Name Project*** -> RTL Project
4. Under "Add Source" add the following files:
    - fifo.sv
    - m55.sv
    - nochw2.sv
    - perm.sv
    - pri_rr_arb.sv
    - ps.sv
    - slave.sv
5. For Default Part, make sure to select a part that has the following:
    - LUT: 18,273
    - LUTRAM: 32
    - FF: 36,390
    - IO: 20
    - BUFG: 1
6. Press Finish
7. Open the new project
8. Under the "Sources" tab press the "+" button to add new files, select "Add or create simulation sources", and select the following files:
    - tb_intf.sv
    - adult.sv
    - baby.sv
    - child.sv
    - teen.sv
9. Go back into "Add or create simulation sources", press on the bottom where it says "Files of type", change it to "All Files", and add the following file:
    - sha3_module_test.txt
11. Run Simulation
