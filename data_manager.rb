module SUExcel
  class DataManager
    attr_accessor :enable_send_to_excel

    # data as static/class variable
    # access with DataManager.data
    @@data
    def self.data
      return @@data
    end

    def initialize(execel_connector)
      #数据字典
      @@data = Hash.new
      @excelConnector = execel_connector
      @enable_send_to_excel = true
    end

    def clearData
      @@data.clear
    end

    def updateData(entity)
      zone=entity.get_attribute("BuildingBlock","zone")
      tower=entity.get_attribute("BuildingBlock","tower")
      program=entity.get_attribute("BuildingBlock","program")
      ftfh=entity.get_attribute("BuildingBlock","ftfh")
      area=entity.get_attribute("BuildingBlock","area")
      bd_height=entity.get_attribute("BuildingBlock","bd_height")
      bd_floors=entity.get_attribute("BuildingBlock","bd_floors")
      @@data[entity.guid] = Array[zone,program,tower,ftfh,area,bd_height,bd_floors]
      updateToExcel()  if @enable_send_to_excel
      SUExcel.update_data_note()
    end
	
    def updateToExcel()
      @excelConnector.updateExcel(@@data)
    end

    def colorize(group,colorKey)
      return
      colors=SUExcel.colors
      color=colors[colorKey]
      if color == nil
        p "colors=#{color}, colorKey=#{colorKey}"
        return
      end
      color=Sketchup::Color.new(color[0].to_i, color[1].to_i, color[2].to_i)
      group.entities.each {|ent|
          ent.material = color if colors.key?(colorKey) and ent.class == Sketchup::Face
      }
    end

    def readText()
      SUExcel.colors = Hash.new    #颜色字典
      path = File.dirname(__FILE__)  #当前脚本所在目录。文本文档应与脚本在同一目录
      aFile = File.open(path+"/colorPallet.txt","r").read   #逐行读取文本
      aFile.gsub!(/\r\n?/, "\n")
      aFile.each_line do |line|
        info = line.split(':')
        id = info[0]
        nums = info[1].split(',')
        SUExcel.colors[id] = nums
      end
    end

    def onChangeEntity(entity)                   #任意组发生改变时调用
      updateData(entity)
    end

    def onDelete(entity)                          #删除键
      @@data.delete(entity.guid)
      @excelConnector.updateExcel(@@data)
    end

    def onElementAdded(entities, entity)       #当添加一个Entities时调用
      updateData(entity)
    end

  end
end
