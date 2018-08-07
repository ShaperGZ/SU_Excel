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
    #作用是把实际尺寸记录在组里

    # TODO：
    # 1. 通过bounds.max.z - bounds.min.z 提取高度信息
    # @gp.bounds.max.z
    # 2. 提取ftfh 计算层数
    # ftfh=@gp.get_attribute("BuildingBlock","ftfh")
    # 3. 把高度信息和层数set attribute到组里
    return if @gp.valid? == false
    #p "set高度和楼层数"
    group = @gp

    bd_width,bd_depth,bd_height=Op_Dimension.get_size(@gp)

    group.set_attribute("BuildingBlock","bd_height",bd_height)
    group.set_attribute("BuildingBlock","bd_width",bd_width)
    group.set_attribute("BuildingBlock","bd_depth",bd_depth)
  end


end