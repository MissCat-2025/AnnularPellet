# conda activate moose && mpirun -n 8 /home/yp/projects/annular_pellet/annular_pellet-opt -i mesh0.125.i --mesh-only

# 双冷却环形燃料几何参数 (单位：mm)(无内外包壳)
pellet_inner_diameter = 10.291         # 芯块内直径mm
pellet_outer_diameter = 14.627         # 芯块外直径mm
w = 2 #裂纹尖端时，l是mesh_size的2**w倍
mesh_size = '${fparse 5e-5}' #网格尺寸即可
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
    new_boundary = 'pellet_inner pellet_outer xplane fortyfive_plane'
  []
  [rename2]
    type = RenameBlockGenerator
    input = rename
    old_block = '1'
    new_block = 'pellet'
  []
[]