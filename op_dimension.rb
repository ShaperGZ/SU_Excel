class Op_Dimension
  def self.set_bd_size(gp,size)
    osize=self.get_size(gp)
    scale=[1,1,1]
    for i in 0..2
      scale[i]=size[i]/osize[i]
    end

    ArchUtil.scale_3d(gp,scale)

    gp.set_attribute("BuildingBlock", "bd_width", size[0])
    gp.set_attribute("BuildingBlock", "bd_depth", size[1])
    gp.set_attribute("BuildingBlock", "bd_height", size[2])

  end



  def self.get_size(gp)
    group=gp
    height = (group.local_bounds.max.z * gp.transformation.zscale).to_m.round(3)

    width_max = (group.local_bounds.max.x * gp.transformation.xscale).to_m.round(3)
    width_min = (group.local_bounds.min.x * gp.transformation.xscale).to_m.round(3)
    width = width_max-width_min

    depth_max = (group.local_bounds.max.y * gp.transformation.yscale).to_m.round(3)
    depth_min = (group.local_bounds.min.y * gp.transformation.yscale).to_m.round(3)
    depth = depth_max - depth_min

    return width,depth,height
  end

  def self.is_equal_size(gp,size)
    osize=Op_Dimension.get_size(gp)
    for i in 0..2
      return false if osize[i] != size[i].m
    end
    return true
  end

end