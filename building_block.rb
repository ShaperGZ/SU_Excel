class BuildingBlock < Arch::Block

  #类静态函数，保证不重复加载监听器
  def self.create_or_invalidate(g,zone=nil,tower=nil,program=nil,ftfh=nil)
    # 删除非法reference只在读取新档案时有用，但放在这里保证每次选择都检查并清除非法组
    self.remove_deleted()

    # 如果这个组已经创建过，不能再创建，因为已经有了监听器
    # 所以只更新其属性，然后invalidate
    # 否则就新创建一个 BuuildingBlock, 在构造器里会invalidate

    if !g.deleted? and @@created_objects.key?(g.guid)
      block=@@created_objects[g.guid]
      if program==nil and ftfh==nil
        zone=g.get_attribute("BuildingBlock","zone")
        tower=g.get_attribute("BuildingBlock","tower")
        program=g.get_attribute("BuildingBlock","program")
        ftfh=g.get_attribute("BuildingBlock","ftfh")
      end

      block.setAttr4(zone,tower,program,ftfh)
      block.invalidate
      return block
    else
      zone="zone1" if zone==nil
      tower="t1" if tower==nil
      program="retail" if program==nil
      ftfh=3 if ftfh==nil
      return BuildingBlock.new(g,zone,tower,program,ftfh)
    end
  end

  def self.remove_deleted()
    hs=@@created_objects
    count=0
    hs.keys.each{|k|
      gp=hs[k].gp
      if gp==nil or gp.deleted?
        hs.delete(k)
        count+=1
      end
    }
    p "#{count} objects are deleted from BuildingBlock.created_objects"
  end

  @@enable_dynamic_update_base_area = true
  def self.enable_dynamic_update_base_area()
    @@enable_dynamic_update_base_area
  end
  def self.enable_dynamic_update_base_area=(val)
    @@enable_dynamic_update_base_area = val
  end

  def self.cal_base_area()
    # 1. 把全部建筑放进一个list里
    blocks=@@created_objects.values.dup
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
    excel = SUExcel.excel
    excel.update_base_area(sprintf("%.2f",base_area))
  end

  ##### instance ########################

  attr_accessor :updators
  def initialize(gp,zone="zone1",tower="t1",program="retail",ftfh=3)
    super(gp)
    setAttr4(zone,tower,program,ftfh)
    add_updators()
    invalidate
  end

  def add_updators()
    @updators << BH_FaceConstrain.new(gp,self)
    @updators << BH_CalArea.new(gp,self)
    @updators << BH_Visualize.new(gp,self)
    @updators << BH_Dimension.new(gp,self)
  end

  def onClose(e)
    super(e)
    SUExcel.data_manager.onChangeEntity(e) if SUExcel.data_manager != nil
    BuildingBlock.update_base_area
  end

  def onChangeEntity(e)
    super(e)
    SUExcel.data_manager.onChangeEntity(e) if SUExcel.data_manager != nil

    #分解或删除组时触发
    if @gp.valid? == false
      puts "除去created_objects里的 Deleted Entity"
      keys = []
      BuildingBlock.created_objects.keys.each{|key|
        if BuildingBlock.created_objects[key].gp.valid? == false
          keys << key
        end
      }
      keys.each{|key|
        BuildingBlock.created_objects.delete(key)
      }
    end

    BuildingBlock.update_base_area
  end

  def setAttr4(zone,tower,program,ftfh)
    dict= Hash.new
    dict["zone"]=zone
    dict["tower"]=tower
    dict["program"]=program
    dict["ftfh"]=ftfh
    setAttrByDict(dict)
  end

  def setAttrByDict(dict)
    dict.each{|kvp|
      k=kvp[0]
      v=kvp[1]
      @gp.set_attribute("BuildingBlock",k,v)
      p "setting #{k} to #{v}"
    }
  end

  def invalidate()
    @updators.each{|e| e.onClose(@gp)}
    SUExcel.data_manager.onChangeEntity(@gp) if SUExcel.data_manager != nil
    # 测试性每次更新都计算底面积，如果太慢，就不要放在invalidate里
    BuildingBlock.update_base_area

  end

end