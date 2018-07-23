module SUExcel

  def self.open_wd_general_info
    #如果没有就创建新的dialog
    dialog=WD_GeneralInfo.create_or_get(WD_GeneralInfo.name)
    dialog.open
  end

end

class WD_GeneralInfo < SUExcel::WebDialogWrapper

  def self.create_or_get(name)
    dialog=SUExcel::WebDialogWrapper.get(WD_GeneralInfo.name)
    # TODO: 确认dialog如何检查正确性
    if dialog == nil
      name=WD_GeneralInfo.name
      dialog=WD_GeneralInfo.new(name)
    end
    return dialog
  end

  def initialize(name)
    super(name)
  end

  # override WebDialog.open
  def open()
    return if @visible
    #@@excel_manager=SUExcel::ExcelManager.get_singleton()

    @dlg = UI::WebDialog.new("更改组信息", true, "ShowSketchupDotCom", 400, 500, 150, 150, true)
    file = File.join(__dir__,"/dialogs/test.html")
    @dlg.set_file(file)
    @dlg.set_background_color("ffffff")
    @dlg.set_on_close{close()}
    @dlg.show {
      concept = SUExcel.read_scheme_types
      concept.each{|c|
        @dlg.execute_script("document.getElementById('id2').options.add(new Option('#{c}','#{c}'))")
      }
    }
    @dlg.add_action_callback("confirm") {|dialog, params|onConfirm(params)}
    @dlg.add_action_callback("default") {|dialog, params|onFillDefault()}

    @visible=true
  end

  # override WebDialog.close
  def close()
    @dlg == nil
    @visible = false
  end

  # override WebDialog.onSelectionCleared(selection)
  def onSelectionCleared(selection)
    #close
  end

  # override WebDialog.onSelectionBulkChange(selection)
  def onSelectionBulkChange(selection)
    if selection.size != 1
      close
      return
    end
    entity = selection[0]

    dict=Hash.new
    5.times{|i|
      dict["id"+(i+1).to_s]=""
    }
    if entity.typename != "Group"
      _send_to_html(dict)
      return
    end
    dict['id1'] = entity.get_attribute("BuildingBlock","pln_zone")
    dict['id2'] = entity.get_attribute("BuildingBlock","pln_program")
    dict['id3'] = entity.get_attribute("BuildingBlock","pln_tower")
    dict['id4'] =  entity.get_attribute("BuildingBlock","bd_ftfh")
    area=entity.get_attribute("BuildingBlock","bd_area")
    area=sprintf("%.2f",area) if area !=nil
    dict['id5'] = area

    _send_to_html(dict)
  end


  def onFillDefault()
    @default=["zone1","retail","t1","3"]
    dict=Hash.new
    4.times{|i|
      dict["id"+(i+1).to_s]=@default[i]
    }
    _send_to_html(dict)

  end

  # 按下确认键的动作
  def onConfirm(params)
    excel_manager=SUExcel::ExcelManager.get_singleton
    p "dialog confirmed! params=#{params}"
    info = params.split('_')
    selections = Sketchup.active_model.selection
    if  selections.empty?
      UI.messagebox("未选择任何组！")
      return
    end

    # 防止更新底面积和同步excel
    excel_manager.enable_send_to_excel =false
    BH_BaseArea.enable_dynamic_update_base_area=false

    selections.each{|e|
      if e.typename == "Group"
        BuildingBlock.create_or_invalidate(e,info[0],info[2],info[1],info[3].to_f)
      end
    }
    # 批量更新底面积和同步excel
    excel_manager.enable_send_to_excel =true
    excel_manager.updateInstanceData()
    BH_BaseArea.enable_dynamic_update_base_area=true
    BH_BaseArea.update_base_area

  end

  #-----------------自用方法------------------------
  #发送消息到html
  def _send_to_html(dict)
    dict.each{|key,val|
      @dlg.execute_script("document.getElementById('#{key}').value='#{val}'")
    }
  end

end