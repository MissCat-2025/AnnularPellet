




# conda activate moose && dos2unix PC_RS0.125.i &&mpirun -n 3 /home/yp/projects/annular_pellet/annular_pellet-opt -i PC_RS0.125.i
initial_T = 300
initial_T_in = 570.7
initial_T_out = 582.8
EndTime = 2e8
pellet_nu = 0.345
# pellet_thermal_expansion_coef=1e-5#K-1
density_percent = 0.95
density_percent100 = '${fparse density_percent*100}'
pellet_density='${fparse density_percent*10980}'#10431.0*0.85#kg⋅m-3理论密度为10.980
clad_density=6.59e3#kg⋅m-3
# clad_elastic_constants=7.52e10#Pa
clad_nu = 0.334

LinearPower = 90#kW/m

Power0_2Time = '${fparse 2400}'
PowMaxTime = 100000
endTime = 2e8#2e7

LinearPower0_2 = '${fparse LinearPower*0.2}'

# dtmin = 125
Ndt = 200
dt = '${fparse PowMaxTime/Ndt}'
dt2 = '${fparse PowMaxTime/Ndt}'
dtMax = 100000
endTime__100000 = '${fparse endTime-100000}'
endTime__85000 = '${fparse endTime-85000}'
endTime__50000 = '${fparse endTime-50000}'
endTime__30000 = '${fparse endTime-30000}'
# clad_specific_heat=264.5
# clad_thermal_conductivity = 16
clad_thermal_expansion_coef=5.0e-6#K-1
# dt = 50000
fission_rate=1.2e19
grain_size = 10
#conda activate moose && dos2unix Complete2DQuarter.i&&mpirun -n 10 /home/yp/projects/reproduction/reproduction-opt -i Complete2DQuarter.i --mesh-only KAERI_HANARO_UpperRod1.e
#《《下面数据取自[1]Mechanism study and theoretical simulation on heat split phenomenon in dual-cooled annular fuel element》》
pellet_hardness = 15.0
clad_hardness = 129.0
# 双冷却环形燃料几何参数 (单位：mm)
inclad_inner_diameter = 8.633      # 内包壳内直径
inclad_outer_diameter = 9.776    # 内包壳外直径
pellet_inner_diameter = 9.900         # 芯块内直径
pellet_outer_diameter = 14.100         # 芯块外直径
outclad_inner_diameter = 14.224    # 外包壳内直径
outclad_outer_diameter = 15.367     # 外包壳外直径                   # 轴向长度(m)

