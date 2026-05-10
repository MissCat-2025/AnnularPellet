###############################################################################
################### MOOSE Application Standard Makefile #######################
###############################################################################
#
# Optional Environment variables
# MOOSE_DIR        - Root directory of the MOOSE project
# RACCOON_DIR      - Root directory of the RACCOON project
#
###############################################################################

# Set the RACCOON directory
RACCOON_DIR        ?= $(shell dirname `pwd`)/raccoon
#
###############################################################################
# Use the MOOSE submodule if it exists and MOOSE_DIR is not set
MOOSE_SUBMODULE    := $(CURDIR)/moose
ifneq ($(wildcard $(MOOSE_SUBMODULE)/framework/Makefile),)
  MOOSE_DIR        ?= $(MOOSE_SUBMODULE)
else
  MOOSE_DIR        ?= $(shell dirname `pwd`)/moose
endif

# framework
FRAMEWORK_DIR      := $(MOOSE_DIR)/framework
include $(FRAMEWORK_DIR)/build.mk
include $(FRAMEWORK_DIR)/moose.mk

################################## MODULES ####################################
# To use certain physics included with MOOSE, set variables below to
# yes as needed.  Or set ALL_MODULES to yes to turn on everything (overrides
# other set variables).

ALL_MODULES                 := no

CHEMICAL_REACTIONS          := no
CONTACT                     := no
ELECTROMAGNETICS            := no
EXTERNAL_PETSC_SOLVER       := no
FLUID_PROPERTIES            := no
FSI                         := no
FUNCTIONAL_EXPANSION_TOOLS  := no
GEOCHEMISTRY                := no
HEAT_TRANSFER               := yes
LEVEL_SET                   := no
MISC                        := no
NAVIER_STOKES               := no
OPTIMIZATION                := no
PERIDYNAMICS                := no
PHASE_FIELD                 := yes
POROUS_FLOW                 := no
RAY_TRACING                 := no
REACTOR                     := no
RDG                         := no
SOLID_MECHANICS             := yes
STOCHASTIC_TOOLS            := no
THERMAL_HYDRAULICS          := no
XFEM                        := no

include $(MOOSE_DIR)/modules/modules.mk

################################## RACCOON ####################################
# Include RACCOON as a dependency
RACCOON            := yes
RACCOON_LIB        := yes
# 添加RACCOON的所有include路径
ADDITIONAL_INCLUDES += -I$(RACCOON_DIR)/include
ADDITIONAL_INCLUDES += -I$(RACCOON_DIR)/include/materials/small_deformation_models
ADDITIONAL_INCLUDES += -I$(RACCOON_DIR)/include/materials/hardening_models
ADDITIONAL_INCLUDES += -I$(RACCOON_DIR)/include/interfaces
ADDITIONAL_INCLUDES += -I$(RACCOON_DIR)/include/materials
ADDITIONAL_INCLUDES += -I$(RACCOON_DIR)/include/kernels
ADDITIONAL_INCLUDES += -I$(RACCOON_DIR)/include/base
ADDITIONAL_INCLUDES += -I$(RACCOON_DIR)/include/utils
ADDITIONAL_LIBS     += -L$(RACCOON_DIR)/lib -lraccoon-$(METHOD)
###############################################################################

# dep apps
APPLICATION_DIR    := $(CURDIR)
APPLICATION_NAME   := annular_pellet
BUILD_EXEC         := yes
GEN_REVISION       := no
include            $(FRAMEWORK_DIR)/app.mk

###############################################################################
# Additional special case targets should be added here
