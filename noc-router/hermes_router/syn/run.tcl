##############################################################
##              Logical synthesis commands                  ##
## Script Generated for Undergrad class of microelectronics ##
## Generated by Matheus Moreira - 9/11/2011                 ##
## GAPH/FACIN/PUCRS                                         ##
##############################################################

## 1) load synthesis configuration, read description and elaborate design 
include load.tcl
read_hdl -vhdl HeMPS_defaults.vhd  Hermes_buffer.vhd  Hermes_crossbar.vhd  Hermes_switchcontrol.vhd  RouterCC.vhd  
elaborate RouterCC

## 2) read constraints
read_sdc constraints.sdc

## 3) synthesize to generic
synthesize -to_generic -eff high

## 4) synthesize to mapped
synthesize -to_mapped -eff high -no_incr

## 4.1) wrtie sdf
write_sdf -no_escape -design RouterCC > src/layout/RouterCC.sdf

## 4.2) report area and timing
report area
report timing

## 5) build physical synthesis environment
write_design -innovus -base_name src/layout/RouterCC
#write_encounter design -basename encounter/router
