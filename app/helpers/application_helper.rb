module ApplicationHelper
  def render_markdown(text)
    renderer = Redcarpet::Render::HTML.new(
      hard_wrap: true,
      fenced_code_blocks: true,
      no_styles: true
    )
    markdown = Redcarpet::Markdown.new(renderer,
      fenced_code_blocks: true,
      autolink: true,
      tables: true,
      strikethrough: true,
      superscript: true,
      highlight: true,
      no_intra_emphasis: true
    )
    sanitize(markdown.render(text), tags: %w[p br strong em a code pre ul ol li h1 h2 h3 h4 blockquote table thead tbody tr th td hr span del sup], attributes: %w[href target class])
  end
end
