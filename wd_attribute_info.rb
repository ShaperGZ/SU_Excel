module SUExcel
  def self.open_attribute_info()
    dialog=WD_AttributeInfo.create_or_get(WD_AttributeInfo.name)
    dialog.open
  end
end

class WD_AttributeInfo < SUExcel::WebDialogWrapper
  def self.create_or_get(name)
    dialog=SUExcel::WebDialogWrapper.get(WD_AttributeInfo.name)
    if dialog == nil
      name=WD_AttributeInfo.name
      dialog=WD_AttributeInfo.new(name)
    end
    return dialog
  end

  def initialize(name)
    super(name)
  end

  def open()
    return if @visible
    @dlg = UI::WebDialog.new("AttributeInfo", true, "Information", 739, 641, 150, 150, true)
    file = File.join(__dir__,"/dialogs/attributeInfo.html")
    @dlg.set_file(file)
    @dlg.set_background_color("999999")
    @dlg.set_on_close{close()}
    @dlg.show

    @visible=true
  end

  def close()
    @dlg == nil
    @visible = false
  end

  def onSelectionBulkChange(selection)
    if selection.size != 1
      close
      return
    end
    entity = selection[0]

    if entity.typename != "Group"
      _send_to_html("当前选择的不是一个组")
      return
    end

    if  entity.has_attributes?("BuildingBlock")
      dict = entity.attribute_dictionary("BuildingBlock")
      _send_to_html(dict)
    else
      _send_to_html("该组不包含BuildingBlock")
    end

  end

  #-----------------自用方法------------------------
  #发送消息到html
  def _send_to_html(info)
    @dlg.execute_script("document.getElementById('txtContent').value =''")
    if info.class == Sketchup::AttributeDictionary
      info.keys.each{|key|
        message = key.to_s+" : "+info[key].to_s
        @dlg.execute_script("write('#{message}')")
      }
    else
      @dlg.execute_script("document.getElementById('txtContent').value ='#{info}'")
    end

  end

end