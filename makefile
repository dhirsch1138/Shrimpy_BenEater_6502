#Based on https://github.com/dbuchwald/cc65-tools
#Specify target ROM
ROM_NAME=output

#LD65 configuration file
CONFIGFILE_NAME=linker.cfg

#Static folders
C65FOLDER=.c65/
ASM_SOURCEFOLDER=source/

#Relative folder paths to workspace folder
C65PATH=$(C65FOLDER)

#Full file and folder paths used during build
ASM_SOURCES:=$(wildcard $(ASM_SOURCEFOLDER)*.s)
LD65_CFG=$(ASM_SOURCEFOLDER)$(CONFIGFILE_NAME)
COMMON_FOLDER=$(C65PATH)common/

#Build path is currently annoying because I am lazy and have to leave off the trailing slash
#TECH DEBT YAY. I'll need to cleanup where this is used and so that I can add the slash back here to be consistent
BUILDPATH=build

$(info   INFO: Processing source files in folder "$(ASM_SOURCEFOLDER)")
$(info   INFO: Located these source files and will process "$(ASM_SOURCES)")
$(info   INFO: Will use linker configuration "$(LD65_CFG)")
$(info   INFO: CC65 rules folder "$(C65PATH)")

#We are currently hard linking to the cc65 toolset, ignoring VASM
include $(C65PATH)common/cc65.rules.mk