module ArchUtil
  class ExcelConduit
    attr_accessor :excel
    attr_accessor :work_book
    attr_accessor :work_sheet
    @excel=nil
    @work_book=nil
    @work_sheet
    def connect_dynamic(workbook, sheet='sheet1')
      #begin
      p "Trying to connect to workbook: #{workbook}"
      @excel = WIN32OLE.connect("excel.application")
      p "@excel=#{@excel}"
      @work_book = @excel.Workbooks(workbook)
      p "@work_book=#{@work_book}"
      @work_sheet = @work_book.Worksheets(sheet)
      p "已连接到#{@work_sheet.name}"
      #rescue
      #  p 'failed to connect to excel'
      #end



    end

    def update_matrix(data,clear_size=100)  #更新整个execel
      if @work_sheet == nil
        p "excel is not connected to a work sheet"
        return
      end

      return if data==nil or data.size==0

      row_indices=[*?a..?z]
      count=data.keys.size
      data_width=data[data.keys[0]].size
      # iterate row
      for i in 1..clear_size
        # guid is the first item in a row
        if (i-1) < count
          key=data.keys[i-1]
          if key==nil
            p "!key == nil ; data=#{data}"
            return
          end
          @work_sheet.Range("a"+i.to_s).Value= key.guid.to_s

          # iterate columns on each row
          for j in 1..data_width-1
            if j< row_indices.size
              index=row_indices[j]
              if i<=count
                value=data[key][j]
              else
                value=""
              end
              @work_sheet.Range(index+i.to_s).Value= value
            end # end if i-1
          end # end for j
        end # end for k

      end # end for i
    end #end def


  end # end class ExcelConduit
end