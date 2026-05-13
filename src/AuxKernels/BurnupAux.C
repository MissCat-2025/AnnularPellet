// BurnupAux.C
#include "BurnupAux.h"
#include <cmath>

registerMooseObject("AnnularPelletApp", BurnupAux);

InputParameters
BurnupAux::validParams()
{
  /*
   * 径向功率分布公式 (Deng et al., 2016):
   *   term1    = A * Bu^0.55 * exp(-180 * (r - r_i)^0.56)     ← 内边缘效应
   *   term2    = B * Bu^0.55 * exp(-115 * (r_o - r)^0.5)      ← 外边缘效应
   *   termBase = C * Bu^2 + D * Bu - 1                         ← 基础分布 (C<0)
   *   f(r)     = term1 + term2 - termBase
   *
   * 燃耗积分 (FIMA, 显式 Euler):
   *   N_f0         = density * N_av / M_w * 1000               [atoms/m³]
   *   _total_power  = power_history(t) * f(r)                   [W/m³]
   *   burnup[t]    = burnup[t-1] + _total_power / alpha * dt / N_f0
   */
  InputParameters params = AuxKernel::validParams();
  params.addClassDescription(
      "将局部燃耗 (FIMA) 作为辅助变量进行显式 Euler 积分更新，"
      "完整实现径向边缘效应功率分布因子 (Deng et al., 2016) 及燃耗积分逻辑。"
      "使用上一时步的燃耗值计算径向因子（显式），密度由材料属性提供。");

  // ── 功率历史函数 ───────────────────────────────────────────
  params.addRequiredParam<FunctionName>("power_history",
      "功率历史函数，返回当前时刻均匀化基础功率密度 (W/m³)");

  // ── 几何参数 ───────────────────────────────────────────────
  params.addRequiredParam<Real>("pellet_inner_radius", "环形芯块内半径 (m)");
  params.addRequiredParam<Real>("pellet_outer_radius", "环形芯块外半径 (m)");

  // ── 径向边缘效应 ───────────────────────────────────────────
  params.addParam<bool>("use_rim_effect", true,
      "是否启用径向边缘效应功率分布因子 f(r)；"
      "设为 false 时 f(r)=1，退化为均匀功率分布");
  params.addParam<Real>("A", 3.5,   "边缘效应内侧系数 (控制内边缘峰值幅度)");
  params.addParam<Real>("B", 4.5,   "边缘效应外侧系数 (控制外边缘峰值幅度)");
  params.addParam<Real>("C", -15.7, "基础分布二次项系数 (通常为负值)");
  params.addParam<Real>("D",  3.5,  "基础分布一次项系数");

  // ── 物理常数 ───────────────────────────────────────────────
  params.addParam<Real>("N_av",  6.022e23,   "阿伏伽德罗常数 (atoms/mol)");
  params.addParam<Real>("M_w",   270.0,      "UO2 分子量 (g/mol)");
  params.addParam<Real>("alpha", 3.2845e-11, "每次裂变释放的能量 (J/fission)");

  return params;
}

BurnupAux::BurnupAux(const InputParameters & parameters)
  : AuxKernel(parameters),
    _power_history(getFunction("power_history")),
    _pellet_inner_radius(getParam<Real>("pellet_inner_radius")),
    _pellet_outer_radius(getParam<Real>("pellet_outer_radius")),
    _use_rim_effect(getParam<bool>("use_rim_effect")),
    _A(getParam<Real>("A")),
    _B(getParam<Real>("B")),
    _C(getParam<Real>("C")),
    _D(getParam<Real>("D")),
    _N_av(getParam<Real>("N_av")),
    _M_w(getParam<Real>("M_w")),
    _alpha(getParam<Real>("alpha")),
    _density(getADMaterialProperty<Real>("density")),
    _u_old(_var.slnOld())  // AuxKernel 无内置 _u_old，需显式从 _var.slnOld() 获取
{
}

Real
BurnupAux::powerFactor(Real r, Real bu_old) const
{
  // 若关闭径向效应或燃耗为零（首步），返回均匀因子 1.0
  if (!_use_rim_effect || bu_old <= 0.0)
    return 1.0;

  // 内边缘效应项
  Real term1 = _A * std::pow(bu_old, 0.55)
               * std::exp(-180.0 * std::pow(r - _pellet_inner_radius, 0.56));

  // 外边缘效应项
  Real term2 = _B * std::pow(bu_old, 0.55)
               * std::exp(-115.0 * std::pow(_pellet_outer_radius - r, 0.5));

  // 基础分布项：f_base = C*Bu^2 + D*Bu - 1  (C<0 时为向下开口抛物线)
  Real termBase = _C * bu_old * bu_old + _D * bu_old - 1.0;

  // f(r) = term1 + term2 - termBase
  return term1 + term2 - termBase;
}

Real
BurnupAux::computeValue()
{
  // ── 1. 上一时步的燃耗值（显式，不参与非线性迭代）─────────
  const Real bu_old = _u_old[_qp];

  // ── 2. 当前积分点坐标及径向距离 ──────────────────────────
  const Point & p = _q_point[_qp];
  const Real r = std::sqrt(p(0) * p(0) + p(1) * p(1));

  // ── 3. 当前时刻基础功率密度 (W/m³) ──────────────────────
  const Real power_base = _power_history.value(_t, _q_point[_qp]);

  // ── 4. 径向功率形状因子 ───────────────────────────────────
  const Real f_r = powerFactor(r, bu_old);

  // ── 5. 局部总功率密度 (W/m³) ─────────────────────────────
  const Real local_total_power = power_base * f_r;

  // ── 6. 初始重金属原子数密度 (atoms/m³) ───────────────────
  //    N_f0 = rho [kg/m³] * N_av [atoms/mol] / M_w [g/mol] * 1000 [g/kg]
  const Real rho  = MetaPhysicL::raw_value(_density[_qp]);
  const Real N_f0 = rho * _N_av / _M_w * 1000.0;

  // ── 7. 显式 Euler 积分更新燃耗 (FIMA) ────────────────────
  return bu_old + local_total_power / _alpha * _dt / N_f0;
}
