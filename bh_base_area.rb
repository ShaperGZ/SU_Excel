class BH_BaseArea < Arch::BlockUpdateBehaviour

  @@enable_dynamic_update_base_area = true
  def self.enable_dynamic_update_base_area()
    @@enable_dynamic_update_base_area
  end
  def self.enable_dynamic_update_base_area=(val)
    @@enable_dynamic_update_base_area = val
  end

  def self.cal_base_area()
    return 0 if BuildingBlock.created_objects.size < 1
    # 1. 把全部建筑放进一个list里
    blocks=BuildingBlock.created_objects.values.dup
    gps=[]
    blocks.each{|b|
      gps<<b.gp
    }
    # 2. 用 ArchUtil.union_groups(gps) 得出其union合体组
    union=ArchUtil.union_groups(gps)
    xscale=union.transformation.xscale
    yscale=union.transformation.yscale
    scale_factor=xscale*yscale

    # 3. 合体后的Face如果满足以下条件
    #       a，法线朝下
    #       b, 高度<15m
    # 计算满足条件的face的面积总合，就是基底面积 base_area
    # return 基底面积 base_area
    base_area=0
    union.entities.each{|e|
      if e.class == Sketchup::Face and e.normal.z==-1 and e.vertices[0].position.z < (15*$m2inch)
        base_area+=e.area
      end
    }
    base_area/= $m2inchsq
    union.entities.clear!      #删除合并的组
    return base_area * scale_factor
  end

  def self.update_base_area()
    return if !@@enable_dynamic_update_base_area
    base_area=self.cal_base_area()
    p "updating base area = #{base_area}"
    em=SUExcel::ExcelManager.get_singleton
    em.update_base_area(sprintf("%.2f",base_area))
  end



  def initialize(gp,host)
    super(gp,host)
    @parapet_container = nil
    @parapets=Hash.new
  end


  def onClose(e)
    BH_BaseArea.update_base_area
  end

  def onChangeEntity(e)
    BH_BaseArea.update_base_area
  end
end