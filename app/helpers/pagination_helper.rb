module PaginationHelper
    def pagy_link(pagy, page, label: nil, classes: "")
        label ||= page.to_s
        href = pagy.page_url(page)
        link_to label, href, class: classes
    end
end