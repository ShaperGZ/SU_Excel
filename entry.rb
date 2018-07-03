require 'sketchup.rb'
require 'socket'
require 'win32ole'
require 'pathname'

require File.expand_path('../data_manager',__FILE__)
require File.expand_path('../excel_connector',__FILE__)
require File.expand_path('../arch_util',__FILE__)
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

  @@data_manager=nil
  @@data=nil
  @@colors=nil
  @@excel=nil
  @@is_first_time_connect=true
  @@note=nil
  
  @@last_user_input=["zone1","retail","t1","3"]
  def self.data_manager
    @@data_manager
  end
  def self.data
    return @@data_manager.class.data if @@data_manager.class.data!=nil
    return nil
  end
  def self.data_manger=(val)
    @@data_manager=val
  end
  def self.excel
    @@excel
  end
  def self.excel=(val)
    @@excel=val
  end
  def self.colors
    @@colors
  end

  #与excel链接并更新全部数据
  # 如果已经连接，更新全部数据
  # 该方法用于UI，被用户调用
  def self.connect_to_excel
    self._first_time_connect() if @@is_first_time_connect
    self.clear_script_generated_objs()
    self.batch_add_observers()
    self.update_data_note if @@data_manager!=nil
  end

  # 把选定物体加入到数据管理
  # 用户选择组，通过UI选择建筑类型后，自动起名字并更新第一次数据
  # 预设名字为="zone1_t1_#{building_type}_3"
  # 缺点是用户需要之后自己修改名字更正zone, t#,和层高ftfh
  # 该方法用于UI，被用户调用
  def self.set_building

    if @@data_manager==nil
      self._first_time_connect
    end

    prompts = ["分区","业态","栋","层高"]
    defaults = @@last_user_input
    types = ""
    self.read_color_profile if @@colors == nil
    @@colors.keys.each{|key| 
		types +="|" if types!=""
		types+=key.to_s
    }

    # 设定菜单内容
    zones=""
    towers=""
    ftfh=""
      list = [zones,types,towers,ftfh]

    defaults=@@last_user_input

    input = UI.inputbox(prompts, defaults, list, "Set Building")
	  return if input == nil or input == false
	
	  @@last_user_input = input
    sel = Sketchup.active_model.selection
    selected_groups=[]
    sel.each{|e| selected_groups<<e if e.class == Sketchup::Group}

    group_count = selected_groups.size
    if  group_count == 0 || sel.empty?
      UI.messagebox("未选择任何组！")
      return
    end


    p "selected count =#{selected_groups.size}"
    # two actions: 01 assign color, 02 assign name
    selected_groups.each{|group|
      # 01 assign color
      color=@@colors[input[1]]
      color=Sketchup::Color.new(color[0].to_i, color[1].to_i, color[2].to_i)
      group.entities.each {|ent|
        ent.material = color if color!=nil and ent.class == Sketchup::Face
      }
      # 02 assign name
      building_type=input[1]
      name="#{input[0]}_#{input[1]}_#{input[2]}_#{input[3]}"
      p "name=#{name}"
      group.name=name
      #group.set_attribute("BuildingBlock","ftfh",input[3].to_f)
      BuildingBlock.create_or_invalidate(group,input[0],input[1],input[2],input[3].to_f)
	    #AreaUpdater.create_or_invalidate(group)
      #AreaUpdater.new(group)
      @@data_manager.updateData(group)
    }
  end

  def self._first_time_connect
    self.read_color_profile()
    @@excel = SUExcel::ExcelConnector.new
    @@data_manager=SUExcel::DataManager.new(SUExcel.excel)
    @@excel.connectExcel()
    @@is_first_time_connect = false
  end

  def self.update_data_note()
    return if @@note==nil
    #把@@data各行变成一个单一string 变量，赋予 $note.text
    text = ""
    data=@@data_manager.data
    data.keys.each{|key|
      area = data[key][4]
      if area != nil
        a = sprintf("%.2f",data[key][4]).to_s
      else
        a = ""
      end
      text += key[0,4]
      4.times{|i| text += ","+data[key][0].to_s}
      text +=", area:" + a + "\n"
    }
    @@note=Sketchup.active_model.add_note("",0.05,0.05) if @@note==nil or @@note.deleted?
    @@note.text=text
  end

  def self.read_color_profile()
    #颜色字典
    @@colors = Hash.new
    path = File.dirname(__FILE__)  #当前脚本所在目录。文本文档应与脚本在同一目录
    aFile = File.open(path+"/colorPallet.txt","r").read   #逐行读取文本
    aFile.gsub!(/\r\n?/, "\n")
    aFile.each_line do |line|
      info = line.split(':')
      id = info[0]
      nums = info[1].split(',')
      @@colors[id] = nums
    end
  end

  def self.satisfy_name(name)
    if (name.include? "_") and (name.split('_').size > 3)
      return true
    else
      return false
    end
  end

  def self.batch_add_observers()
    @@data_manager.clearData if @@data_manager != nil
    #@@excel.clearExcel()
    @@data_manager.enable_send_to_excel =false
    entites = Sketchup.active_model.entities

    #清空非法数据
    #通常打开新文件时，原来的数据会留在记录里成为非法数据
    #AreaUpdater.remove_deleted()
    BuildingBlock.remove_deleted()


    #要先把现有的entities提取出来，如果直接拿Sketchup.active_model.entities来遍历
    # 会把过程中新建的entity也遍历
    ents=[]
    entites.each {|e| ents<<e}
    ents.each {|e|
      if e.typename == "Group" and self.satisfy_name(e.name)
        BuildingBlock.create_or_invalidate(e)
        self.data_manager.updateData(e)
      end
    }
    @@data_manager.enable_send_to_excel =true
    @@data_manager.updateToExcel()
  end

  def self.clear_script_generated_objs()

    counter=0
    tbd=[]
    Sketchup.active_model.entities.each{|entity|
      if entity.typename == "Group" and entity.name == "SCRIPTGENERATEDOBJECTS"
        tbd<<entity
      end
    }
    #p "clearing all script generated objects count=#{tbd.size}"
    tbd.each{|e| e.erase!}
  end

end












