
#module VisualModes
#  @@concept=11
#  @@textured=22
#  @@model=33
#end

class BH_Visualize < Arch::BlockUpdateBehaviour
  # 静态属性/方法
  # 方案颜色从这里提取，在打开sketchup时更新一次，
  @@scheme_colors=Hash.new

  # 当前的材质模式
  #@@mode=VisualModes.textured

  # entry读完颜色后把颜色dictionary set给这个类
  def self.set_scheme_colors(dict)
    @@scheme_colors=dict
  end
  # 这几个setter各有一个按钮
  # 全局设为方案模式
  def self.set_mode_concept()
    self.mode=VisualModes.concept
  end
  #全局设为贴图模式
  def self.set_mode_textured()
    self.mode=VisualModes.textured
  end

  #-------------------------------------------------

  # @material 以面(Face)为key, 材质为value
  @textures=Hash.new
  #self.mode=VisualModes.textured
  def initialize(gp,host)
    super(gp,host)
  end


  # 监听行为
  def onOpen(e)
    # 为当前编辑的组切换到“贴图”模式 ！
  end

  def onClose(e)
    # 因为打开组时，当前编辑的组强被迫变成贴图模式
    # 设计师会在编辑过程中赋予材质
    # 所以关闭组时
    # 1.清空@textures
    # 2.把每一个面所对应的材质hash到 @textures
    # 3.根据BH_Visualize.mode为每个面赋予材质，譬如在编辑前是方案模式的就在记录完才之后赋回方案颜色。
  end



  # 设为方案模式
  def _set_mode_concept()
    #根据其类型赋予方案颜色
  end
  #设为贴图模式
  def _set_mode_textured()
    # 从@textures里为每个面分配材质，如果无记录的面则给default材质
  end


end