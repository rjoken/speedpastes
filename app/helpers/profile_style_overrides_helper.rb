module ProfileStyleOverridesHelper
  def profile_style_overrides_attribute(user)
    user.profile_style
      .to_h
      .slice(*User::PROFILE_STYLE_KEYS)
      .filter { |key, value| valid_profile_style_override?(key, value) }
      .map { |key, value| "#{key}: #{value};" }
      .join(" ")
  end

  private

  def valid_profile_style_override?(key, value)
    case User::PROFILE_STYLE_SCHEMA.dig(key, :type)
    when :color
      value.is_a?(String) && value.match?(User::HEX_COLOR_REGEX)
    else
      false
    end
  end
end
