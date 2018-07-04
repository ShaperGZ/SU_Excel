#module VisualModes
#  @@concept=11
#  @@textured=22
#  @@model=33
#end

class BH_Visualize < Arch::BlockUpdateBehaviour
  # 静态属性/方法
  # 方案颜色从这里提取，在打开sketchup时更新一次，

  # 当前的材质模式
  @@mode= 1
  #@@mode=VisualModes.textured

  #这个是以program为key，material为值的字典
  @@scheme_colors=Hash.new
  def self.scheme_colors
    return @@scheme_colors
  end
  # entry读完颜色后把颜色dictionary set给这个类
  def self.set_scheme_colors(dict, forced=false)
    #创建并添加到材质库
    if @@scheme_colors.size ==0 or forced
      @@scheme_colors = self._create_materials(dict)
    end
  end


  def self._create_materials(dict)
    p "创建颜色"
    mats=Hash.new
    model = Sketchup.active_model
    materials = model.materials
    dict.keys.each{|key|
      color = dict[key]
      if !mats.key?(key)
        m = materials.add(key)
        m.color = Sketchup::Color.new(color[0].to_i, color[1].to_i, color[2].to_i)
        mats[key]=m
      end
    }
    p "return mats:#{mats}"
    return mats
  end

  # 全局设为方案模式
  def self.set_modes_concept()
    @@mode = 1
    ents=BuildingBlock.created_objects
    return if ents == nil
    # TODO：make better accessor for updators
    ents.values.each{|e|
      e.updators[2].set_mode(1)
    }
  end

  #全局设为贴图模式
  def self.set_modes_texture()
    @@mode = 2
    ents=BuildingBlock.created_objects
    return if ents == nil
    ents.values.each{|e|
      e.updators[2].set_mode(2)
    }
  end

  def self.setMode(num)
    @@mode = num
    case num
    when 1
      set_modes_concept
    when 2
      set_modes_texture
    end
  end

  #-------------------------------------------------
  # @material 以面(Face)为key, 材质为value
  #self.mode=VisualModes.textured
  def initialize(gp,host)
    super(gp,host)
    @mode=1
    @last_mode=1
    #以显示模式为key,Hash为value的字典
    @materials = Hash.new



   #TODO: create static hash to keep created objects
    puts "Visualize 初始化！"
  end

  # 监听行为
  @is_opened=false
  def onOpen(e)
    @is_opened =true
    # 为当前编辑的组切换到“贴图”模式 ！
    set_mode(2)
  end

  def onClose(e)
    if !@is_opened
      set_mode(@@mode)
      return
    end

    @is_opened=false
    # 因为打开组时，当前编辑的组强被迫变成贴图模式
    # 设计师会在编辑过程中赋予材质
    # 所以关闭组时
    # 1.清空@textures
    # 2.把每一个面所对应的材质hash到 @textures
    # 3.根据BH_Visualize.mode为每个面赋予材质，譬如在编辑前是方案模式的就在记录完才之后赋回方案颜色。
    p "触发OnClose() #{@gp}"

    save_material
    set_mode(@@mode)
  end

  def set_mode(num)
    @mode=num
    case num
    when 1
      set_mode_concept
    when 2
      set_mode_texture
    end
    @last_mode=@mode
  end

  # 设为方案模式
  def set_mode_concept()
    program=@gp.get_attribute("BuildingBlock","program")
    mat = @@scheme_colors[program]
    mat = 'white' if mat ==nil
    @gp.entities.each{|e|
      if e.class == Sketchup::Face
        e.material=mat
      end
    }
  end


  #设为贴图模式
  def set_mode_texture()
    # 从@textures里为每个面分配材质，如果无记录的面则给default材质
    puts "贴图模式"
    @host.enableUpdate = false
    p "@materials.key?(2) #{@materials.key?(2)}"
    if !@materials.key?(2)
      _set_all_face_to_white
      @host.enableUpdate = true
      return
    end

    dict=@materials[2]
    if dict ==nil
      p ' dict == nil'
      _set_all_face_to_white
      @host.enableUpdate = true
      return
    end

    entity=@gp
    entity.entities.each {|ent|
      if ent.class == Sketchup::Face
        p "dict.key?(ent.entityID) #{dict.key?(ent.entityID)}"
        p "dict[ent.entityID] != nil #{dict[ent.entityID] != nil}"
        if dict.key?(ent.entityID) and  dict[ent.entityID] != nil
          ent.material =dict[ent.entityID]
        else
          ent.material= 'white'
        end
      end
    }
    @host.enableUpdate = true
  end

  def _set_all_face_to_white()
    entity=@gp
    entity.entities.each {|ent|
      if ent.class == Sketchup::Face
        ent.material= 'white'
      end
    }
  end


  def save_material(mode=nil)
    mode=@mode if mode ==nil
    key=mode
    @materials[key]=Hash.new
    _save_material(@gp, @materials[key])
    _save_materials_to_attribues(key)
  end


  def _save_material(entity, dict)
    entity.entities.each {|ent|
      if ent.class == Sketchup::Face
        dict[ent.entityID] = ent.material
      end
    }
  end

  def _save_materials_to_attribues( key )
    # TODO: 把 @materials[key] 数据变成list
    # 格式是 texture_indexed_list= [ [face.entityID,face.material.name],... ]
    texture_indexed_list=[]
    e.set_attribute("BuildingBlock","texture_mode", texture_indexed_list)
  end

  def _load_materials_from_attribute(key)
    # TODO: 把  list数据变成 @materials[key]
    texture_indexed_list = e.get_attribute("BuildingBlock","texture_mode")

  end

end