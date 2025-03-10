
MKIMG = $(PWD)/mkimage_imx8
CC = gcc
CFLAGS ?= -g -O2 -Wall -std=c99 -static
INCLUDE += $(CURR_DIR)/src

SRCS = src/imx8qm.c  src/imx8qx.c src/imx8qxb0.c src/mkimage_imx8.c

ifeq ($(SOC), iMX8M)
DTBS ?= fsl-imx8mq-evk.dtb
endif

ifneq ($(findstring iMX8M,$(SOC)),)
SOC_DIR = iMX8M
endif
SOC_DIR ?= $(SOC)

ifdef DTBS
EXTRAS := dtbs=$(DTBS)
endif

vpath $(INCLUDE)

.PHONY:  clean all bin

.DEFAULT:
	@$(MAKE) -s --no-print-directory bin
	@$(MAKE) ${EXTRAS} --no-print-directory -C $(SOC_DIR) -f soc.mak $@

#print out usage as the default target
all: $(MKIMG) help

clean:
	@rm -f $(MKIMG)
	@rm -f src/build_info.h
	@$(MAKE) --no-print-directory -C iMX8QM -f soc.mak clean
	@$(MAKE) --no-print-directory -C iMX8QX -f soc.mak  clean
	@$(MAKE) --no-print-directory -C iMX8M -f soc.mak  clean
	@$(MAKE) --no-print-directory -C iMX8dv -f soc.mak  clean

$(MKIMG): src/build_info.h $(SRCS)
	@echo "Compiling mkimage_imx8"
	$(CC) $(CFLAGS) $(SRCS) -o $(MKIMG) -I src

bin: $(MKIMG)

src/build_info.h:
	@echo -n '#define MKIMAGE_COMMIT 0x' > src/build_info.h
	@git rev-parse --short=8 HEAD >> src/build_info.h
	@echo '' >> src/build_info.h

help:
	@echo $(CURR_DIR)
	@echo "usage ${MAKE} SOC=<SOC_TARGET> [TARGET]"
	@echo "i.e.  ${MAKE} SOC=iMX8QX flash_dcd"
	@echo "Common Targets:"
	@echo
	@echo "Parts with SCU"
	@echo "	  flash_scfw    - Only boot SCU"
	@echo "	  flash_dcd     - SCU + AP cluster with DCDs"
	@echo "	  flash         - SCU + AP (no DCD)"
	@echo "	  flash_flexspi - SCU + AP (FlexSPI device) "
	@echo "	  flash_cm4_0   - SCU + M4_0 w/ DCDs "
	@echo "	  flash_all     - SCU + AP + M4 + SCD + CSF(AP & SCU) w/ DCDs"
	@echo ""
	@echo "Parts w/o SCU"
	@echo "	  u-boot-%.hdmibin     - HDMI FW + u-boot spl"
	@echo
	@echo "Typical flash cmd: dd if=iMX8QM/flash.bin of=/dev/<your device> bs=1k seek=33"
	@echo

