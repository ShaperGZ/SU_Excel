require 'sketchup.rb'


module Prototyping
  class CreatePrototype
    def initialize()
      super
      Definitions.load()
      activate
    end
    def activate
      p ' activate'
      @prototype = Prototype.new
      @mouse_ip = Sketchup::InputPoint.new

      @pick_points=[]
      for i in 0..3
        @pick_points<< Sketchup::InputPoint.new
      end

      @picked_org_ip = Sketchup::InputPoint.new
      @picked_xref_ip = Sketchup::InputPoint.new
      @picked_yref_ip = Sketchup::InputPoint.new
      @picked_zref_ip = Sketchup::InputPoint.new

      @has_next=true


    end

    def _mag_vects()

      size=[60,30,20]

      #default values
      xv=Geom::Vector3d.new(size[0],0,0)
      yv=Geom::Vector3d.new(0,size[1],0)
      zv=Geom::Vector3d.new(0,0,size[2])
      return [xv,yv,zv] if !@picked_xref_ip.valid? || !@picked_org_ip.valid?

      #calculate vects from inputs
      up=Geom::Vector3d.new(0,0,1)
      #----------------------------------
      xv=@picked_xref_ip.position - @picked_org_ip.position
      p "xv=#{xv}"
      if @picked_yref_ip.valid?
        yv = @picked_yref_ip.position - @picked_org_ip.position
        p "yv=#{yv}"
      else
        yv = up.cross(xv.normalize)
        yv.length = size[1]
      end
      zv=up.clone
      zv.length=size[2]
      #zv= @picked_zref_ip.position - @picked_org_ip.position if @picked_zref_ip.valid?
      return [xv,yv,zv]

    end

    def _format_mag_vects()
      mv=_mag_vects
      t="magvects=#{mv[0]},#{mv[1]},#{mv[2]}"

    end

    def _unit_vects()
      vects=[]
      mag_vects=_mag_vects
      3.times{|i|
        return nil if mag_vects[i] ==nil
        vects<<mag_vects[i]
      }
      return vects
    end

    def _get_transform(origin,mag_vects)

    end

    def deactivate(view)
      view.invalidate
    end

    def resume(view)
      view.invalidate
    end

    def onCancel(reason, view)
      view.invalidate
      Sketchup.active_model.select_tool(nil)
    end

    def onMouseMove(flags, x, y, view)
      #TODO: have to update the second point here'
      lastpp=nil
      @pick_points.each{|pp|
        break if pp == nil
        lastpp=pp
      }
      if lastpp != nil
        @mouse_ip.pick(view,x,y,lastpp)
      else
        @mouse_ip.pick(view,x,y)
      end

      view.invalidate
      # if @picked_org_ip.valid?
      #   @mouse_ip.pick(view,x,y,@picked_org_ip)
      # elsif @picked_xref_ip.valid?
      #   @mouse_ip.pick(view,x,y,@picked_xref_ip)
      # elsif @picked_yref_ip.valid?
      #   @mouse_ip.pick(view,x,y,@picked_yref_ip)
      # else
      #   @mouse_ip.pick(view,x,y)
      # end
      # view.invalidate
    end

    def onLButtonDown(flags, x, y, view)

      pt=@mouse_ip.position
      @has_next=@prototype.set_point(pt) if @has_next

      if !@has_next
        @prototype.confirm_creation
        Sketchup.active_model.select_tool(nil)
      end

    end

    def onRButtonDown(flags, x, y, view)
      if @prototype.picked_points[0]!=nil
        begin
          @prototype.confirm_creation
        rescue Exception=> e
          p e
        end

      end
      Sketchup.active_model.select_tool(nil)
    end

    def draw(view)
      @prototype.draw(view,@mouse_ip.position)
      # mag_vects=_mag_vects
      # pts=[]
      # pts<<@mouse_ip.position
      # pts<<pts[0]+mag_vects[0]
      # pts<<pts[1]+mag_vects[1]
      # pts<<pts[0]+mag_vects[1]
      #
      #
      # view.draw(GL_LINE_LOOP,pts)
      # view.draw_points(pts,pointsize =6 , pointstyle =2)
      @mouse_ip.draw(view)
      @pick_points.each {|pp|
        if pp.valid?
          pp.draw(view)
        end
      }
    end

    def create()
      p 'create'
      Sketchup.active_model.select_tool(nil)
    end
  end

  def Prototyping.set_tool()
    ts=Prototyping::CreatePrototype.new
    Sketchup.active_model.select_tool(ts)
  end
end



