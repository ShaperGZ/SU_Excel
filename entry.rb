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
require File.expand_path('../bh_dimension',__FILE__)
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
  cmd1.status_bar_text = "First Connect"
  cmd1.menu_text = "excel"

  cmd2 = UI::Command.new("SetBuilding"){SUExcel.set_building()}
  cmd2.small_icon = "Images/icon2.jpg"
  cmd2.large_icon = "Images/icon2.jpg"
  cmd2.tooltip = "excel"
  cmd2.status_bar_text = "Set building"
  cmd1.menu_text = "set building"

  cmd3 = UI::Command.new("SetConceptMode"){SUExcel.set_conceptMode()}
  cmd3.small_icon = "Images/ConceptMode.jpg"
  cmd3.large_icon = "Images/ConceptMode.jpg"
  cmd3.tooltip = "conceptMode"
  cmd3.status_bar_text = "Set Concept"
  cmd3.menu_text = "set ConceptMode"

  cmd4 = UI::Command.new("SetTexture"){SUExcel.set_textureMode()}
  cmd4.small_icon = "Images/TextureMode.jpg"
  cmd4.large_icon = "Images/TextureMode.jpg"
  cmd4.tooltip = "textureMode"
  cmd4.status_bar_text = "Set texture"
  cmd4.menu_text = "set texture"

  cmd5 = UI::Command.new("ShowOrHide"){SUExcel.showOrHide()}
  cmd5.small_icon = "Images/ComponentMode.jpg"
  cmd5.large_icon = "Images/ComponentMode.jpg"
  cmd5.tooltip = "showOrHide"
  cmd5.status_bar_text = "show Or Hide"
  cmd5.menu_text = "showOrHide"

  cmd6 = UI::Command.new("WEB"){SUExcel.open_web()}
  cmd6.small_icon = "Images/web.png"
  cmd6.large_icon = "Images/web.png"
  cmd6.tooltip = "web"
  cmd6.status_bar_text = "Web Dialog"
  cmd6.menu_text = "web"

  toolbar1 = toolbar1.add_item cmd1
  toolbar1 = toolbar1.add_item cmd2
  toolbar1 = toolbar1.add_item cmd3
  toolbar1 = toolbar1.add_item cmd4
  toolbar1 = toolbar1.add_item cmd5
  toolbar1 = toolbar1.add_item cmd6
  toolbar1.show
end

