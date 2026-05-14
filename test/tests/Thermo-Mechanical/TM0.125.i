# conda activate moose && mpirun -n 8 /home/yp/projects/annular_pellet/annular_pellet-opt -i TM0.125_bad.i
initial_T = 558.2
initial_T_in = 570.7
initial_T_out = 582.8
pellet_nu = 0.345
density_percent = 0.95
pellet_density='${fparse density_percent*10980}'#10431.0*0.85#kg⋅m-3理论密度为10.980
density_percent100 = '${fparse density_percent*100}'
fission_rate=1.2e19
grain_size = 10

LinearPower = 90
Power0_2Time = '${fparse 2400}'
PowMaxTime = 98400
LinearPower0_2 = '${fparse LinearPower*0.2}'
endTime = 2e7#2e7
endTime__50000 = '${fparse endTime-50000}'
endTime__100000 = '${fparse endTime-100000}'
# 双冷却环形燃料几何参数 (单位：mm)(无内外包壳)
pellet_inner_diameter = 10.291         # 芯块内直径mm
pellet_outer_diameter = 14.627         # 芯块外直径mm
w = 2 #裂纹尖端时，l是mesh_size的2**w倍
mesh_size = '${fparse 3e-5}' #网格尺寸即可
n_azimuthal = '${fparse int(3.1415*(pellet_outer_diameter)/8/mesh_size*1e-3/2^(w-2))}' #int()取整
n_radial_pellet = '${fparse int((pellet_outer_diameter-pellet_inner_diameter)/mesh_size*1e-3/2^(w-1))}'
pellet_inner_radius = '${fparse pellet_inner_diameter/2*1e-3}'
pellet_outer_radius = '${fparse pellet_outer_diameter/2*1e-3}'
[Mesh]
  [annular]
    type = AnnularMeshGenerator
    nr = ${n_radial_pellet}
    nt = ${n_azimuthal}
    rmin = ${pellet_inner_radius}
    rmax = ${pellet_outer_radius}
    dmin = 0
    dmax = 45
    growth_r = 1.006
    boundary_id_offset = 10
    boundary_name_prefix = 'pellet'
  []
  [subdomain]
    type = SubdomainIDGenerator
    input = annular
    subdomain_id = 1
  []
  [rename]
    type = RenameBoundaryGenerator
    input = subdomain
    old_boundary = 'pellet_rmin pellet_rmax pellet_dmin pellet_dmax'
    new_boundary = 'pellet_inner pellet_outer x_axis fortyfive_plane'
  []
  [rename2]
    type = RenameBlockGenerator
    input = rename
    old_block = '1'
    new_block = 'pellet'
  []
[]



[GlobalParams]
    displacements = 'disp_x disp_y'
    out_of_plane_strain = strain_zz
[]

[AuxVariables]
  [stress_I]
    order = CONSTANT
    family = MONOMIAL
  []
  [vonMises]
    order = CONSTANT
    family = MONOMIAL
  []
    [burnup]
    order = CONSTANT
    family = MONOMIAL
    block = pellet
    initial_condition = 1e-12  # 避免首步 Bu=0 导致 pow(0,0.55) 的数值问题
  []
[]


[AuxKernels]
  [./stress_I]
    type = ADRankTwoScalarAux
    scalar_type = MaxPrincipal
    rank_two_tensor = stress
    variable = stress_I
    selected_qp = 0
  [../]
  [vonMisesStress]
    type = ADRankTwoScalarAux
    variable = vonMises
    rank_two_tensor = stress
    execute_on = 'TIMESTEP_END'
    scalar_type = VonMisesStress
    # 不需要 index_i 和 index_j，因为我们使用 VonMisesStress 标量类型
  []
    # 燃耗更新：使用上一时步 burnup 旧值（显式）计算功率，积分更新 burnup
  [burnup_update]
    type = BurnupAux
    variable = burnup
    block = pellet
    execute_on = 'TIMESTEP_END'
    power_history = 'power_history'
    pellet_inner_radius = ${pellet_inner_radius}
    pellet_outer_radius = ${pellet_outer_radius}
    use_rim_effect = true   # 设为 false 可退化为均匀功率分布
    # A B C D N_av M_w alpha 均使用默认值，可按需覆盖
  []
[]

