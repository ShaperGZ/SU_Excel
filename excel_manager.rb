module SUExcel
  class ExcelManager
    attr_accessor :enable_send_to_excel
    attr_accessor :excel_conduit
    attr_accessor :data
    attr_accessor :static_data

    HEADER=[
        "pln_zone",
        "pln_program",
        "pln_tower",
        "bd_ftfh",
        "bd_area",
        "bd_height",
        "bd_floors"
    ]

    # access with DataManager.data
    @@singleton = nil
    def self.get_singleton()
      @@singleton=ExcelManager.new if @@singleton == nil
      return @@singleton
    end

    def initialize()
      #数据字典
      @data = Hash.new
      @static_data = Hash.new
      @excel_conduit = ArchUtil::ExcelConduit.new()
      @enable_send_to_excel = true
      connect('PlayGround.xlsx')
    end

    def connect(workbook='PlayGround.xlsx')
      @excel_conduit.connect_dynamic(workbook,sheet='InstanceData')
      @excel_conduit.connect_dynamic(workbook,sheet='StaticData')
    end

    def clearData
      @data.clear
    end

    def setEntity(entity)
      block_info=_entity_to_array(entity)
      #@data[entity.guid] = block_info
      @data[entity] = block_info
    end

    def deleteEntity(entity)
      #@data.delete(entity.guid)
      @data.delete(entity)
    end

    def setUpdate(entity)
      return if entity==nil
      setEntity(entity)
      updateInstanceData
    end
    def deleteUpdate(entity)
      deleteEntity(entity)
      updateInstanceData
    end

    def updateInstanceData()
      return if !@enable_send_to_excel
      mheader=["guid"]+ExcelManager::HEADER
      @excel_conduit.update_matrix(@data,'InstanceData')
    end

    def updateStaticData()
      return if !@enable_send_to_excel
      @excel_conduit.update_matrix(@static_data,'StaticData')
    end

    def update_base_area(area)
      return if !@enable_send_to_excel
      return if @excel_conduit.work_sheets['StaticData'] == nil
      @excel_conduit.work_sheets['StaticData'].Range("A1").Value= "BaseArea"
      @excel_conduit.work_sheets['StaticData'].Range("B1").Value= area.to_s
        #static_data["area"]=area
      #updateStaticData()
    end

    def _entity_to_array(ent, dict="BuildingBlock")
	    arr=[]
      arr<<ent.guid
      item_indices=ExcelManager::HEADER
      item_indices.each{|item_index|
        arr<<ent.get_attribute(dict,item_index)
      }
      return arr
    end


  end
end
