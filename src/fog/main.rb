require 'sketchup.rb'

module Fog

  PLUGIN_ROOT = File.dirname(__FILE__)
  SOURCE_FILES = %w[vec names shape layout builder body_tool].freeze
  MIN_SKETCHUP_VERSION = 21   # tag folders

  SOURCE_FILES.each { |f| require File.join(PLUGIN_ROOT, f) }

  # Overlap option of button 1, kept between tool runs in this SketchUp session
  def self.overlap
    @overlap || :a
  end

  def self.overlap=(option)
    @overlap = option
  end

  def self.start_body
    if Sketchup.version.to_i < MIN_SKETCHUP_VERSION
      UI.messagebox('FOG needs SketchUp 2021 or newer (tag folders).')
    else
      Sketchup.active_model.select_tool(BodyTool.new)
    end
  end

  # Development helper: loads all source files again and restarts an active Body tool.
  # A new menu item or toolbar button still needs a SketchUp restart.
  def self.reload
    verbose, $VERBOSE = $VERBOSE, nil   # no "already initialized constant" warnings
    SOURCE_FILES.each { |f| load File.join(PLUGIN_ROOT, "#{f}.rb") }
    load __FILE__
    $VERBOSE = verbose
    BodyTool.instance_variable_set(:@cursor, nil)
    model = Sketchup.active_model
    tools = model.tools
    if tools.respond_to?(:active_tool) && tools.active_tool.is_a?(BodyTool)
      model.select_tool(nil)
      start_body
    end
    Sketchup.status_text = "FOG reloaded (#{Time.now.strftime('%H:%M:%S')})"
    puts 'FOG reloaded'
  rescue Exception => e   # also SyntaxError, which is not a StandardError
    $VERBOSE = verbose
    UI.messagebox("FOG reload failed:\n\n#{e.class}: #{e.message}\n\n#{e.backtrace.first(5).join("\n")}")
  end

  unless file_loaded?(__FILE__)
    command = lambda do |title, icon, text, &block|
      c = UI::Command.new(title, &block)
      c.tooltip = title
      c.status_bar_text = text
      c.small_icon = c.large_icon = File.join(PLUGIN_ROOT, 'icons', "#{icon}.svg")
      c
    end
    later = ->(title) { UI.messagebox("#{title}: this button is not ready yet.") }
    commands = [
      command.call('Body', 'body', 'Change a drawn shape into a body: four panels, tags and a scene') { start_body },
      command.call('Fronts', 'fronts', 'Add fronts (not ready yet)') { later.call('Fronts') },
      command.call('Back', 'back', 'Add a back (not ready yet)') { later.call('Back') },
      command.call('Edge bindings', 'edges', 'Make edge bindings (not ready yet)') { later.call('Edge bindings') },
      command.call('Joints', 'joints', 'Place joints (not ready yet)') { later.call('Joints') }
    ]

    menu = UI.menu('Extensions').add_submenu('FOG')
    commands.each { |c| menu.add_item(c) }
    menu.add_separator
    menu.add_item('Reload extension (dev)') { reload }

    toolbar = UI::Toolbar.new('FOG')
    commands.each { |c| toolbar.add_item(c) }
    toolbar.restore

    file_loaded(__FILE__)
  end

end