[Variables]
    [disp_x]
    []
    [disp_y]
    []
    [T]
      initial_condition = ${initial_T}
    []
    [strain_zz]
    []
    [x]
      initial_condition = 0.01
    []
[]


[Kernels]
  #力平衡方程
    [solid_x]
        type = ADStressDivergenceTensors
        variable = disp_x
        component = 0
    []
    [solid_y]
        type = ADStressDivergenceTensors
        variable = disp_y
        component = 1
    []
    [./solid_z]
      type = ADWeakPlaneStress
      variable = strain_zz
    [../]
    #热传导方程
    [heat_conduction]
      type = ADHeatConduction
      variable = T
    []
    [hcond_time]
      type = ADHeatConductionTimeDerivative
      variable = T
    []
    [Fheat_source]
      type = ADMatHeatSource
      variable = T
      material_property = total_power
      block = pellet
    []
      [x]
    type = NullKernel
    variable = x
  []
[]

# ==============================================================

[BCs]
  [fix_uy_xplane]
    type = DirichletBC
    variable = disp_y
    boundary = x_axis
    value = 0.0
  []
  
  # 45度对称面的法向位移惩罚边界条件
  [fortyfive_plane_x]
    type = ADPenaltyInclinedNoDisplacementBC
    variable = disp_x
    boundary = fortyfive_plane
    component = 0
    penalty = 1e18
    displacements = 'disp_x disp_y'
  []
  [fortyfive_plane_y]
    type = ADPenaltyInclinedNoDisplacementBC
    variable = disp_y
    boundary = fortyfive_plane
    component = 1
    penalty = 1e18
    displacements = 'disp_x disp_y'
  []

  #芯块包壳间隙压力
  [gap_pressure_fuel_x]
    type = Pressure
    variable = disp_x
    boundary = 'pellet_inner pellet_outer'
    factor = 2e6
    # use_displaced_mesh = true
  []
  [gap_pressure_fuel_y]
    type = Pressure
    variable = disp_y
    boundary = 'pellet_inner pellet_outer'
    factor = 2e6
    # use_displaced_mesh = true
  []
  [coolant_bc_in]#对流边界条件
    type = ConvectiveFluxFunction
    variable = T
    boundary = 'pellet_inner'
    T_infinity = T_infinity_in
    coefficient = 3500 #3500 W·m-2 K-1！！！！！！！！！！！！！！！！！！！！！！！！！！！
  []
  [coolant_bc_out]#对流边界条件
  type = ConvectiveFluxFunction
  variable = T
  boundary = 'pellet_outer'
  T_infinity = T_infinity_out
  coefficient = 5000 #W·m-2 K-1！！！！！！！！！！！！！！！！！！！！！！！！！！！
[]
[]