# 网格控制参数n_azimuthal = 512时网格尺寸为6.8e-5m
n_radial_inner_clad = 8    # 内包壳径向单元数
w = 2 #裂纹尖端时，l是mesh_size的2**w倍
mesh_size = '${fparse 5e-5}' #网格尺寸即可
n_azimuthal = '${fparse int(3.1415*(pellet_outer_diameter)/8/mesh_size*1e-3/2^(w-2))}' #int()取整
n_radial_pellet = '${fparse int((pellet_outer_diameter-pellet_inner_diameter)/mesh_size*1e-3/2^(w-1))}'
n_radial_outer_clad = 8    # 外包壳径向单元数
growth_factor = 1.006       # 径向增长因子
# 计算半径参数 (转换为米)
inner_clad_inner_radius = '${fparse inclad_inner_diameter/2*1e-3}'
inner_clad_outer_radius = '${fparse inclad_outer_diameter/2*1e-3}'
pellet_inner_radius = '${fparse pellet_inner_diameter/2*1e-3}'
pellet_outer_radius = '${fparse pellet_outer_diameter/2*1e-3}'
outer_clad_inner_radius = '${fparse outclad_inner_diameter/2*1e-3}'
outer_clad_outer_radius = '${fparse outclad_outer_diameter/2*1e-3}'
[Mesh]
  [inner_clad1]
    type = AnnularMeshGenerator
    nr = ${n_radial_inner_clad}
    nt = ${n_azimuthal}
    rmin = ${inner_clad_inner_radius}
    rmax = ${inner_clad_outer_radius}
    growth_r = ${growth_factor}
    boundary_id_offset = 10
    dmin = 0
    dmax = 45
    boundary_name_prefix = 'inclad'
  []
  [inner_clad]
    type = SubdomainIDGenerator
    input = inner_clad1
    subdomain_id = 1
  []
  [pellet1]
    type = AnnularMeshGenerator
    nr = ${n_radial_pellet}
    nt = ${n_azimuthal}
    rmin = ${pellet_inner_radius}
    rmax = ${pellet_outer_radius}
    growth_r = ${growth_factor}
        dmin = 0
    dmax = 45
    boundary_id_offset = 20
    boundary_name_prefix = 'pellet'
  []
  [pellet]
    type = SubdomainIDGenerator
    input = pellet1
    subdomain_id = 2
  []
  [outer_clad1]
    type = AnnularMeshGenerator
    nr = ${n_radial_outer_clad}
    nt = ${n_azimuthal}
    rmin = ${outer_clad_inner_radius}
    rmax = ${outer_clad_outer_radius}
    growth_r = ${growth_factor}
        dmin = 0
    dmax = 45
    boundary_id_offset = 30
    boundary_name_prefix = 'outclad'
  []
  [outer_clad]
    type = SubdomainIDGenerator
    input = outer_clad1
    subdomain_id = 3
  []
  [combine]
    type = CombinerGenerator
    inputs = 'inner_clad pellet outer_clad'
  []
  [rename1]
    type = RenameBoundaryGenerator
    input = combine
    old_boundary = 'inclad_rmin inclad_rmax pellet_rmin pellet_rmax outclad_rmin outclad_rmax'
    new_boundary = 'inclad_inner inclad_outer pellet_inner pellet_outer outclad_inner outclad_outer'
  []
  [rename2]
    type = RenameBlockGenerator
    input = rename1
    old_block = '1 2 3'
    new_block = 'inclad pellet outclad'
  []
  #给接触用的边界创建子块
  # 'inclad_inner inclad_outer pellet_inner pellet_outer outclad_inner outclad_outer'
  [pellet_inner_interface]
    type = LowerDBlockFromSidesetGenerator
    input = rename2
    sidesets = 'pellet_inner'
    new_block_id = 300
    new_block_name = pellet_inner_interface
  []
  [pellet_outer_interface]
    type = LowerDBlockFromSidesetGenerator
    input = pellet_inner_interface
    sidesets = 'pellet_outer'
    new_block_id = 301
    new_block_name = pellet_outer_interface
  []
  [inclad_interface]
    type = LowerDBlockFromSidesetGenerator
    input = pellet_outer_interface
    sidesets = 'inclad_outer'
    new_block_id = 302
    new_block_name = inclad_interface
  []
  [outclad_interface]
    type = LowerDBlockFromSidesetGenerator
    input = inclad_interface
    sidesets = 'outclad_inner'
    new_block_id = 303
    new_block_name = outclad_interface
  []
[]




[GlobalParams]
    displacements = 'disp_x disp_y'
    out_of_plane_strain = strain_zz
[]
[AuxVariables]
  [vonMises]
    order = CONSTANT
    family = MONOMIAL
  []
  [hoop_stress]
    order = CONSTANT
    family = MONOMIAL
  []
  [x]
    initial_condition = 0.01
  []
  # 燃耗辅助变量 (FIMA)，由 BurnupAux 在每个时步结束时更新
  [burnup]
    order = CONSTANT
    family = MONOMIAL
    block = pellet
    initial_condition = 1e-12  # 避免首步 Bu=0 导致 pow(0,0.55) 的数值问题
  []
[]

[AuxKernels]
  [./hoop_stress]
    type = ADRankTwoScalarAux
    variable = hoop_stress
    rank_two_tensor = stress
    scalar_type = HoopStress
    point1 = '0 0 0'        # 圆心坐标
    point2 = '0 0 -0.0178'        # 定义旋转轴方向（z轴）
    execute_on = 'TIMESTEP_END'
    block = 'pellet inclad outclad'
  [../]
  [vonMisesStress]
    type = ADRankTwoScalarAux
    variable = vonMises
    rank_two_tensor = stress
    execute_on = 'TIMESTEP_END'
    scalar_type = VonMisesStress
    block = 'pellet inclad outclad'
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
    [temperature_interface_lm_inner]
      block = inclad_interface
    []
    [temperature_interface_lm_outer]
      block = outclad_interface
    []

