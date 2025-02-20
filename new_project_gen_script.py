# script to make new Xilinx FPGA projects how I like to make them. 
# different folders are made and correct contraints for my boards are added
# a short Tcl script is generated to create a new project in Vivado. 
#
# current for Vivado 2024.1
#
# Ver 1.0 Dominic Meads 2/19/2025

import os
import shutil

# get input
proj_name = input("Enter project name: ")
while(True):
  board = input("Type \"P\" for PYNQ Z-1 board, or \"A\" for Arty S7-25 board: ")
  if (board == "A" or board == "P"):
    break
  else:
    print("Error, undefined board entered.")
    continue
  
# make project folder
os.mkdir(proj_name)

#  make sub folders
proj_path = "C:/Users/demea/Xilinx_projects/" + proj_name
os.chdir(proj_path)
folder_names = ["sim", "src", "constraints", "ip", "tcl"]
for folder_name in folder_names:
  os.mkdir(folder_name)

# add correct constraints file
part = "default"
board_part_tcl = "default"
if board == "P":  # pynq board
  source_path = "C:/Users/demea/Xilinx_projects/PYNQ-Z1_C.xdc"
  part = "xc7z020clg400-1"
  board_part_tcl = "set_property board_part www.digilentinc.com:pynq-z1:part0:1.0 [current_project]"
elif board == "A":  # arty board
  source_path = "C:/Users/demea/Xilinx_projects/Arty-S7-25-Master.xdc"
  part = "xc7s25csga324-1"
  board_part_tcl = "set_property board_part digilentinc.com:arty-s7-25:part0:1.1 [current_project]"
constraints_path = proj_path + "/constraints"
shutil.copy(source_path, constraints_path)

# make tcl script to generate new Vivado project
zynq_gen = "default"
tcl_path = proj_path + "/tcl"
zynq_gen_tcl_lines = [
  "create_bd_design \"design_1\"",
  "update_compile_order -fileset sources_1",
  "startgroup",
  "create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0",
  "endgroup",
  "apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external \"FIXED_IO, DDR\" apply_board_preset \"1\" Master \"Disable\" Slave \"Disable\" }  [get_bd_cells processing_system7_0]",
  "save_bd_design"
]
os.chdir(tcl_path)
create_proj_tcl_str = "create_project " + proj_name + "_proj " + proj_path + "/" + proj_name + "_proj " + " -part " + part + "\n"  # create project in new subfolder
with open("new_project_gen.tcl", 'w') as file: 
  file.write(create_proj_tcl_str)
  file.write(board_part_tcl + "\n")
  if board == "P":
    while(True):
      zynq_gen = input("Do you want to use the ZYNQ processing system? type Y/N: ")
      if (zynq_gen == "Y" or zynq_gen == "N"):
        break
      else:
        print("Error, please type a choice")
        continue

    if zynq_gen == "Y":
      for line in zynq_gen_tcl_lines:
        file.write(line + "\n")