module SUExcel
  #本项目不再使用$号的全局变量
  #这些是本项目的全局变量，已SUExcel.dataManager读写

  @@data_manager=nil
  @@data=nil
  @@colors=nil
  @@excel=nil
  @@is_first_time_connect=true
  @@note=nil
  @@idex = 0
  @@last_user_input=["zone1","retail","t1","3"]
  @@dlg = nil
  @@Sele = Sketchup.active_model.selection

  def self.selection
    return @@Sele
  end
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
    @@excel = SUExcel::ExcelConnector.new if @@excel == nil
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

    #确保每次新打开文件时，sketchup内的方案颜色不会清空
    BH_Visualize.set_scheme_colors(@@colors,true) if Sketchup.active_model.materials.size == $Material_size

    prompts = ["分区","业态","栋","层高"]
    defaults = @@last_user_input
    program = ""

    p "@@colors=#{@@colors}" if @@colors !=nil

    @@colors.keys.each{|key| 
		program +="|" if program!=""
		program+=key.to_s
    }
    # 设定菜单内容
    zones=""
    towers=""
    ftfh=""
    list = [zones,program,towers,ftfh]

    defaults=@@last_user_input

    input = UI.inputbox(prompts, defaults, list, "Set Building")
	  return if input == nil or input == false
	
	  @@last_user_input = input
    sel = Sketchup.active_model.selection
    selected_groups=[]
    sel.each{|e| selected_groups<<e if e.class == Sketchup::Group or e.class == Sketchup::ComponentInstance}

    group_count = selected_groups.size
    if  group_count == 0 || sel.empty?
      UI.messagebox("未选择任何组！")
      return
    end

    p "selected count =#{selected_groups.size}"
    selected_groups.each{|group|
      building_type=input[1]
      p "name=#{name}"
      zone=input[0]
      program=input[1]
      tower=input[2]
      ftfh=input[3].to_f
      BuildingBlock.create_or_invalidate(group,zone,tower,program,ftfh)
      @@data_manager.updateData(group)
    }
  end

  def self._first_time_connect
    #读取颜色
    if @@colors == nil
      self.read_color_profile
    end
    #把颜色dictionary set给 BH_Visualize类
    BH_Visualize.set_scheme_colors(@@colors)

    @@Sele.add_observer(MySelectionObserver.new)

    Sketchup.add_observer(MyAppObserver.new)

    @@excel = SUExcel::ExcelConnector.new
    @@data_manager= SUExcel::DataManager.new(SUExcel.excel)
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

  def self.batch_add_observers()
    @@data_manager.clearData if @@data_manager != nil

    @@data_manager.enable_send_to_excel =false
    entites = Sketchup.active_model.entities

    #递归找组
    entites.each{|e| SUExcel.recursive_find_group(e)}
    p "组总数：#{@group.size}"
    entites = @group

    #清空非法数据
    #通常打开新文件时，原来的数据会留在记录里成为非法数据
    BuildingBlock.remove_deleted()

    #要先把现有的entities提取出来，如果直接拿Sketchup.active_model.entities来遍历
    # 会把过程中新建的entity也遍历
    ents=[]
    entites.each {|e| ents<<e}

    BuildingBlock.enable_dynamic_update_base_area=false
    ents.each {|e|
      try_get=e.get_attribute("BuildingBlock","ftfh")
      if try_get!=nil
        BuildingBlock.create_or_invalidate(e)
        self.data_manager.updateData(e)
      end
    }
    BuildingBlock.enable_dynamic_update_base_area=true
    BuildingBlock.update_base_area

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

  def self.set_conceptMode()
    BH_Visualize.set_modes_concept
  end

  def self.set_textureMode()
    BH_Visualize.set_modes_texture
  end

  #显示或隐藏名为"SCRIPTGENERATEDOBJECTS"的组
  def self.showOrHide()
    Sketchup.active_model.entities.each{|entity|
      if entity.typename == "Group" and entity.name == "SCRIPTGENERATEDOBJECTS"
        if(@@idex == 0)
          entity.hidden = true
          BH_CalArea.set_hide(true)
        else
          entity.hidden = false
          BH_CalArea.set_hide(false)
        end
      end
    }

    if(@@idex == 0)
      @@idex = 1
      return
    else
      @@idex = 0
    end
  end

  @is_open_web = false
  def self.open_web()
    if @is_open_web
      return
    end

    if @@data_manager==nil
      self._first_time_connect
    end

    @is_open_web = true
    #确保每次新打开文件时，sketchup内的方案颜色不会清空
    BH_Visualize.set_scheme_colors(@@colors,true) if Sketchup.active_model.materials.size == $Material_size

    @@dlg = UI::WebDialog.new("更改组信息", true, "ShowSketchupDotCom", 739, 641, 150, 150, true)
    file = File.join(__dir__,"/dialogs/test.html")
    @@dlg.set_file(file)
    @@dlg.show
    @@dlg.set_background_color("999999")
    @@dlg.set_on_close{self.clear_dlg }
    selections = Sketchup.active_model.selection
    @@dlg.execute_script("creat()")
   # @@dlg.execute_script("document.getElementById('concept').options.add(new Option('retail', 'retail'))")
    #@@dlg.execute_script("document.getElementById('concept').innerHTML='<option value='volvo'>Volvo</option>'")
    @@dlg.add_action_callback("SetInfo") {|dialog, params|
      info = params.split('_')
      @count = 0
      selections.each{|selection|
        if selection.typename == "Group"
          @count += 1
          BuildingBlock.create_or_invalidate(selection,info[0],info[2],info[1],info[3].to_f)
          @@data_manager.updateData(selection)
        end

        #设置完即更新面积
        self.update_area(selection)

      }
      if  @count == 0 || selections.empty?
        UI.messagebox("未选择任何组！")
      end
    }
  end

  def self.clear_dlg()
    @@dlg == nil
    @is_open_web = false
  end

  #发送消息到html
  def self.send_info_to_html(zone,program,tower,ftfh,area)
    return if @@dlg == nil
    @@dlg.execute_script("document.getElementById('id1').value='#{zone}'")
   # @@dlg.execute_script("document.getElementById('id2').value='#{program}'")
    @@dlg.execute_script("document.getElementById('id3').value='#{tower}'")
    @@dlg.execute_script("document.getElementById('id4').value='#{ftfh}'")
    if area != nil
      @@dlg.execute_script("document.getElementById('id5').value='#{sprintf("%.2f",area)}'")
    else
      @@dlg.execute_script("document.getElementById('id5').value='#{nil}'")
    end
  end

  #递归找组
  @group = []
  def self.recursive_find_group(gp)
    return if gp.typename != "Group"
    count = 0
    gp.entities.each{|ent|
      if ent.typename == "Group"
        if is_single_group(ent)
          @group << ent
        else
          recursive_find_group(ent)
        end
      else
        count += 1
      end
    }
    if(count == gp.entities.size)
      @group << gp
    end
  end

  def self.is_single_group(ent)
    ent.entities.each{|e|
      if e.typename == "Group"
        return false
      end
      return true
    }
  end

  def self.update_area(entity)
    return if @@dlg == nil
    area = entity.get_attribute("BuildingBlock","area")
    if area != nil
      @@dlg.execute_script("document.getElementById('id5').value='#{sprintf("%.2f",area)}'")
    else
      @@dlg.execute_script("document.getElementById('id5').value='#{nil}'")
    end
  end

end

#选中事件观察者  鼠标选中单个组时触发
class MySelectionObserver < Sketchup::SelectionObserver
  def onSelectionBulkChange(selection)
    if SUExcel.selection.size != 1
      SUExcel.send_info_to_html(nil,nil,nil,nil,nil)
      return
    end
    entity = SUExcel.selection[0]
    if entity.typename != "Group"
      SUExcel.send_info_to_html(nil,nil,nil,nil,nil)
      return
    end
    zone = entity.get_attribute("BuildingBlock","zone")
    program = entity.get_attribute("BuildingBlock","program")
    tower = entity.get_attribute("BuildingBlock","tower")
    ftfh =  entity.get_attribute("BuildingBlock","ftfh")
    area = entity.get_attribute("BuildingBlock","area")
    SUExcel.send_info_to_html(zone,program,tower,ftfh,area)
  end
end

#打开文件或新建场景
class MyAppObserver < Sketchup::AppObserver
  def onOpenModel(model)
    puts "打开文件"
    Sketchup.active_model.selection.add_observer(MySelectionObserver.new)
  end

  def onNewModel(model)
    puts "新建场景"
    Sketchup.active_model.selection.add_observer(MySelectionObserver.new)
  end
end

#初始的sketchup材质数量
$Material_size = Sketchup.active_model.materials.size













