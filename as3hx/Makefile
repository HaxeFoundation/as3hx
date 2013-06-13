###############################################################################
#
# File: Makefile
#
# Copyright 2013 TiVo Inc. All Rights Reserved.
#
###############################################################################

ISM_DEPTH := ../..
include $(ISM_DEPTH)/ismdefs

ifneq ($(DEBUG_AS3HX),)
HAXE_DEBUG := -debug
endif

default: $(OBJDIR)/.mkdir
	haxe --no-traces $(HAXE_DEBUG) -cp . -neko $(OBJDIR)/as3tohx.n -main Run
	nekotools boot $(OBJDIR)/as3tohx.n

include $(ISMRULES)
