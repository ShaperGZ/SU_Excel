require 'sketchup.rb'
#module VisualModes
#  @@concept=11
#  @@textured=22
#  @@model=33
#end

module DisplayModes
  SCHEME=111
  TEXTURED=222
end

class BH_Visualize < Arch::BlockUpdateBehaviour
  # 静态属性/方法
  # 方案颜色从这里提取，在打开sketchup时更新一次，

  # 当前的材质模式
  @@mode= DisplayModes::SCHEME

  # 这个是以program为key，material为值的字典
  # TODO：把配置文件位置变为可浏览选择
  @@scheme_colors=nil
  @@scheme_colors_profile_path=nil
  def self.scheme_colors
    @@scheme_colors=BH_Visualize.get_color_materials
    #p @@scheme_colors
    return @@scheme_colors
  end


  # 阅读颜色配置文件
  # 配置文件的位置实际由SUExcel.profile_path()提供
  def self.get_color_materials(profile_path=nil)
    #p "reading color profile"
    profile = Hash.new    #颜色字典
    if profile_path ==nil
      profile_path = SUExcel.get_file_path
    end
    aFile = File.open(profile_path,"r").read   #逐行读取文本
    aFile.gsub!(/\r\n?/, "\n")
    aFile.each_line do |line|
      info = line.split(':')
      id = info[0]
      nums = info[1].split(',')
      profile[id] = nums
    end
    colors=_create_scheme_color_materials(profile)
    return colors
  end

  def self._create_scheme_color_materials(dict)
    #p "创建颜色"
    mats=Hash.new
    model = Sketchup.active_model
    materials = model.materials
    dict.keys.each{|key|
      color = dict[key]
      if !mats.key?(key)
        m = ArchUtil.getMaterial(key)
        if m==nil
          m = materials.add(key)
          m.color = Sketchup::Color.new(color[0].to_i, color[1].to_i, color[2].to_i)
        end
        mats[key]= m

      end
    }
    return mats
  end



  # 全局设为方案模式
  def self.set_modes_concept()
    @@mode = DisplayModes::SCHEME
    self.set_mode(@@mode)
  end

  #全局设为贴图模式
  def self.set_modes_texture()
    @@mode = DisplayModes::TEXTURED
    self.set_mode(@@mode)
  end

  def self.set_mode(mode)
    @@mode = mode
    ents=BuildingBlock.created_objects
    return if ents == nil
    # TODO：make better accessor for updators
    ents.values.each{|e|
      visualizer=e.get_updator_by_type(self)
      visualizer.set_mode(@@mode)
    }
  end

  #-------------------------------------------------

  attr_accessor :clones
  def initialize(gp,host)
    super(gp,host)
    @attr_key="ttr_face_textures"
    @mode = DisplayModes::SCHEME
    #TODO: add clones for different visual representations
    # save textures on creation
    _load_textures
    _save_textures
    #@last_mode
  end

  # 监听行为
  @is_opened=false
  def onOpen(e)
    @is_opened =true
    set_mode(DisplayModes::TEXTURED)
  end

  def onClose(e)
    #p 'visualize.onClose'
    if @is_opened
      #p 'visualize.onClose->_save_texture'
      _save_textures
    end
    @is_opened=false

    #p 'visualize.onClose->set_mode'
    set_mode(@@mode)
    #p 'visualize.onClose->end'
  end

  def onChangeEntity(e, invalidated)
    super(e, invalidated)
  end

  def set_mode(mode)
    case mode
    when DisplayModes::SCHEME
      _set_mode_concept
    when DisplayModes::TEXTURED
      _set_mode_texture
    end
    #@last_mode = @mode
  end

  # 设为方案模式
  def _set_mode_concept()
    program=@gp.get_attribute("BuildingBlock","pln_program")
    mat = BH_Visualize.scheme_colors[program]
    mat = 'white' if mat == nil

    for i in 0..@gp.entities.size-1
      e=@gp.entities[i]
      if e.class == Sketchup::Face
        e.material= mat
      end
    end

    @mode = DisplayModes::SCHEME
  end

  #设为贴图模式
  def _set_mode_texture()
    _load_textures
    @mode = DisplayModes::TEXTURED
  end


  def _save_textures()
    #p '!! saved texture'
    key=@attr_key
    dict=Hash.new
    @gp.entities.each_with_index{|f,i|
    if f.class == Sketchup::Face
      if f.material == nil
        mat= "white"
      else
        mat=f.material.name
      end

      if !dict.include? mat
        dict[mat]=[i]
      else
        dict[mat]<<i
      end
    end
    }
    @gp.set_attribute("BuildingBlock",key,dict.to_a)
    #p @gp.get_attribute("BuildingBlock",key)
  end

  def _load_textures()
    has_texture=true
    has_texture=false if !@gp.valid?
    key=@attr_key
    dict=@gp.get_attribute("BuildingBlock",key)
    #p "dict=#{dict}"
    has_texture=false if dict==nil

    if has_texture
      # 从材质库里提取材质
      dict.each{|i|
        key = i[0]
        mat=ArchUtil.getMaterial(key)
        mat = "white" if mat ==nil
        faceIDs= i[1]
        faceIDs.each{|i|
          f=@gp.entities[i]
          f.material=mat if f!=nil
        }
      }
    else
      @gp.entities.each{|f|
        if f.class == Sketchup::Face
          f.material="white"
        end
      }
    end

  end



end