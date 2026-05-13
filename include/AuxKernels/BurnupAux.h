// BurnupAux.h
#pragma once

#include "AuxKernel.h"
#include "Function.h"
#include "metaphysicl/raw_type.h"

/**
 * 将局部燃耗 (FIMA, Fissions per Initial Metal Atom) 作为辅助变量进行显式积分更新。
 *
 * 完整实现 ADRimEffertPowerBurnup 的所有计算逻辑：
 *   1. 读取功率历史函数，获取当前时刻基础功率密度 power_base(t) [W/m³]
 *   2. (可选) 计算径向边缘效应功率分布因子 f(r, Bu_old)
 *      参考: Deng Y, et al. Nuclear Engineering and Design, 2016, 301: 353-365.
 *        term1 = A * Bu^0.55 * exp(-180 * (r - r_i)^0.56)
 *        term2 = B * Bu^0.55 * exp(-115 * (r_o - r)^0.5)
 *        termBase = C * Bu^2 + D * Bu - 1       (注: C 一般为负值)
 *        f(r) = term1 + term2 - termBase
 *   3. 总功率密度: total_power = power_base * f(r)
 *   4. 显式 Euler 积分更新燃耗:
 *        burnup[t] = burnup[t-1] + total_power / alpha * dt / N_f0
 *        N_f0 = rho * N_av / M_w * 1000   [atoms/m³]
 *
 * 注：径向因子使用上一时步的燃耗值（显式，不参与非线性迭代），
 *     密度通过 AD 材料属性读取并提取标量值。
 */
class BurnupAux : public AuxKernel
{
public:
  static InputParameters validParams();
  BurnupAux(const InputParameters & parameters);

protected:
  virtual Real computeValue() override;

  /**
   * 计算径向边缘效应功率分布因子 f(r, Bu_old)。
   * 若 use_rim_effect=false 或 bu_old<=0，直接返回 1.0。
   */
  Real powerFactor(Real r, Real bu_old) const;

  // ── 功率历史函数 ──────────────────────────────────────────
  const Function & _power_history;

  // ── 几何参数 ──────────────────────────────────────────────
  /// 环形芯块内半径 (m)
  const Real _pellet_inner_radius;
  /// 环形芯块外半径 (m)
  const Real _pellet_outer_radius;

  // ── 径向边缘效应开关及参数 ────────────────────────────────
  /// 是否启用径向边缘效应功率因子（默认 true）
  const bool _use_rim_effect;
  /// 控制内边缘燃耗最大值 (默认 3.5)
  const Real _A;
  /// 控制外边缘燃耗最大值 (默认 4.5)
  const Real _B;
  /// 二次项系数，通常为负值 (默认 -15.7)
  const Real _C;
  /// 一次项系数 (默认 3.5)
  const Real _D;

  // ── 燃耗积分物理常数 ──────────────────────────────────────
  /// 阿伏伽德罗常数 (atoms/mol)
  const Real _N_av;
  /// UO2 分子量 (g/mol)
  const Real _M_w;
  /// 每次裂变释放的能量 (J/fission)
  const Real _alpha;

  // ── 材料属性：燃料密度 ────────────────────────────────────
  /// 从材料系统读取燃料密度 (kg/m³)，用于计算初始重金属原子数密度
  const ADMaterialProperty<Real> & _density;

  // ── 辅助变量上一时步旧值 ──────────────────────────────────
  /// AuxKernel 基类无内置 _u_old，需显式绑定 _var.slnOld()
  const VariableValue & _u_old;
};
