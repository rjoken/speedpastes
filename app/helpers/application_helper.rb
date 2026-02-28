module ApplicationHelper
    def possessive(string)
        s = string.to_s
        return "" if s.empty?
        s.end_with?("s", "S") ? "#{s}'" : "#{s}'s"
    end
end