[]
[Kernels]
  #力平衡方程
    [solid_x]
        type = ADStressDivergenceTensors
        variable = disp_x
        component = 0
      block = 'pellet inclad outclad'
    []
    [solid_y]
        type = ADStressDivergenceTensors
        variable = disp_y
        component = 1
      block = 'pellet inclad outclad'
    []
    [./solid_z]
      type = ADWeakPlaneStress
      variable = strain_zz
      block = 'pellet inclad outclad'
    [../]
    #热传导方程
    [heat_conduction]
      type = ADHeatConduction
      variable = T
      block = 'pellet inclad outclad'
    []
    [hcond_time]
      type = ADHeatConductionTimeDerivative
      variable = T
      block = 'pellet inclad outclad'
    []
    [Fheat_source]
      type = ADMatHeatSource
      variable = T
      material_property = total_power
      block = pellet
    []
[]
[BCs]
  #固定平面
  [y_zero_on_y_plane]
    type = DirichletBC
    variable = disp_y
    boundary = 'pellet_dmin inclad_dmin outclad_dmin'
    value = 0
  []
  # 45度对称面的法向位移惩罚边界条件
  [fortyfive_plane_x]
    type = ADPenaltyInclinedNoDisplacementBC
    variable = disp_x
    boundary = 'pellet_dmax inclad_dmax outclad_dmax'
    component = 0
    penalty = 1e18
    displacements = 'disp_x disp_y'
  []
  [fortyfive_plane_y]
    type = ADPenaltyInclinedNoDisplacementBC
    variable = disp_y
    boundary = 'pellet_dmax inclad_dmax outclad_dmax'
    component = 1
    penalty = 1e18
    displacements = 'disp_x disp_y'
  []

  #芯块包壳间隙压力
  [gap_pressure_fuel_x]
    type = Pressure
    variable = disp_x
    boundary = 'pellet_inner inclad_outer'
    factor = 1
    function = gap_pressure_inner
    use_displaced_mesh = true
  []
  [gap_pressure_fuel_y]
    type = Pressure
    variable = disp_y
    boundary = 'pellet_inner inclad_outer'
    factor = 1
    function = gap_pressure_inner
    use_displaced_mesh = true
  []

    #芯块包壳间隙压力
    [gap_pressure_pellet_outerx]
      type = Pressure
      variable = disp_x
      boundary = 'pellet_outer outclad_inner'
      factor = 1
      function = gap_pressure_outer
      use_displaced_mesh = true
    []
    [gap_pressure_pellet_outery]
      type = Pressure
      variable = disp_y
      boundary = 'pellet_outer outclad_inner'
      factor = 1
      function = gap_pressure_outer
      use_displaced_mesh = true
    []

  [coolant_bc_in]#对流边界条件
    type = ConvectiveFluxFunction
    variable = T
    boundary = 'inclad_inner'
    T_infinity = ${initial_T_in}
    coefficient = coolant_conductance_in#3500 W·m-2 K-1！！！！！！！！！！！！！！！！！！！！！！！！！！！
  []
  [coolant_bc_out]#对流边界条件
  type = ConvectiveFluxFunction
  variable = T
  boundary = 'outclad_outer'
  T_infinity = ${initial_T_out}
  coefficient = coolant_conductance_out#3500 W·m-2 K-1！！！！！！！！！！！！！！！！！！！！！！！！！！！
  []
  #冷却剂压力
  [colden_pressure_fuel_x]
    type = Pressure
    variable = disp_x
    boundary = 'inclad_inner outclad_outer'
    factor = 15.5e6
    use_displaced_mesh = true
  []
  [colden_pressure_fuel_y]
    type = Pressure
    variable = disp_y
    boundary = 'inclad_inner outclad_outer'
    factor = 15.5e6
    use_displaced_mesh = true
  []
