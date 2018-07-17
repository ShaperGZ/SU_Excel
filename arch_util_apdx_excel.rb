module ArchUtil
  class ExcelConduit
    attr_accessor :excel
    attr_accessor :work_book
    attr_accessor :work_sheets
    @excel=nil
    @work_book=nil
    @work_sheets
    def initialize()
      @work_sheets=Hash.new
    end

    def connect_dynamic(workbook, sheet='sheet1')
      begin
        p "Trying to connect to workbook: #{workbook}"
        @excel = WIN32OLE.connect("excel.application")
        p "@excel=#{@excel}"
        @work_book = @excel.Workbooks(workbook)
        p "@work_book=#{@work_book}"
        @work_sheets[sheet] = @work_book.Worksheets(sheet)
        p "已连接到#{@work_sheets[sheet].name}"
      rescue
       p "failed to connect to excel #{workbook}.#{sheet}"
      end



    end

    def update_matrix(data, sheet, clear_size_h=80,clear_size_w=8)  #更新整个execel
      if !@work_sheets.key?sheet or @work_sheets[sheet]==nil
        p "excel is not connected to a work sheet: #{sheet}"
        return
      end
      work_sheet=@work_sheets[sheet]
      p "work sheet = #{work_sheet}"
      count=0
      if data!=nil and data.size>0
        row_indices=[*?a..?z]
        count=data.keys.size
        data_width=data[data.keys[0]].size
      end

      # iterate row
      for i in 1..clear_size_h
        # guid is the first item in a row
        if count >0 and (i-1) < count
          key=data.keys[i-1]
          if key==nil
            p "!key == nil ; data=#{data}"
            return
          end
          if key.class == Sketchup::Group
            work_sheet.Range("a"+i.to_s).Value= key.guid.to_s
          else
            work_sheet.Range("a"+i.to_s).Value= key
          end

          # iterate columns on each row
          for j in 0..data_width-1
            if j< row_indices.size
              index=row_indices[j]
              if i<=count
                value=data[key][j]
              else
                value=""
              end
              work_sheet.Range(index+i.to_s).Value= value
            end # end if j<
          end # end for j

        else
          #p 'else'
          work_sheet.Range("#{i}0:#{i}").Value=""
        end # end for i-1

      end # end for i
    end #end def


  end # end class ExcelConduit
end