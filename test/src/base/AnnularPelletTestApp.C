//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#include "AnnularPelletTestApp.h"
#include "AnnularPelletApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "MooseSyntax.h"

InputParameters
AnnularPelletTestApp::validParams()
{
  InputParameters params = AnnularPelletApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

AnnularPelletTestApp::AnnularPelletTestApp(const InputParameters & parameters) : MooseApp(parameters)
{
  AnnularPelletTestApp::registerAll(
      _factory, _action_factory, _syntax, getParam<bool>("allow_test_objects"));
}

AnnularPelletTestApp::~AnnularPelletTestApp() {}

void
AnnularPelletTestApp::registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs)
{
  AnnularPelletApp::registerAll(f, af, s);
  if (use_test_objs)
  {
    Registry::registerObjectsTo(f, {"AnnularPelletTestApp"});
    Registry::registerActionsTo(af, {"AnnularPelletTestApp"});
  }
}

void
AnnularPelletTestApp::registerApps()
{
  registerApp(AnnularPelletApp);
  registerApp(AnnularPelletTestApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
// External entry point for dynamic application loading
extern "C" void
AnnularPelletTestApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  AnnularPelletTestApp::registerAll(f, af, s);
}
extern "C" void
AnnularPelletTestApp__registerApps()
{
  AnnularPelletTestApp::registerApps();
}