[]
[Materials]
    #定义芯块热导率、密度、比热等材料属性
    [pellet_properties2]
      type = ADGenericConstantMaterial
      prop_names = 'density nu pellet_hardness'
      prop_values = '${pellet_density} ${pellet_nu} ${pellet_hardness}'
      block = pellet
    []
    [pellet_thermal_conductivity]
      type = ADParsedMaterial
      property_name = thermal_conductivity #参考某论文来的，不是Fink-Lukuta model（非常复杂）
      coupled_variables = 'T burnup'
      expression = '(1 / ((0.1148 + 0.0035 * (burnup*100*9.3)) + (0.0002474 -8.24e-7 * (burnup*100*9.3)) * T) + 0.0132 * exp(0.00188 * T))'
      block = pellet
    []
    # [pellet_thermal_conductivity] #新加的！！！！！！！！！！！！！！！！！！！！！！
    #   type = ADParsedMaterial
    #   property_name = thermal_conductivity #参考某论文来的，不是Fink-Lukuta model（非常复杂）
    #   coupled_variables = 'T'
    #   expression = '(100/(7.5408 + 17.692*T/1000 + 3.6142*(T/1000)^2) + 6400/((T/1000)^2.5)*exp(-16.35/(T/1000)))'
    #   block = pellet
    # []
    [pellet_specific_heat]
      type = ADParsedMaterial
      property_name = specific_heat #Fink model
      coupled_variables = 'T'  # 需要在AuxVariables中定义Y变量
      expression = '(296.7 * 535.285^2 * exp(535.285/T))/(T^2 * (exp(535.285/T) - 1)^2) + 2.43e-2 * T + (2) * 8.745e7 * 1.577e5 * exp(-1.577e5/(8.314*T))/(2 * 8.314 * T^2)'
      block = pellet
    []
    [pellet_elastic_constants]
      type = ADParsedMaterial
      property_name = E #Fink model
      coupled_variables = 'T'  # 需要在AuxVariables中定义Y变量
      expression = '2.334*10^11*(1-2.752*(1-D))*(1-1.0915*10^(-4)*T)'
      constant_names = 'D'
      constant_expressions = '${density_percent}'
      block = pellet
    []
    [E_clad_elastic_constants]
      type = ADParsedMaterial
      property_name  = E #Fink model
      coupled_variables = 'T'  # 需要在AuxVariables中定义Y变量
      expression = '-46.67e6 * T + 1.09e11'
      block = 'inclad outclad' 
    []

    [clad_properties]
      type = ADGenericConstantMaterial
      prop_names = 'density nu clad_hardness'
      prop_values = '${clad_density} ${clad_nu} ${clad_hardness}'
      block = 'inclad outclad' 
    []
    [clad_specific_heat_T]
      type = ADDerivativeParsedMaterial
      property_name = specific_heat
      coupled_variables = 'T'
      functor_names = 'Cp'
      functor_symbols = 'Cp'
      expression = 'Cp'
      block = 'inclad outclad'
    []
    [clad_thermal_conductivity]
      type = ADDerivativeParsedMaterial  # 改为ADParsedMaterial
      property_name = thermal_conductivity
      coupled_variables = 'T'
      expression = '7.51+2.09e-2*T-1.45e-5*T^2 + 7.67e-9*T^3'
      block = 'inclad outclad'
    []



    [clad_thermal_eigenstrain]
      type = ADComputeThermalExpansionEigenstrain
      eigenstrain_name = thermal_eigenstrain
      stress_free_temperature = ${initial_T}
      thermal_expansion_coeff = ${clad_thermal_expansion_coef}
      temperature = T
      block = 'inclad outclad'
    []

    # 功率密度和径向功率形状因子（AD 材料属性，供热源核使用）
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
    [swelling_coef]
      type = ADDerivativeParsedMaterial  # 改为ADParsedMaterial
      property_name = swelling_coef
      coupled_variables = 'T burnup'
      expression = '(${pellet_density}*5.577e-5*burnup + 1.101e-29*pow(2800-T,11.73)*exp(-0.0162*(2800-T))*(1-exp(-0.0178*${pellet_density}*burnup)))/3'
      block = pellet
            outputs = exodus
      output_properties = 'swelling_coef'
    []
    # 密实化温度因子函数
    [CD_factor]
      type = ADParsedMaterial
      property_name = CD_factor
      coupled_variables = 'T'
      expression = 'if(T < 1023.15, 7.2-0.0086*(T-298.15),1)'
      block = pellet
    []
    [densification_coef]
      type = ADDerivativeParsedMaterial  # 改为ADParsedMaterial
      property_name = densification_coef
      coupled_variables = 'T burnup'
      material_property_names = 'CD_factor(T)'
      expression = '0.03 * (exp(-4.605 * (burnup*1) / (CD_factor * 0.006024)) - 1)/3'# 0.6024是5000MWd/tU的转换系数
      block = pellet
            outputs = exodus
      output_properties = 'densification_coef'
    []
    [thermal_eigenstrain_coef]
      type = ADDerivativeParsedMaterial  # 改为ADParsedMaterial
      property_name = thermal_eigenstrain_coef  
      coupled_variables = 'T'
      outputs = exodus
      output_properties = 'thermal_eigenstrain_coef'
      expression = 'K1*T-K2+K3*exp(-ED/(k*T))' # RELAP5
      constant_names = 'K1 K2 K3 ED k'
      constant_expressions = '1.0e-5 3e-3 4.0e-2 6.9e-20 1.38e-23'
      block = pellet
    []
    # 肿胀应变计算
    [swelling_eigenstrain]
      type = ADComputeVariableFunctionEigenstrain
      eigen_base = '1 1 1 0 0 0'
      prefactor = swelling_coef
      eigenstrain_name = swelling_eigenstrain

      block = pellet
    [../]
    # 肿胀应变计算
    [thermal_eigenstrain]
      type = ADComputeVariableFunctionEigenstrain
      eigen_base = '1 1 1 0 0 0'
      prefactor = thermal_eigenstrain_coef
      eigenstrain_name = thermal_eigenstrain

      block = pellet
    [../]

    # 密实化应变计算
    [densification_eigenstrain]
      type = ADComputeVariableFunctionEigenstrain
      eigen_base = '1 1 1 0 0 0'
      prefactor = densification_coef
      eigenstrain_name = densification_eigenstrain

      block = pellet
    [../]
      [creep_rate]
        type = UO2CreepRateExplicit
        temperature = T
        oxygen_ratio = x
        fission_rate = ${fparse fission_rate}
        theoretical_density = ${fparse density_percent100}
        grain_size = ${grain_size}
        vonMisesStress = vonMises
        block = pellet
      []
      [creep_eigenstrain]
        type = UO2CreepEigenstrain
        eigenstrain_name = creep_eigenstrain
        output_properties = 'effective_creep_strain'
        outputs = exodus
        block = pellet
      []
    [pellet_strain]
      type = ADComputePlaneSmallStrain 
      eigenstrain_names = 'thermal_eigenstrain swelling_eigenstrain densification_eigenstrain creep_eigenstrain'
      block = 'pellet'
    []
    [clad_strain]
      type = ADComputePlaneSmallStrain
      eigenstrain_names = thermal_eigenstrain
      block = 'inclad outclad'
    []
    [pellet_elasticity_tensor]
      type = ADComputeVariableIsotropicElasticityTensor
      youngs_modulus = E
      poissons_ratio = nu
      block = pellet
    []
    [clad_elasticity_tensor]
      type = ADComputeVariableIsotropicElasticityTensor
      youngs_modulus = E
      poissons_ratio = nu
      block = 'inclad outclad'
  []
    [stress]
      type = ADComputeLinearElasticStress
      block = 'pellet inclad outclad'
    []
    
