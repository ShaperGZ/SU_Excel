module SUExcel
  class WebDialogWrapper
    # 这个静态变量管理所有创建过的窗口
    @@created_objects=Hash.new
    def WebDialogWrapper.created_objects
      @@created_objects
    end


    def WebDialogWrapper.get(name)
      if @@created_objects.key?(name)
        return @@created_objects[name]
      end
      return nil
    end

    def WebDialogWrapper.set(name,dialog)
      if @@created_objects.key?(name)
        obv=@@created_objects[name]
        obv.close
        begin
          Sketchup.active_model.selection.remove_observer(obv)
        rescue
          p 'nothing to remove'
        end
      end
      @@created_objects[name] = dialog
    end

    #查询一个窗口是否被创建过
    def WebDialogWrapper.created?(dialog)
      return @@created_objects.include?dialog
    end

    # 创建时会加入到静态数据列已做管理
    def initialize(name)
      @name=name
      SUExcel::WebDialogWrapper.set(name, self)
      Sketchup.active_model.selection.add_observer(WebDialogSelectionObserver.new(self))
      # do somthing
    end

    # 切换显隐叫toggle
    @visible=false
    def toggle()
      @visible = !visible
      #do somthing
    end

    #----------------- instance ----------------------

    # 继承时无需写super,因为需要按需判断和设置@visible状态
    def open()
      #override
      @visible=true
    end

    # 继承时无需写super,因为需要按需判断和设置@visible状态
    def close()
      #override
      @visible=false
    end


    def onSelectionCleared(selection)
      close
    end

    def onSelectionBulkChange(selection)
    end
  end # end class

  class WebDialogSelectionObserver < Sketchup::SelectionObserver
    def initialize(dialog)
      @host=dialog
    end

    def onSelectionCleared(selection)
      return if @host == nil
      @host.onSelectionCleared(selection)
    end

    def onSelectionBulkChange(selection)
      return if @host == nil
      @host.onSelectionBulkChange(selection)
    end


  end

end
