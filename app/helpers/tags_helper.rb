module TagsHelper
    def normalize_tags(raw_tags)
        Array(raw_tags).flat_map { |t| t.to_s.split(",") }.map { |tag| tag.strip.downcase }.reject(&:blank?).uniq
    end
end