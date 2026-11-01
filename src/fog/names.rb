module Fog

  # Rules for the unit name (requirements, section 3.3)
  module Names

    # Two names are in conflict if they are the same, or if one starts with the other plus '-'.
    # All names of a unit are <name> or start with <name>-.
    def self.conflict?(a, b)
      a = a.downcase
      b = b.downcase
      a == b || a.start_with?("#{b}-") || b.start_with?("#{a}-")
    end

    # Returns the reason why the name is not valid, or nil. existing: names of the tags, tag
    # folders, component definitions and scenes of the model.
    def self.error(name, existing)
      return 'The group has no name. Write the unit name in Entity Info > Instance.' if name.empty?
      return "The name \"#{name}\" must not start with f_ or g_." if name.match?(/\A[fg]_/i)
      other = existing.find { |e| conflict?(name, e) }
      other && "The name \"#{name}\" is in conflict with \"#{other}\" in this model."
    end

  end

end