[Materials]
    #定义芯块热导率、密度、比热等材料属性
    [pellet_properties2]
      type = ADGenericConstantMaterial
      prop_names = 'density nu'
      prop_values = '${pellet_density} ${pellet_nu}'
    []

    [pellet_thermal_conductivity]
      type = ADParsedMaterial
      property_name = thermal_conductivity #参考某论文来的，不是Fink-Lukuta model（非常复杂）
      coupled_variables = 'T burnup'
      expression = '(1 / ((0.1148 + 0.0035 * (burnup*100*9.3)) + (0.0002474 -8.24e-7 * (burnup*100*9.3)) * T) + 0.0132 * exp(0.00188 * T))'
      block = pellet
    []
    [pellet_specific_heat]
      type = ADParsedMaterial
      property_name = specific_heat #Fink model
      coupled_variables = 'T'  # 需要在AuxVariables中定义Y变量
      expression = '(296.7 * 535.285^2 * exp(535.285/T))/(T^2 * (exp(535.285/T) - 1)^2) + 2.43e-2 * T + (2) * 8.745e7 * 1.577e5 * exp(-1.577e5/(8.314*T))/(2 * 8.314 * T^2)'
    []
    [pellet_elastic_constants]
      type = ADParsedMaterial
      property_name = E #Fink model
      coupled_variables = 'T'  # 需要在AuxVariables中定义Y变量
      expression = '2.334*10^11*(1-2.752*(1-D))*(1-1.0915*10^(-4)*T)'
      constant_names = 'D'
      constant_expressions = '${density_percent}'
    []
    [total_power]
      type = ADPower
      power_history = 'power_history'
      pellet_inner_radius = ${pellet_inner_radius}
      pellet_outer_radius = ${pellet_outer_radius}
      use_rim_effect = true   # 与 BurnupAux 保持一致
      burnup = burnup         # 耦合 AuxVariable，使用其上一时步旧值计算径向因子
      block = pellet
      output_properties = 'total_power radial_power_shape'
      outputs = exodus
    []
    [thermal_eigenstrain_coef]
      type = ADDerivativeParsedMaterial  # 改为ADParsedMaterial
      property_name = thermal_eigenstrain_coef
      coupled_variables = 'T'
      expression = '-4.972e-4+7.107e-6*T+2.581e-9*T^2+1.14e-13*T^3'# 0.6024是5000MWd/tU的转换系数
    []
    [thermal_eigenstrain]
      type = ADComputeVariableFunctionEigenstrain
      eigen_base = '1 1 1 0 0 0'
      prefactor = thermal_eigenstrain_coef
      eigenstrain_name = thermal_eigenstrain
    [../]
    
    [creep_rate]
        type = UO2CreepRateExplicit
        temperature = T
        oxygen_ratio = x
        fission_rate = ${fparse fission_rate}
        theoretical_density = ${fparse density_percent100}
        grain_size = ${grain_size}
        vonMisesStress = vonMises
    []
    [creep_eigenstrain]
        type = UO2CreepEigenstrain
        eigenstrain_name = creep_eigenstrain
        output_properties = 'effective_creep_strain'
        outputs = exodus
    []
    [pellet_strain]
      type = ADComputePlaneSmallStrain 
      eigenstrain_names = 'thermal_eigenstrain creep_eigenstrain'
    []

    [pellet_elasticity_tensor]
      type = ADComputeVariableIsotropicElasticityTensor
      youngs_modulus = E
      poissons_ratio = nu
    []
    [stress]
      type = ADComputeLinearElasticStress
    []
  []


# 线密度转为体积密度的转换系数
power_factor = '${fparse 1000*1/3.1415926/(pellet_outer_radius^2-pellet_inner_radius^2)}' #新加的！！！！！！！！！！！！！！！！！！！！！！
[Functions]
  [power_history] #新加的！！！！！！！！！！！！！！！！！！！！！！
  type = PiecewiseLinear
    x = '0.0 ${Power0_2Time} ${PowMaxTime} ${endTime__100000} ${endTime__50000} ${endTime}'
    y = '0.0 ${LinearPower0_2} ${LinearPower} ${LinearPower} 0 0'
    scale_factor = ${power_factor}
  []
[T_infinity_in]
  #间隙压力随时间的变化
  type = PiecewiseLinear
  x = '0 ${PowMaxTime} ${endTime__100000} ${endTime__50000} ${endTime}'
  y = '293.15 ${initial_T_in} ${initial_T_in} 293.15 293.15'
  scale_factor = 1
[]
[T_infinity_out]
  #间隙压力随时间的变化
  type = PiecewiseLinear
  x = '0 ${PowMaxTime} ${endTime__100000} ${endTime__50000} ${endTime}'
  y = '293.15 ${initial_T_out} ${initial_T_out} 293.15 293.15'
  scale_factor = 1
[]

[]



[Executioner]
  type = Transient # 瞬态求解器
  solve_type = 'NEWTON'
  petsc_options = '-snes_ksp_ew'
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -ksp_gmres_restart'
  petsc_options_value = 'lu       superlu_dist                  51'
    line_search = 'bt'
  automatic_scaling = true # 启用自动缩放功能，有助于改善病态问题的收敛性
  compute_scaling_once = true  # 每个时间步都重新计算缩放
  nl_max_its = 80
  nl_rel_tol = 1e-3 # 非线性求解的相对容差
  nl_abs_tol = 1e-4 # 非线性求解的绝对容差
  l_tol = 5e-4  # 线性求解的容差
  l_abs_tol = 5e-5 # 线性求解的绝对容差
  l_max_its = 200 # 线性求解的最大迭代次数
  # abort_on_solve_fail = true
  dtmin = 1000
  dtmax = 5000000
  end_time = ${endTime} #105000#${endTime} # 总时间24h
  fixed_point_rel_tol =1e-3 # 固定点迭代的相对容差
[]

[Outputs]
  exodus = true #表示输出exodus格式文件
  print_linear_residuals = false
  # hide = 'pellet_area'
  # file_base = 'Output/1'
[]