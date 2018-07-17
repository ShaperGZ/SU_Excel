class BH_ExcelConduit < Arch::BlockUpdateBehaviour

  def initialize(gp,host)
    super(gp,host)
  end

  def onClose(e)
    em = SUExcel::ExcelManager.get_singleton
    em.setUpdate(e)
  end

  def onChangeEntity(e, invalidated)
    return if not invalidated[2]
    p '-> BH_ExcelConduit.onChangeEntity'
    em = SUExcel::ExcelManager.get_singleton
    em.setUpdate(e)
  end

  def onEraseEntity(entity)
    super(entity)
    em = SUExcel::ExcelManager.get_singleton
    p " psot delete em.keys=#{em.data.keys}"
    em.deleteUpdate(@gp)
    p " psot delete em.keys=#{em.data.keys}"
  end

end