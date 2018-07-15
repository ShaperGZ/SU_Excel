class BH_ExcelConduit < Arch::BlockUpdateBehaviour
  @xscale=1
  @yscale=1
  @zscale=1
  def initialize(gp,host)
    super(gp,host)
    @xscale=gp.transformation.xscale
    @yscale=gp.transformation.yscale
    @zscale=gp.transformation.zscale
  end

  def onClose(e)
    em = SUExcel::ExcelManager.get_singleton
    em.setUpdate(e)
  end

  def onChangeEntity(e)
    if e.transformation.xscale!= @xscale or e.transformation.yscale!= @yscale or e.transformation.zscale!= @zscale
      em = SUExcel::ExcelManager.get_singleton
      em.setUpdate(e)

      @xscale=e.transformation.xscale
      @yscale=e.transformation.yscale
      @zscale=e.transformation.zscale
    end

  end

  def onEraseEntity(entity)
    super(entity)
    em = SUExcel::ExcelManager.get_singleton
    em.deleteUpdate(@gp)
  end

end