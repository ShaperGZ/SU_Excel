require 'sketchup.rb'
#module VisualModes
#  @@concept=11
#  @@textured=22
#  @@model=33
#end

module DisplayModes
  def self.SCHEME()
    "displaymodes.scheme"
  end
  def self.TEXTURED()
    "displaymodes.textured"
  end
end

class BH_Visualize < Arch::BlockUpdateBehaviour
  # 静态属性/方法
  # 方案颜色从这里提取，在打开sketchup时更新一次，

  # 当前的材质模式
  @@mode= DisplayModes.SCHEME

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
        mats[key]= m
      end
    }
    return mats
  end

  # 全局设为方案模式
  def self.set_modes_concept()
    @@mode = DisplayModes.SCHEME
    self.set_mode(@@mode)
  end

  #全局设为贴图模式
  def self.set_modes_texture()
    @@mode = DisplayModes.TEXTURED
    self.set_mode(@@mode)
  end

  def self.set_mode(mode)
    @@mode = mode
    ents=BuildingBlock.created_objects
    return if ents == nil
    # TODO：make better accessor for updators
    ents.values.each{|e|
      e.updators[2].set_mode(@@mode)
    }
  end

  #-------------------------------------------------

  def initialize(gp,host)
    super(gp,host)
    @mode= DisplayModes.SCHEME
    #@last_mode
    @Materials_hash = Hash.new
    puts "Visualize 初始化！"
  end

  # 监听行为
  @is_opened=false
  def onOpen(e)
    @is_opened =true
    set_mode(DisplayModes.TEXTURED)
    p "点开模型，切换到贴图模式"
  end

  def onClose(e)
    if !@is_opened    #如果未进入就退出
      set_mode(@@mode)   #设置完成按mode决定是否给颜色
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
    p "原模式是 #{@@mode}"
    save_material
    set_mode(@@mode)
    p "存完材质，切换到原模式"
  end

  def onChangeEntity(e)
    SUExcel.update_area(e)
  end

  def set_mode(mode)
    @mode = mode        #将@@mode赋给@mode
    case mode
    when DisplayModes.SCHEME
      _set_mode_concept
    when DisplayModes.TEXTURED
      _set_mode_texture
    end
    #@last_mode = @mode
  end

  # 设为方案模式
  def _set_mode_concept()
    puts "方案模式"
    program=@gp.get_attribute("BuildingBlock","program")
    mat = @@scheme_colors[program]
    mat = 'white' if mat == nil
    p "GUID:#{@gp.guid}"
    @gp.entities.each{|e|
      if e.class == Sketchup::Face
        e.material= mat
      end
    }
  end

  #设为贴图模式
  def _set_mode_texture()
    # 从@textures里为每个面分配材质，如果无记录的面则给default材质
    puts "贴图模式"
    @host.enableUpdate = false

    p "包含该模式#{@mode}吗？ #{is_material_key(@mode)}"
    #不包含的情况
    if !is_material_key(@mode)
      _set_all_face_to_white
      @host.enableUpdate = true
      return
    end

    #包含的情况
    #dict= _load_materials_from_attribute(DisplayModes.TEXTURED)    #取出哈希
    dict = _load_materials(DisplayModes.TEXTURED)
    p "哈希为：#{dict}"

    if dict == nil
      p "哈希为空！"
      _set_all_face_to_white
      @host.enableUpdate = true
      return
    end

    entity=@gp
    entity.entities.each {|ent|
      if ent.class == Sketchup::Face
        p "哈希包含面#{ent.entityID}的key #{dict.key?(ent.entityID)}"
        p "该哈希键对应的值不为空 #{dict[ent.entityID] != nil}"
        if dict.key?(ent.entityID) and  dict[ent.entityID] != nil
          ent.material =dict[ent.entityID]
        else
          ent.material= 'white'
        end
      end
    }
    @host.enableUpdate = true
  end

  def is_material_key(mode)
    r = @Materials_hash.include?(mode)
    return r
  end

  def _set_all_face_to_white()
    entity=@gp
    entity.entities.each {|ent|
      if ent.class == Sketchup::Face
        ent.material= 'white'
      end
    }
  end

  #将当前智能组的材质存储起来
  def save_material()
    #_save_materials_to_attribues(@mode)
    _save_materials(@mode)
  end

  def _save_materials(mode)
    entity = @gp
    texture_indexed_list=[]
    entity.entities.each {|ent|
      if ent.class == Sketchup::Face
        texture_indexed_list << [ent.entityID,ent.material]
      end
    }
    @Materials_hash[mode] = texture_indexed_list
  end

  def _load_materials(mode)
    dic = Hash.new
    @Materials_hash[mode].each{|e|
      dic[e[0]] = e[1]
    }
    p "获取的哈希：#{dic}"
    return dic
  end

  #实验证明，set_attribute无法存入material，读取时显示为nil
  def _save_materials_to_attribues(mode)
    # TODO: 把每个面的材质 数据变成list
    # 格式是 texture_indexed_list= [ [face.entityID,face.material.name],... ]
    entity = @gp
    texture_indexed_list=[]

    entity.entities.each {|ent|
      if ent.class == Sketchup::Face
        texture_indexed_list << [ent.entityID,ent.material]
      end
    }
    p "材质列表为：#{texture_indexed_list}"
    entity.set_attribute("BuildingBlock",mode, texture_indexed_list)
    p "存完后试着读一下: #{entity.get_attribute("BuildingBlock",mode)}"
  end
  def _load_materials_from_attribute(mode)
    # TODO: 把  list数据变成 hash
    # hash的格式是 face为key, material为value
    e = @gp
    texture_indexed_list = e.get_attribute("BuildingBlock",mode)
    dic = Hash.new

    texture_indexed_list.each{|tex|
      dic[tex.key] = tex[tex.value]
    }

    return dic
  end


end