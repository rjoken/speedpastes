module UiHelper
    def button_class(variant: :default, size: :sm)
        base = "cursor-pointer border font-bold shadow-sm"
        sizes = { xs: "px-2 py-1 text-xs font-regular", sm: "px-2 py-1 text-sm", md: "px-4 py-2 text-md", lg: "px-6 py-3 text-lg" }
        variants = {
            default: "border-[var(--button-border)] bg-[var(--button-bg)] hover:bg-[var(--button-bg-hover)]",
            danger: "border-[var(--border-danger)] bg-[var(--button-bg-danger)] hover:bg-[var(--button-bg-danger-hover)] text-[var(--text-danger)]",
            muted: "border-[var(--button-border)] bg-[var(--button-bg)] hover:bg-[var(--button-bg-hover)] font-normal text-[var(--muted)]",
        }
        [ base, sizes.fetch(size), variants.fetch(variant) ].join(" ")
    end

    def link_class(variant: :default, size: :md)
        base = "cursor-pointer hover:underline"
        sizes = { xs: "text-xs", sm: "text-sm", md: "text-md", lg: "text-lg" }
        variants = {
            default: "underline",
            text: "text-[var(--text)]",
            bold: "text-[var(--text)] font-semibold",
            muted: "text-[var(--muted)]",
            external: "text-[var(--external-link)] underline"
        }
        [ base, sizes.fetch(size), variants.fetch(variant) ].join(" ")
    end

    def gradient_class(variant: :default)
        base = "border-b border-[var(--border-muted)] bg-gradient-to-b from-[var(--surface2)] to-[var(--surface)]"
        variants = {
            default: "from-[var(--surface2)] to-[var(--surface)]",
            nav: "from-[var(--surface)] to-[var(--surface2)]"
        }
        [ base, variants.fetch(variant, "") ].join(" ")
    end

    def pagy_nav_class(variant: :inactive)
        base = "px-2 py-1 border shadow-sm"
        variants = {
            active: "border-[var(--border)] bg-[var(--surface)] hover:bg-[var(--surface2)]",
            inactive: "border-[var(--border-muted)] bg-[var(--surface2)] text-[var(--muted)] cursor-not-allowed"
        }
        [ base, variants.fetch(variant, "") ].join(" ")
    end
end