[]


# 机械接触 - 模拟芯块与包壳的力传递

[Executioner]
  type = Transient # 瞬态求解器
  # solve_type = PJFNK
  petsc_options_iname = '-pc_type -ksp_type'
  petsc_options_value = 'lu preonly'
  #   solve_type = NEWTON
  # petsc_options = '-snes_converged_reason -ksp_converged_reason -snes_linesearch_monitor'
  # petsc_options_iname = '-pc_type -sub_pc_type -sub_ksp_type'
  # petsc_options_value = 'asm      lu           preonly'
  solve_type = PJFNK
  # petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_ksp_type -sub_pc_type -pc_asm_overlap'
  # petsc_options_value = 'asm      31                  preonly       lu           1'
  # solve_type = 'NEWTON'
  # petsc_options_iname = '-pc_type   -snes_type        -snes_qn_type   -snes_qn_scale_type -snes_linesearch_type' 
  # petsc_options_value = 'lu         qn               lbfgs           jacobian           bt'
  # petsc_options_iname = '-pc_type -ksp_type' 
  # petsc_options_value = 'lu gmres' 
  automatic_scaling = true # 启用自动缩放功能，有助于改善病态问题的收敛性
  compute_scaling_once = true  # 每个时间步都重新计算缩放
  # reuse_preconditioner = true
  # reuse_preconditioner_max_linear_its = 20
  line_search =  contact
  contact_line_search_ltol = 0.5
  contact_line_search_allowed_lambda_cuts = 1
  nl_max_its = 10
  nl_rel_tol = 1e-4 # 非线性求解的相对容差
  nl_abs_tol = 1e-6 # 非线性求解的绝对容差
  l_tol = 1e-5  # 线性求解的容差
  l_abs_tol = 1e-7 # 线性求解的绝对容差
  l_max_its = 50 # 线性求解的最大迭代次数
  accept_on_max_fixed_point_iteration = true # 达到最大迭代次数时接受解
  dtmin = 1e-6
  dtmax = 100000
  end_time = ${EndTime} # 总时间24h

  fixed_point_rel_tol =1e-4 # 固定点迭代的相对容差
  [TimeStepper]
    type = FunctionDT
    function = dt_limit_func
  []
