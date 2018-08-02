class BH_Dimension < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    super(gp,host)
  end

  def onClose(e)
    super(e)
    invalidate
  end

  def onChangeEntity(e, invalidated)
    return if not invalidated[2]
    p '-> BH_Dimension.onChangeEntity'
    super(e, invalidated)
    invalidate
  end

  def invalidate()
    # TODO：
    # 1. 通过bounds.max.z - bounds.min.z 提取高度信息
    # @gp.bounds.max.z
    # 2. 提取ftfh 计算层数
    # ftfh=@gp.get_attribute("BuildingBlock","ftfh")
    # 3. 把高度信息和层数set attribute到组里
    return if @gp.valid? == false
    #p "set高度和楼层数"
    group = @gp

    bd_width,bd_depth,bd_height=BH_Dimension.get_size(@gp)

    group.set_attribute("BuildingBlock","bd_height",bd_height)
    group.set_attribute("BuildingBlock","bd_width",bd_width)
    group.set_attribute("BuildingBlock","bd_depth",bd_depth)
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
end