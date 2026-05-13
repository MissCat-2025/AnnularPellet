// ADPower.C
#include "ADPower.h"
#include "Function.h"

registerMooseObject("AnnularPelletApp", ADPower);

InputParameters
ADPower::validParams()
{
  /*
   * 径向功率分布公式 (Deng et al., Nuclear Engineering and Design, 2016):
   *   term1    = A * Bu^0.55 * exp(-180 * (r - r_i)^0.56)   内边缘效应
   *   term2    = B * Bu^0.55 * exp(-115 * (r_o - r)^0.5)    外边缘效应
   *   termBase = C * Bu^2 + D * Bu - 1                       基础分布 (C<0)
   *   f(r)     = term1 + term2 - termBase
   *
   * burnup 由外部 AuxVariable (BurnupAux) 提供，本材料使用其上一时步旧值（显式）。
   */
  InputParameters params = ADMaterial::validParams();
  params.addClassDescription(
      "计算局部功率密度和径向功率形状因子的 AD 材料（Deng 边缘效应模型）。"
      "burnup 由外部 AuxVariable 耦合提供（coupledValueOld，显式），不在此处积分。");

  // ── 功率历史函数 ──────────────────────────────────────────
  params.addRequiredParam<FunctionName>("power_history",
      "功率历史函数，返回当前时刻均匀化基础功率密度 (W/m³)");

  // ── 几何参数 ──────────────────────────────────────────────
  params.addRequiredParam<Real>("pellet_inner_radius", "环形芯块内半径 (m)");
  params.addRequiredParam<Real>("pellet_outer_radius", "环形芯块外半径 (m)");

  // ── 径向边缘效应 ──────────────────────────────────────────
  params.addParam<bool>("use_rim_effect", true,
      "是否启用径向边缘效应功率因子；false 时退化为均匀功率 f(r)=1");
  params.addParam<Real>("A", 3.5,   "内边缘效应系数");
  params.addParam<Real>("B", 4.5,   "外边缘效应系数");
  params.addParam<Real>("C", -15.7, "基础分布二次项系数（通常为负值）");
  params.addParam<Real>("D",  3.5,  "基础分布一次项系数");

  // ── 耦合 burnup AuxVariable ───────────────────────────────
  params.addRequiredCoupledVar("burnup",
      "燃耗辅助变量 (AuxVariable)，由 BurnupAux 更新；"
      "本材料使用其上一时步旧值（显式）计算径向功率形状因子");

  return params;
}

ADPower::ADPower(const InputParameters & parameters)
  : ADMaterial(parameters),
    _power_history(getFunction("power_history")),
    _pellet_inner_radius(getParam<Real>("pellet_inner_radius")),
    _pellet_outer_radius(getParam<Real>("pellet_outer_radius")),
    _use_rim_effect(getParam<bool>("use_rim_effect")),
    _A(getParam<Real>("A")),
    _B(getParam<Real>("B")),
    _C(getParam<Real>("C")),
    _D(getParam<Real>("D")),
    _burnup_old(coupledValueOld("burnup")),
    _total_power(declareADProperty<Real>("total_power")),
    _radial_power_shape(declareADProperty<Real>("radial_power_shape"))
{
}

ADReal
ADPower::powerFactor(const Real & r) const
{
  using MetaPhysicL::exp;
  using MetaPhysicL::pow;
  using std::exp;
  using std::pow;

  const Real bu = _burnup_old[_qp];

  // 若关闭径向效应或燃耗为零（首步），返回均匀因子 1.0
  if (!_use_rim_effect || bu <= 0.0)
    return 1.0;

  // 内边缘效应项
  ADReal term1 = _A * pow(bu, 0.55)
                 * exp(-180.0 * pow(r - _pellet_inner_radius, 0.56));

  // 外边缘效应项
  ADReal term2 = _B * pow(bu, 0.55)
                 * exp(-115.0 * pow(_pellet_outer_radius - r, 0.5));

  // 基础分布项：C*Bu^2 + D*Bu - 1  (C<0 时为向下开口抛物线)
  ADReal termBase = _C * bu * bu + _D * bu - 1.0;

  return term1 + term2 - termBase;
}

void
ADPower::computeQpProperties()
{
  // ── 1. 当前积分点径向距离 ─────────────────────────────────
  const Point & p = _q_point[_qp];
  const Real r = std::sqrt(p(0) * p(0) + p(1) * p(1));

  // ── 2. 径向功率形状因子（AD） ─────────────────────────────
  _radial_power_shape[_qp] = powerFactor(r);

  // ── 3. 当前时刻基础功率密度 (W/m³) ──────────────────────
  const Real power_base = _power_history.value(_t, _q_point[_qp]);

  // ── 4. 总功率密度（AD，传递给热源核 ADMatHeatSource） ────
  _total_power[_qp] = power_base * _radial_power_shape[_qp];
}
