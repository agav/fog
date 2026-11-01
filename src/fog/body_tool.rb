module Fog

  # Button 1. Move the cursor: the tool highlights a valid shape. Click it: the tool reads the
  # unit name from the instance name of the group, then Left / Right select the overlap and
  # Enter or a click makes the body. Esc goes one step back, then exits.
  class BodyTool

    COLOR_PANEL = Sketchup::Color.new(254, 222, 11)   # same yellow as ocl-joints
    COLOR_FRONT = Sketchup::Color.new(255, 140, 0)
    LINE_WIDTH = 1
    FRONT_WIDTH = 3
    PICK_APERTURE = 6

    def self.cursor
      @cursor ||= UI.create_cursor(File.join(PLUGIN_ROOT, 'cursors', 'body.svg'), 2, 2)
    end

    def activate
      @model = Sketchup.active_model
      _reset
      _status
    end

    def onSetCursor
      UI.set_cursor(BodyTool.cursor)
    end

    def deactivate(view)
      view.invalidate
    end

    def resume(view)
      _status
      view.invalidate
    end

    def getExtents
      @model.bounds
    end

    def onCancel(reason, view)
      if reason != 2 && @picked.nil?   # 2: undo, the model changed
        @model.select_tool(nil)
        return
      end
      _reset
      _status
      view.invalidate
    end

    def onMouseMove(flags, x, y, view)
      return if @picked
      group = _pick_group(view, x, y)
      return if group == @hover
      @hover = group
      @result = group && Builder.analyze(group)
      @note = @result&.error && "This group is not valid: #{@result.error}"
      @hover_lines = @result && @result.error.nil? ? _edge_lines(group) : nil
      _status
      view.invalidate
    end

    def onLButtonUp(flags, x, y, view)
      if @picked
        _accept(view)
      elsif @hover_lines && @hover.valid?
        _pick(view)
      end
    end

    def onReturn(view)
      _accept(view) if @picked
    end

    def onKeyDown(key, repeat, flags, view)
      return false unless @picked && [ VK_LEFT, VK_RIGHT ].include?(key)
      Fog.overlap = Fog.overlap == :a ? :b : :a
      _update_panels
      _status
      view.invalidate
      true
    end

    def draw(view)
      view.line_stipple = ''
      if @picked
        _draw_lines(view, @picked[:front], COLOR_FRONT, FRONT_WIDTH)
        _draw_lines(view, @picked[:lines], COLOR_PANEL, LINE_WIDTH)
      elsif @hover_lines && @hover.valid?
        _draw_lines(view, @hover_lines, COLOR_PANEL, LINE_WIDTH)
      end
    end

    private

    def _reset
      @hover = nil
      @result = nil
      @hover_lines = nil
      @picked = nil
      @note = nil
    end

    # A group in the model root. best_picked is the entity that the select tool would pick.
    def _pick_group(view, x, y)
      entity = view.pick_helper(x, y, PICK_APERTURE).best_picked
      entity.is_a?(Sketchup::Group) && entity.parent.is_a?(Sketchup::Model) ? entity : nil
    end

    def _edge_lines(group)
      t = group.transformation
      group.definition.entities.grep(Sketchup::Edge).flat_map do |edge|
        edge.vertices.map { |v| v.position.transform(t) }
      end
    end

    def _pick(view)
      name = @hover.name.strip
      error = Names.error(name, Builder.existing_names(@model))
      if error
        UI.messagebox(error)
        return
      end
      points = @result.points
      frame = Layout.frame(points, @result.axis, Builder.to_camera(view, points))
      @picked = { group: @hover, name: name, frame: frame, front: _points(Layout.front_lines(frame)) }
      _update_panels
      _status
      view.invalidate
    end

    def _update_panels
      @picked[:panels] = Layout.panels(@picked[:frame], Fog.overlap, Shape::THICKNESS)
      @picked[:lines] = _points(@picked[:panels].flat_map(&:lines))
    end

    def _accept(view)
      Builder.build(@model, @picked[:group], @picked[:name], @picked[:panels])
      name = @picked[:name]
      _reset
      @note = "Body \"#{name}\" is ready."
    rescue StandardError => e
      UI.messagebox("FOG could not make the body: #{e.message}")
      _reset
    ensure
      _status
      view.invalidate
    end

    def _points(mm_points)
      mm_points.map { |p| Geom::Point3d.new(*p.map(&:mm)) }
    end

    def _draw_lines(view, points, color, width)
      view.line_width = width
      view.drawing_color = color
      view.draw(GL_LINES, points)
    end

    def _status
      text = if @picked
               option = Fog.overlap == :a ? 'top and bottom cover the sides' : 'the sides cover top and bottom'
               "Unit \"#{@picked[:name]}\": #{option}. Left / Right: other option. Enter or click: make the body. Esc: back."
             elsif @model.active_path
               'Close all groups: the shape must be in the model root.'
             else
               'Click a drawn shape (18 mm walls, through opening). The unit name is its instance name. Esc: exit.'
             end
      Sketchup.status_text = [ @note, text ].compact.join(' ')
    end

  end

end
