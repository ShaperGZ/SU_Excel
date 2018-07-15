require 'sketchup.rb'
require 'socket'
require 'win32ole'
require 'pathname'

require File.expand_path('../excel_manager', __FILE__)
require File.expand_path('../arch_util',__FILE__)
require File.expand_path('../arch_util_apdx_excel',__FILE__)
require File.expand_path('../archi',__FILE__)
require File.expand_path('../building_block',__FILE__)

# 自动化行为
# 自动规整层高： BH_FaceConstrain
# 切出楼层算面积：BH_CalArea
# 可视化（方案颜色，立面效果）：BH_Visualize
require File.expand_path('../bh_face_constrain',__FILE__)
require File.expand_path('../bh_cal_area',__FILE__)
require File.expand_path('../bh_visualize',__FILE__)
require File.expand_path('../bh_parapet',__FILE__)
require File.expand_path('../bh_excel_conduit',__FILE__)
require File.expand_path('../bh_base_area',__FILE__)

$enableOnEntityAdded=true
$firstime=true
$note = nil

#UI
module Sketchup::Excel
  toolbar1 = UI::Toolbar.new "SU_Excel"

  cmd1 = UI::Command.new("Excel"){SUExcel.connect_to_excel()}
  cmd1.small_icon = "Images/icon1.jpg"
  cmd1.large_icon = "Images/icon1.jpg"
  cmd1.tooltip = "connect excel"
  cmd1.status_bar_text = "开启传输Excel功能"
  cmd1.menu_text = "excel"

  cmd2 = UI::Command.new("SetBuilding"){SUExcel.set_building()}
  cmd2.small_icon = "Images/icon2.jpg"
  cmd2.large_icon = "Images/icon2.jpg"
  cmd2.tooltip = "excel"
  cmd2.status_bar_text = "Set building"
  cmd1.menu_text = "set building"


  toolbar1 = toolbar1.add_item cmd1
  toolbar1 = toolbar1.add_item cmd2
  toolbar1.show
end

module SUExcel
  #本项目不再使用$号的全局变量
  #这些事本项目的全局变量，已SUExcel.dataManager读写

  @@excel_manager=nil
  @@data=nil
  @@excel=nil
  @@is_first_time_connect=true
  @@note=nil
  
  @@last_user_input=["zone1","t1","retail","3"]
  def self.data_manager
    @@excel_manager
  end
  def self.data
    return @@excel_manager.class.data if @@excel_manager.class.data!=nil
    return nil
  end
  def self.data_manger=(val)
    @@excel_manager=val
  end
  def self.excel
    @@excel
  end
  def self.excel=(val)
    @@excel=val
  end


  #与excel链接并更新全部数据
  # 如果已经连接，更新全部数据
  # 该方法用于UI，被用户调用
  def self.connect_to_excel
    self.clear_script_generated_objs()
    self.batch_add_observers()
  end

  def self.read_scheme_types(profile_path=nil)
    types=[]
    if profile_path ==nil
      #当前脚本所在目录。文本文档应与脚本在同一目录
      basepath = File.dirname(__FILE__)
      profile_path = basepath + "/colorPallet.txt"
    end
    aFile = File.open(profile_path,"r").read   #逐行读取文本
    aFile.gsub!(/\r\n?/, "\n")
    aFile.each_line do |line|
      info = line.split(':')
      id = info[0]
      types<<id
    end
    return types
  end

  # 把选定物体加入到数据管理
  # 用户选择组，通过UI选择建筑类型后，自动起名字并更新第一次数据
  # 预设名字为="zone1_t1_#{building_type}_3"
  # 缺点是用户需要之后自己修改名字更正zone, t#,和层高ftfh
  # 该方法用于UI，被用户调用
  def self.set_building

    @@excel_manager=SUExcel::ExcelManager.get_singleton()

    prompts = ["分区","栋","业态","层高"]
    defaults = @@last_user_input
    programs = ""
    read_types=self.read_scheme_types
    read_types.each{|t|
		programs +="|" if programs!=""
		programs+=t.to_s
    }

    # 设定菜单内容
    zones=""
    towers=""
    ftfh=""
    list = [zones,towers,programs,ftfh]

    # 看看选了什么
    sel = Sketchup.active_model.selection
    selected_groups=[]
    sel.each{|e| selected_groups<<e if e.class == Sketchup::Group}

    if  selected_groups.size==0
      UI.messagebox("未选择任何组！")
      return
    end

    if selected_groups[0].get_attribute("BuildingBlock","bd_ftfh")!=nil
      default = []
      indices = ["pln_zone","pln_tower","pln_program","bd_ftfh"]
      indices.each {|i|
        default<<selected_groups[0].get_attribute("BuildingBlock",i).to_s
      }
    else
      default = @@last_user_input
    end

    input = UI.inputbox(prompts, defaults, list, "Set Building")
    return if input == nil or input == false

    @@last_user_input = input

    p "selected count =#{selected_groups.size}"
    # two actions: 01 assign color, 02 assign name
    selected_groups.each{|group|
      BuildingBlock.create_or_invalidate(group,input[0],input[1],input[2],input[3].to_f)
    }
  end



  def self.batch_add_observers()
    @@excel_manager=SUExcel::ExcelManager.get_singleton()
    @@excel_manager.clearData
    @@excel_manager.enable_send_to_excel =false
    BH_BaseArea.enable_dynamic_update_base_area=false

    # 清空非法数据
    # 通常打开新文件时，原来的数据会留在记录里成为非法数据
    # AreaUpdater.remove_deleted()
    BuildingBlock.remove_deleted()

    # 要先把现有的entities提取出来，如果直接拿Sketchup.active_model.entities来遍历
    # 会把过程中新建的entity也遍历
    entites = Sketchup.active_model.entities
    ents=[]
    entites.each {|e| ents<<e}
    ents.each {|e|
      if e.typename == "Group" and e.get_attribute("BuildingBlock","bd_ftfh") != nil
        zone=e.get_attribute("BuildingBlock","pln_zone")
        tower=e.get_attribute("BuildingBlock","pln_tower")
        program=e.get_attribute("BuildingBlock","pln_program")
        ftfh=e.get_attribute("BuildingBlock","bd_ftfh")
        BuildingBlock.create_or_invalidate(e,zone,tower,program,ftfh)
        #self.data_manager.setUpdate(e)
      end
    }
    @@excel_manager.enable_send_to_excel =true
    BH_BaseArea.enable_dynamic_update_base_area=true
    @@excel_manager.updateToExcel()
    BH_BaseArea.update_base_area
  end



  def self.clear_script_generated_objs()
    generated_names=[
        "SCRIPTGENERATEDOBJECTS",
        "SCRIPTGENERATEDOBJECTS_flrs",
        "SCRIPTGENERATEDOBJECTS_parapet"
    ]
    counter=0
    tbd=[]
    Sketchup.active_model.entities.each{|entity|
      if entity.typename == "Group" and generated_names.include?(entity.name)
        tbd<<entity
      end
    }
    tbd.each{|e| e.erase!}
  end

  def self.profile_path()
    basepath = File.dirname(__FILE__)
    profile_path = basepath + "/colorPallet.txt"
    return profile_path
  end

end












