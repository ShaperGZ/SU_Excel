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
      block_info=analyzeEntity(entity)
      @@data[entity.guid] = Array[block_info[0],block_info[1],block_info[2],block_info[3],entity.get_attribute("BuildingBlock","area")]
      #p block_info
      #p " enable to excel ="+@enable_send_to_excel.to_s
      updateToExcel()  if @enable_send_to_excel
      SUExcel.update_data_note()
    end
	
    def updateToExcel()
      #p "updating data to excel, data:"
      #p @@data
      @excelConnector.updateExcel(@@data)
    end

    def analyzeEntity(entity)
      block_info = entity.name.split('_')
	    bounds=entity.bounds
	    #block_info<<bounds.min.z
      colorKey = block_info[3]
      colorize(entity, colorKey)
      return block_info
    end

    def colorize(group,colorKey)
      #colorize
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
