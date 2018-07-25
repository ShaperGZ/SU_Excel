class BH_Components < Arch::BlockUpdateBehaviour
  @@generated_objects=Hash.new
  def self.BH_Components

  end

  def self.clear()
    for i in 0..@@generated_objects.size-1
      key=@@generated_objects.keys[i]
      o=@@generated_objects[key]
      o.erase! if o.valid?
    end
    @@generated_objects.clear
  end

  def self.orient_definition(definition,bblock)
    width=1.5
    
    ftfh=bblock.gp.get_attribute("BuildingBlock","bd_ftfh")
    qfs=BH_Components.get_quad_faces(bblock)
    trans=BH_Components.get_transforms_for_quad_face(qfs,width)
    defsize=definition.bounds.max
    scalex=width/defsize[0]
    scalez=ftfh/defsize[2]
    tscale=Geom::Transformation.scaling(scalex,1,scalez)

    container=Sketchup.active_model.entities.add_group
    trans.each{|t|
      comp=container.entities.add_instance(definition,tscale)
      comp.transform! t
    }
  end

  def self.get_quad_faces(bblock)
    gp=bblock.gp.copy
    cuts=bblock.get_updator_by_type(BH_CalArea).cuts
    if cuts==nil
      p "cuts==nil from BH_Components.get_qud_faces"
    end
    ArchUtil.intersect(gp,cuts,gp)
    sel=Sketchup.active_model.selection
    sel.clear
    quad_faces=[]

    gp.entities.each{|f|
      if f.class == Sketchup::Face and f.normal.z.abs!=1
        # 测试面是否是4点，但有可能会有些多余的点在直线上
        # 检测并删除多余点

        # 如果一个顶点相邻的边的法线没有一样的就通过
        pts=[]
        pass_count=0
        fail_count=0
        f.vertices.each{|v|
          alledges=v.edges
          edges=[]
          alledges.each{|e|
            edges<<e if f.edges.include?(e)
          }

          nc = ArchUtil.get_edge_normal(edges[0], true, true)
          passed=true
          for i in 1..edges.size-1
            n = ArchUtil.get_edge_normal(edges[i], true, true)
            if n==nc
              passed = false
              break
            else
            end
          end

          if passed
            pass_count+=1
          else
            fail_count+=1
          end
          pts<<v.position if passed
        }
        #p "pts.size = #{pts.size} pass:#{pass_count} fail:#{fail_count}"
        if pts.size==4
          #sel.add(f)
          quad_faces<<pts
        end
      end
    }
    gp.erase!
    return quad_faces
  end

  def self.get_transforms_for_quad_face(quad_faces,width=1.5)
    width *= $m2inch
    transforms=[]
    quad_faces.each{|qf|
      #transformation for one quad face
      pts = ArchUtil.sort_quad_verts(qf)
      vectx = (pts[1]-pts[0]).normalize
      vectz = (pts[3]-pts[0]).normalize
      vecty = vectz.cross(vectx)
      spand=(pts[1]-pts[0]).length
      count=(spand/width).round
      adjwidth=spand/count

      for i in 0..count-1
        vectoffset=vectx.clone
        vectoffset.length=adjwidth*i
        org=pts[0]+vectoffset
        transforms<<Geom::Transformation.new(org,vectx,vecty)
      end
    }
    return transforms
  end

  # def self_gen_transforms(bblock)
  #   cuts=bblock.get_updator_by_type(BH_CalArea).cuts
  #   edges=[]
  #   cuts.entities.each{|e|
  #     if e.class == Sketchup::Face
  #       vs=e.vertices
  #       for i in 0 .. vs.size-2
  #
  #       end
  #     end
  #   }
  # end

  def self._gen_uniform(gp)
    d1= ArchUtil.load_def('/components/comp01.skp')
    d2= ArchUtil.load_def('/components/comp02.skp')
    if @@generated_objects.key?(gp.guid)
      @@generated_objects[gp.guid].erase!
    end

    #gp=block.gp
    container=Sketchup.active_model.entities.add_group
    @@generated_objects[gp.guid]=container
    p "contianer=#{container}"
    gp.entities.each{|e|
      if e.class == Sketchup::Face and e.normal.z.abs!=1
        if e.normal.y.abs > 0.5
          ArchUtil.orient_definition_to_face(d1,e,gp,container,true)
        else
          ArchUtil.orient_definition_to_face(d2,e,gp,container,true)
        end
      end
    }

  end
end