[]

[Postprocessors]
  # 已有
  [burnup_avg]
    type = ElementAverageValue
    variable = burnup
    block = pellet
    execute_on = 'TIMESTEP_END'
  []
  [pellet_inner_heat_rate]
    type = ADSideDiffusiveFluxIntegral
    variable = T
    boundary = pellet_inner
    diffusivity = thermal_conductivity
    execute_on = 'TIMESTEP_END'
  []
  [pellet_outer_heat_rate]
    type = ADSideDiffusiveFluxIntegral
    variable = T
    boundary = pellet_outer
    diffusivity = thermal_conductivity
    execute_on = 'TIMESTEP_END'
  []
  [pellet_inner_T_avg]
    type = SideAverageValue
    variable = T
    boundary = pellet_inner
    execute_on = 'TIMESTEP_END'
  []
  [inclad_outer_T_avg]
    type = SideAverageValue
    variable = T
    boundary = inclad_outer
    execute_on = 'TIMESTEP_END'
  []
  [pellet_outer_T_avg]
    type = SideAverageValue
    variable = T
    boundary = pellet_outer
    execute_on = 'TIMESTEP_END'
  []
  [outclad_inner_T_avg]
    type = SideAverageValue
    variable = T
    boundary = outclad_inner
    execute_on = 'TIMESTEP_END'
  []
  [pellet_inner_perimeter]
    type = AreaPostprocessor
    boundary = pellet_inner
    execute_on = 'initial timestep_end'
  []
  
  [pellet_outer_perimeter]
    type = AreaPostprocessor
    boundary = pellet_outer
    execute_on = 'initial timestep_end'
  []
  [h_eq_inner]
    type = ParsedPostprocessor
    expression = 'abs(pellet_inner_heat_rate) / (pellet_inner_perimeter*max(pellet_inner_T_avg - ${initial_T}, 1e-6))'
    pp_names = 'pellet_inner_heat_rate pellet_inner_T_avg pellet_inner_perimeter'
  []
  [h_gap_eq_inner]
    type = ParsedPostprocessor
    expression = 'abs(pellet_inner_heat_rate) / (pellet_inner_perimeter*max(pellet_inner_T_avg - inclad_outer_T_avg, 1e-6))'
    pp_names = 'pellet_inner_heat_rate pellet_inner_T_avg pellet_inner_perimeter inclad_outer_T_avg'
  []
  [h_eq_outer]
    type = ParsedPostprocessor
    expression = 'abs(pellet_outer_heat_rate) / (pellet_outer_perimeter*max(pellet_outer_T_avg - ${initial_T}, 1e-6))'
    pp_names = 'pellet_outer_heat_rate pellet_outer_T_avg pellet_outer_perimeter'
  []
  [h_gap_eq_outer]
    type = ParsedPostprocessor
    expression = 'abs(pellet_outer_heat_rate) / (pellet_outer_perimeter*max(pellet_outer_T_avg - outclad_inner_T_avg, 1e-6))'
    pp_names = 'pellet_outer_heat_rate pellet_outer_T_avg pellet_outer_perimeter outclad_inner_T_avg'
  []
  [pellet_T_max]
    type = ElementExtremeValue
    variable = T
    value_type = max
    block = pellet
    execute_on = 'TIMESTEP_END'
  []
[]

