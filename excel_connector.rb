
module SUExcel
  class ExcelConnector
    def clearExcel()
      return if @work_sheet == nil
      for i in 1..100
        @work_sheet.Range("a"+i.to_s).Value= ""
        @work_sheet.Range("b"+i.to_s).Value= ""
        @work_sheet.Range("c"+i.to_s).Value= ""
        @work_sheet.Range("d"+i.to_s).Value= ""
        @work_sheet.Range("e"+i.to_s).Value= ""
        @work_sheet.Range("f"+i.to_s).Value= ""
        @work_sheet.Range("g"+i.to_s).Value= ""
        @work_sheet.Range("h"+i.to_s).Value= ""
      end
    end

    def connectExcel()
      excel = WIN32OLE.connect("excel.application")
      workbook = excel.Workbooks('PlayGround.xlsx')
      @work_sheet = workbook.Worksheets('Sheet1')
      p "已连接到#{@work_sheet.name}"
    end

    def updateExcel(data)  #更新整个execel
      if @work_sheet == nil
        p "excel is not connected to a work sheet"
      end

      #clearExcel()
      count=data.keys.size
      number = 0
      #data.keys.each{|key|
      for i in 1..100
        if i<=count
          key=data.keys[i-1]
          @work_sheet.Range("a"+i.to_s).Value= key
          @work_sheet.Range("b"+i.to_s).Value= data[key][0]
          @work_sheet.Range("c"+i.to_s).Value= data[key][1]
          @work_sheet.Range("d"+i.to_s).Value= data[key][2]
          @work_sheet.Range("e"+i.to_s).Value= data[key][3]
          @work_sheet.Range("f"+i.to_s).Value= data[key][4]

          #p 'exported:'+key.to_s
        else
          @work_sheet.Range("a"+i.to_s).Value= ""
          @work_sheet.Range("b"+i.to_s).Value= ""
          @work_sheet.Range("c"+i.to_s).Value= ""
          @work_sheet.Range("d"+i.to_s).Value= ""
          @work_sheet.Range("e"+i.to_s).Value= ""
          @work_sheet.Range("f"+i.to_s).Value= ""
        end
      end #for i
    end #end def
  end
end
