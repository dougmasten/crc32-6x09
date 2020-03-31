.RECIPEPREFIX +=
.DEFAULT_GOAL := help

BUILD_DIR := ./build
TARGET := $(BUILD_DIR)/DISK.DSK
FILE_BIN := $(BUILD_DIR)/FILE.BIN
FILE_LIST := $(BUILD_DIR)/file.lst
DISK_FINAL = *.BIN


# make sure build directories exist
$(shell $(MKDIR) $(DISK_DIR))
$(shell $(MKDIR) $(IMAGE_DIR))

MAME = $(shell which mame)
DECB = $(shell which decb)
ASM = $(shell which lwasm)
RM := rm -f
MKDIR := mkdir -p
RMDIR := rm -rf

#MAME_MACHINE := coco2
#MAME_MACHINE := coco3  # CoCo 3 w/ M6809 CPU
MAME_MACHINE := coco3h  # CoCo 3 w/ H6309 CPU

#MAME_MEM := 128k
#MAME_MEM := 512k
MAME_MEM := 2m
#MEME_MEM := 8m

#MAME_SPEED :=
MAME_SPEED := -nothrottle

MAME_RESOLUTION := 1280x960

MAME_AUTOBOOT := -autoboot_command '\n\n\nLOADM"*":EXEC\n'

MAME_OPTIONS := -nofilter                       \
                -debug                          \
                -natural                        \
                -nomouse                        \
                -nojoy                          \
                -skip_gameinfo                  \
                -window                         \
                -resolution $(MAME_RESOLUTION)  \
                -ramsize $(MAME_MEM)            \
                $(MAME_SPEED)                   \
                $(MAME_AUTOBOOT)

# make sure build directories exist
$(shell $(MKDIR) $(BUILD_DIR))


$(FILE_BIN): $(PACKAGE_SRC)
  $(ASM) -o $(FILE_BIN)       \
         --list=$(FILE_LIST)  \
         --symbols            \
         test.asm


$(TARGET): $(FILE_BIN)
  $(RM) $(TARGET)
  $(DECB) dskini -3 $(TARGET)
  $(DECB) copy -2 -b $(FILE_BIN) $(TARGET),$(DISK_FINAL)


.PHONY: test
test:
  $(MAME) $(MAME_MACHINE) -flop1 $(TARGET) $(MAME_OPTIONS)


.PHONY: clean
clean:
  $(RMDIR) $(BUILD_DIR)


.PHONY: all
all: $(TARGET)
