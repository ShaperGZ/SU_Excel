require 'sketchup.rb'
require 'socket'
require 'win32ole'
require 'pathname'

require File.expand_path('../data_manager',__FILE__)
require File.expand_path('../excel_connector',__FILE__)
require File.expand_path('../CalArea2',__FILE__)

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
  @@data_manager
  @@data
  @@colors
  @@excel
  @@is_first_time_connect
  @@note

  #与excel链接并更新全部数据
  # 如果已经连接，更新全部数据
  # 该方法用于UI，被用户调用
  def self.connect_to_excel
    self._first_time_connect() if self.is_first_time_connect
    self._clear_deleted()
    self._batch_data()
    self.data_manager.update_data_note()
  end

  # 把选定物体加入到数据管理
  # 用户选择组，通过UI选择建筑类型后，自动起名字并更新第一次数据
  # 预设名字为="zone1_t1_#{building_type}_3"
  # 缺点是用户需要之后自己修改名字更正zone, t#,和层高ftfh
  # 该方法用于UI，被用户调用
  def self.set_building
    prompts = ["color"]
    defaults = ["retail"]
    str = ""
    self.colors.keys.each{|key|
      if key != self.colors.keys[self.colors.keys.size-1]
        str += key.to_s+"|"
      else
        str += key.to_s
      end
    }
    list = [str]
    input = UI.inputbox(prompts, defaults, list, "Information")

    selections = Sketchup.active_model.selection
    GroupCount = 0

    selections.each{|selection|
      if selection.typename == "Group"
        GroupCount += 1
        colorKey = input[0]
        selection.entities.each {|ent|
          if  ent.typename == "Face"
            if self.colors.key?(colorKey)
              ent.material = Sketchup::Color.new(self.colors[colorKey][0].to_i, self.colors[colorKey][1].to_i, self.colors[colorKey][2].to_i)
              building_type=colorKey
              name="zone1_t1_#{building_type}_3"
              entity.name=name
              entity.set_attribute("BuildingBlock","ftfh",3)
            end
          end
        }
      end
    }

    if  @GroupCount == 0 || selections.empty?
      UI.messagebox("未选择任何组！")
    end
  end

  def self._first_time_connect
    Sketchup.active_model.entities.add_observer(NewEntityObserver.new)
    #Sketchup.add_observer(MyAppObserver.new)
    self.excel.connectExcel()
    self.is_first_time_connect = false

  end

  def self._read_color_profile()
    self.colors = Hash.new    #颜色字典
    path = File.dirname(__FILE__)  #当前脚本所在目录。文本文档应与脚本在同一目录
    aFile = File.open(path+"/colorPallet.txt","r").read   #逐行读取文本
    aFile.gsub!(/\r\n?/, "\n")
    aFile.each_line do |line|
      info = line.split(':')
      id = info[0]
      nums = info[1].split(',')
      self.colors[id] = nums
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
    @@data.clear if @@data != nil
    @@excel.clearExcel()
    isSendExcel = false
    entites = Sketchup.active_model.entities

    #要先把现有的entities提取出来，如果直接拿Sketchup.active_model.entities来遍历
    # 会把过程中新建的entity也遍历
    ents=[]
    entites.each {|e| ents<<e}
    ents.each {|e|
      if e.typename == "Group" and self.satisfy_name(e.name)
        AreaUpdater.new(e)
        self.data_manager.updateData(e)


      end
    }

  end

  def self.clear_deleted()
    Sketchup.active_model.entities.each{|entity|
      if entity.typename == "Group" and entity.name == "SCRIPTGENERATEDOBJECTS"
         puts "删除该组：#{entity.name}"
      end
    }
  end

end


@@excel=ExcelConnector.new
@@data_manager=DataManager.new(@@excel)
@@data_manager.readText()#读取文本文档









