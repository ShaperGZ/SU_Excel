class BH_Dimension < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    super(gp,host)
  end

  def onClose(e)
    super(e)
    invalidate
  end

  def onChangeEntity(e)
    super(e)
    invalidate
  end

  def invalidate()
    # TODO：
    # 1. 通过bounds.max.z - bounds.min.z 提取高度信息
    # @gp.bounds.max.z
    # 2. 提取ftfh 计算层数
    #ftfh=@gp.get_attribute("BuildingBlock","ftfh")
    # 3. 把高度信息和层数set attribute到组里
    return if @gp.valid? == false
    p "set高度和楼层数"
    group = @gp
    bd_height = (group.bounds.max.z-group.bounds.min.z)/ $m2inch
    group.set_attribute("BuildingBlock","bd_height",sprintf("%.2f",bd_height))

    ftfh = group.get_attribute("BuildingBlock","ftfh")
    bd_floors = bd_height/ftfh
    group.set_attribute("BuildingBlock","bd_floors",bd_floors.to_i)
  end
end