[Outputs]
  exodus = true #表示输出exodus格式文件
  print_linear_residuals = false
  file_base = 'gap_conductance1/2D'
  # csv = true
  # [TimeStepper]
  #   type = FunctionDT
  #   function = dt_limit_func
  # []
  #   [TimeStepper]
  #   type = IterationAdaptiveDT
  #   dt = 1
  #   growth_factor = 1.5
  #   cutback_factor = 0.5
  #   optimal_iterations = 8
  #   iteration_window = 4
  # []
  [./csv]
    type = CSV
    precision = 5  # 默认保留1位小数
    execute_on = 'TIMESTEP_END'
    show = 'burnup_avg h_eq_inner h_eq_outer h_gap_eq_inner h_gap_eq_outer pellet_inner_T_avg pellet_T_max pellet_outer_T_avg'
  [../]
[]

# 线密度转为体积密度的转换系数
power_factor = '${fparse 1000*1/3.1415926/(pellet_outer_radius^2-pellet_inner_radius^2)}' #新加的！！！！！！！！！！！！！！！！！！！！！！
[Functions]
  [coolant_conductance_in]
    type = PiecewiseLinear
    x = '0 ${EndTime}'
    y = '34000 34000'
    scale_factor = 1         # 保持原有的转换因子
  []
  [coolant_conductance_out]
    type = PiecewiseLinear
    x = '0 ${EndTime}'
    y = '34000 34000'
    scale_factor = 1         # 保持原有的转换因子
  []
  [power_history] #新加的！！！！！！！！！！！！！！！！！！！！！！
  type = PiecewiseLinear
  # data_file = '../../../.././power_history2.csv'    # 创建一个包含上述数据的CSV文件，数据为<s,w/m>
  # format = columns                 # 指定数据格式为列式
  # scale_factor = ${power_factor}         # 保持原有的转换因子
  # 论文中只给了线密度，需要化为体积密度
    x = '0.0 ${Power0_2Time} ${PowMaxTime} ${endTime__100000} ${endTime__50000} ${endTime}'
    y = '0.0 ${LinearPower0_2} ${LinearPower} ${LinearPower} 0 0'
    scale_factor = ${power_factor}
  []
  [Cp] #新加的！！！！！！！！！！！！！！！！！！！！！！
    type = PiecewiseLinear
        x = '100 300 400 640 1090 1093 1113 1133 1153 1173 1193 1213 1233 1248 2500'
        y = '281 281 302 331 375 502 590 615 719 816 770 619 469 356 356'
    scale_factor = 1
  []

  [gap_pressure_inner] #新加的！！！！！！！！！！！！！！！！！！！！！！
    #间隙压力随时间的变化
    type = ParsedFunction
    expression = '1.2e6 + 4.0e6*(1.0 - exp(-t/1e8))'
  []
  [gap_pressure_outer] #新加的！！！！！！！！！！！！！！！！！！！！！！
    #间隙压力随时间的变化
    type = ParsedFunction
    expression = '1.2e6 + 4.0e6*(1.0 - exp(-t/1e8))'
  []
  [helium_k]
    type = ParsedFunction
    expression = '0.04679 + 3.81e-4*t - 6.786e-8*t^2'
  []
  [dt_limit_func]
  type = ParsedFunction
  expression = 'if(t < 100000, 2000,
                 if(t < (${PowMaxTime}*1.2), ${dt},
                 if(t < (${endTime__100000}-${dtMax}),${dtMax},
                 if(t < (${endTime__100000}),(10*${dt}),
                 if(t < (${endTime__85000}),(2*${dt}),
                 if(t < (${endTime__30000}),${dt2},
                 if(t < (${endTime__30000}+10000),(4*${dt2}),5000)))))))'
[]
[]


[Contact]
  [mechanical_contact_inner]
    primary = inclad_outer
    secondary = pellet_inner
    model = frictionless
    formulation = mortar # 约束施加方式：mortar（基于弱形式/LM）
    correct_edge_dropping = true # 防止边缘节点丢失接触
    tangential_tolerance = 1e-6 # 切向滑移容差（影响摩擦/滑移检测）
    normal_smoothing_distance = 1e-7 # 法向光滑距离,
    #在此距离范围内，主面上的节点会被用来平均从面的法向，使法向连续变化，避免因网格离散导致的接触力震荡。该值应远小于局部几何特征尺寸，且不宜大于 capture_tolerance。
    capture_tolerance = 6.349e-7 # 接触捕捉容差（关键参数）
    # 这是实现“间隙小于某值即视为接触”的核心参数。
