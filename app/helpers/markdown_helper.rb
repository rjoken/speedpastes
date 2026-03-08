module MarkdownHelper
    def markdown(text)
        return "" if text.blank?

        Commonmarker.to_html(text, options: {
            extension: {
                strikethrough: true,
                table: true,
                autolink: true,
                tagfilter: true
            },
            parse: {
                smart: true
            },
            render: {
                unsafe: false
            }
        }).html_safe
    end
end
