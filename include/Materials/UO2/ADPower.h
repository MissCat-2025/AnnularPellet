// ADPower.h
#pragma once

#include "ADMaterial.h"

/**
 * 计算局部功率密度和径向功率分布形状因子的 AD 材料类。
 *
 * 燃耗由外部 AuxVariable (BurnupAux) 提供，本材料使用上一时步的
 * burnup 旧值（coupledValueOld，显式）来计算径向边缘效应因子，
 * 从而为 FE 求解提供 AD 材料属性：
 *   - total_power        [W/m³]  用于 ADMatHeatSource 热源核
 *   - radial_power_shape [-]     径向功率分布形状因子（用于输出/后处理）
 *
 * 参考: Deng Y, et al. Nuclear Engineering and Design, 2016, 301: 353-365.
 *   term1    = A * Bu^0.55 * exp(-180 * (r - r_i)^0.56)   内边缘效应
 *   term2    = B * Bu^0.55 * exp(-115 * (r_o - r)^0.5)    外边缘效应
 *   termBase = C * Bu^2 + D * Bu - 1                       基础分布 (C<0)
 *   f(r)     = term1 + term2 - termBase
 */
class ADPower : public ADMaterial
{
public:
  static InputParameters validParams();
  ADPower(const InputParameters & parameters);

protected:
  virtual void computeQpProperties() override;

  /// 计算径向边缘效应功率分布因子 f(r)，使用上一时步 burnup 旧值（显式）
  ADReal powerFactor(const Real & r) const;

  // ── 功率历史函数 ──────────────────────────────────────────
  const Function & _power_history;

  // ── 几何参数 ──────────────────────────────────────────────
  const Real _pellet_inner_radius;
  const Real _pellet_outer_radius;

  // ── 径向边缘效应开关及参数 ────────────────────────────────
  /// 是否启用径向边缘效应因子（默认 true）
  const bool _use_rim_effect;
  const Real _A; ///< 控制内边缘燃耗最大值 (默认 3.5)
  const Real _B; ///< 控制外边缘燃耗最大值 (默认 4.5)
  const Real _C; ///< 二次项系数，通常为负值 (默认 -15.7)
  const Real _D; ///< 一次项系数 (默认 3.5)

  // ── 从 AuxVariable burnup 读取的上一时步旧值（显式） ──────
  const VariableValue & _burnup_old;

  // ── 声明 AD 材料属性 ──────────────────────────────────────
  ADMaterialProperty<Real> & _total_power;
  ADMaterialProperty<Real> & _radial_power_shape;
};
