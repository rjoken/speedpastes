module ProfileStyleOverridesHelper
  def profile_style_overrides_attribute(user)
    styles = user.profile_style
      .to_h
      .slice(*User::PROFILE_STYLE_KEYS)
      .filter { |key, value| valid_profile_style_override?(key, value) }
      .map { |key, value| "#{key}: #{value};" }
      .join(" ")

    background_styles = profile_background_styles(user)
    [ styles, *background_styles ].join(" ")
  end

  private

  def valid_profile_style_override?(key, value)
    case User::PROFILE_STYLE_SCHEMA.dig(key, :type)
    when :color
      value.is_a?(String) && value.match?(User::HEX_COLOR_REGEX)
    when :choice
      choices = User::PROFILE_STYLE_SCHEMA.dig(key, :choices) || []
      choices.include?(value)
    else
      false
    end
  end

  def profile_background_styles(user)
    return [] unless user.is_supporter?
    return [] unless user.background_image.attached?

    display = user.profile_style.to_h["--bg-display"]

    repeat = display == "tile" ? "repeat" : "no-repeat"

    size =
    case display
    when "tile" then "auto"
    when "stretch" then "100% 100%"
    else "auto"
    end

    position = display == "center" ? "center center" : "top left"

    [
      "background-image: url('#{url_for(user.background_image)}');",
      "background-repeat: #{repeat};",
      "background-size: #{size};",
      "background-position: #{position};"
    ]
  end
end
