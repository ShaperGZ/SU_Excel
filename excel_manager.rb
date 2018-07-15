module SUExcel
  class ExcelManager
    attr_accessor :enable_send_to_excel
    attr_accessor :excel_conduit

    # data as static/class variable
    # access with DataManager.data
    @@data = nil
    @@singleton = nil
    def self.data
      return @@data
    end

    def self.get_singleton()
      @@singleton=ExcelManager.new if @@singleton == nil
      return @@singleton
    end

    def initialize()
      #数据字典
      @@data = Hash.new
      @excel_conduit = ArchUtil::ExcelConduit.new()
      @enable_send_to_excel = true
      connect('PlayGround.xlsx')
    end

    def connect(workbook='PlayGround.xlsx')
      @excel_conduit.connect_dynamic(workbook)
    end

    def clearData
      @@data.clear
    end

    def setEntity(entity)
      block_info=_entity_to_array(entity)
      #@@data[entity.guid] = block_info
      @@data[entity] = block_info
    end

    def deleteEntity(entity)
      #@@data.delete(entity.guid)
      @@data.delete(entity)
    end

    def setUpdate(entity)
      return if entity==nil
      setEntity(entity)
      updateToExcel
    end
    def deleteUpdate(entity)
      deleteEntity(entity)
      updateToExcel
    end

    def updateToExcel()
      return if !@enable_send_to_excel or @@data.size<1
      @excel_conduit.update_matrix(@@data)
    end

    def update_base_area(area)
      return if !@enable_send_to_excel
      return if @excel_conduit.work_sheet == nil
      @excel_conduit.work_sheet.Range("m1").Value = area
    end

    def _entity_to_array(ent, dict="BuildingBlock")
	    arr=[]
      arr<<ent.guid
      item_indices=["pln_zone","pln_tower","pln_program","bd_ftfh","bd_area"]
      item_indices.each{|item_index|
        arr<<ent.get_attribute(dict,item_index)
      }
      return arr
    end


  end
end
