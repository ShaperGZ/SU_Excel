class DataManager
  $enableSendExcel=true
  def initialize(execel_connector)
    $data = Hash.new     #数据字典
    @excelConnector= execel_connector
  end

  def clearData
    $data.clear
  end

  def updateData(entity)
    analyzeEntity(entity)
    $data[entity.guid] = Array[$part[0],$part[1],$part[2],$part[3],entity.get_attribute("BuildingBlock","area")]
    @excelConnector.updateExcel($data) if $enableSendExcel
    update_data_note()
  end

  def analyzeEntity(entity)
    $part = entity.name.split('_')
    colorKey = $part[2]
    entity.entities.each {|ent|
      if  ent.typename == "Face"
        if $color.key?(colorKey)
          ent.material = Sketchup::Color.new($color[colorKey][0].to_i, $color[colorKey][1].to_i, $color[colorKey][2].to_i)
        end
      end
    }
  end

  def readText()
    $color = Hash.new    #颜色字典
    path = File.dirname(__FILE__)  #当前脚本所在目录。文本文档应与脚本在同一目录
    aFile = File.open(path+"/colorPallet.txt","r").read   #逐行读取文本
    aFile.gsub!(/\r\n?/, "\n")
    aFile.each_line do |line|
      info = line.split(':')
      id = info[0]
      nums = info[1].split(',')
      $color[id] = nums
    end
  end

  def onChangeEntity(entity)                   #任意组发生改变时调用
    updateData(entity)
  end

  def onDelete(entity)                          #删除键
    $data.delete(entity.guid)
    @excelConnector.updateExcel($data)
  end

  def onElementAdded(entities, entity)       #当添加一个Entities时调用
    updateData(entity)
  end

  def update_data_note()
    return if $note==nil
    #把$data各行变成一个单一string 变量，赋予 $note.text
    $note.text = ""
    $data.keys.each{|key|
      area = $data[key][4]
      if area != nil
        a = sprintf("%.2f",$data[key][4]).to_s
      else
        a = ""
      end
      $note.text += key[0,4] + "," + $data[key][0].to_s + "," + $data[key][1].to_s + "," + $data[key][2].to_s + "," + $data[key][3].to_s + ", area:" + a + "\n"
    }
  end

end