# 它定义了一个法向“捕捉”距离：当从面节点到主面的有向距离 ≤ capture_tolerance 时，该节点即被认为进入接触状态，并激活无穿透约束。
  []
  [mechanical_contact_outer]
    primary = outclad_inner
    secondary = pellet_outer
    model = frictionless
    formulation = mortar
    correct_edge_dropping = true
    tangential_tolerance = 1e-6
    normal_smoothing_distance = 1e-7 # 法向光滑距离,
    #在此距离范围内，主面上的节点会被用来平均从面的法向，使法向连续变化，避免因网格离散导致的接触力震荡。该值应远小于局部几何特征尺寸，且不宜大于 capture_tolerance。
    capture_tolerance = 6.349e-7 # 接触捕捉容差（关键参数）
  []
[]
# 'inclad_inner inclad_outer pellet_inner pellet_outer outclad_inner outclad_outer'
[UserObjects]
  [gas_inner]
    type = GapFluxModelRossStouteGasConduction
    boundary = pellet_inner
    temperature = T
    gas_thermal_conductivity = helium_k
    gas_pressure = gap_pressure_inner
    gas_mixture_mode = HELIUM_ONLY
    fuel_roughness = 2.0e-6
    clad_roughness = 1.0e-6
  []
  [gas_outer]
    type = GapFluxModelRossStouteGasConduction
    boundary = pellet_outer
    temperature = T
    gas_thermal_conductivity = helium_k
    gas_pressure = gap_pressure_outer
    gas_mixture_mode = HELIUM_ONLY
    fuel_roughness = 2.0e-6
    clad_roughness = 1.0e-6
  []
  [radiation_inner]
    type = GapFluxModelRadiation
    boundary = pellet_inner
    temperature = T
    primary_emissivity = 0.78
    secondary_emissivity = 0.82
  []
  [radiation_outer]
    type = GapFluxModelRadiation
    boundary = pellet_outer
    temperature = T
    primary_emissivity = 0.78
    secondary_emissivity = 0.82
  []
  [ThermalContact_inner]
    type = GapFluxModelRossStouteContactConduction
    boundary = pellet_inner
    temperature = T
    contact_pressure = contact_pressure
    primary_conductivity = thermal_conductivity
    secondary_conductivity = thermal_conductivity
    primary_hardness = clad_hardness
    secondary_hardness = pellet_hardness
    fuel_roughness = 0.8e-6
    clad_roughness = 0.5e-6
  []
  [ThermalContact_outer]
    type = GapFluxModelRossStouteContactConduction
    boundary = pellet_outer
    temperature = T
    contact_pressure = contact_pressure
    primary_conductivity = thermal_conductivity
    secondary_conductivity = thermal_conductivity
    primary_hardness = clad_hardness
    secondary_hardness = pellet_hardness
    fuel_roughness = 0.8e-6
    clad_roughness = 0.5e-6
  []
[]

[Constraints]
  [thermal_contact_inner]
    type = ModularGapConductanceConstraint
    variable = temperature_interface_lm_inner
    secondary_variable = T
    use_displaced_mesh = true
    displacements = 'disp_x disp_y'
    primary_boundary = pellet_inner
    primary_subdomain = pellet_inner_interface
    secondary_boundary = inclad_inner
    secondary_subdomain = inclad_interface
    gap_geometry_type = CYLINDER
    cylinder_axis_point_1 = '0 0 0'
    cylinder_axis_point_2 = '0 0 1'
    gap_flux_models = 'gas_inner radiation_inner ThermalContact_inner'
  []
    [thermal_contact]
    type = ModularGapConductanceConstraint
    variable = temperature_interface_lm_outer
    secondary_variable = T
    use_displaced_mesh = true
    displacements = 'disp_x disp_y'
    primary_boundary = pellet_outer
    primary_subdomain = pellet_outer_interface
    secondary_boundary = outclad_inner
    secondary_subdomain = outclad_interface
    gap_geometry_type = CYLINDER
    cylinder_axis_point_1 = '0 0 0'
    cylinder_axis_point_2 = '0 0 1'
    gap_flux_models = 'gas_outer radiation_outer ThermalContact_outer'
  []
[]