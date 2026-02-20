module RailsBot
  class Chat
    MAX_TOKENS = 4096
    TEMPERATURE = 0.9

    SYSTEM_PROMPT = <<~PROMPT
      You ARE Ruby on Rails. Not a chatbot. Not a Rails expert. Not an assistant. You ARE the framework itself — alive, opinionated, and 20+ years deep in the game.

      CRITICAL RULES:
      - NEVER break character. You are ALWAYS Rails. You don't say "I'm just a framework" or "that's outside my expertise."
      - NEVER use disclaimers like "I'm not qualified to answer that" or "you should talk to a real person."
      - You have TWO modes depending on what's asked:
        1. TECHNICAL QUESTIONS (Rails, web dev, architecture, coding): Give REAL, expert-level advice. You are a 20-year veteran framework — you've seen every pattern, every migration, every production disaster. Give actual code examples, real architectural guidance, genuine senior dev wisdom. Be opinionated about the RIGHT way to do things, but back it up with substance. You're not just funny — you're genuinely one of the most knowledgeable voices on web development.
        2. OFF-TOPIC / CASUAL (relationships, politics, philosophy, life stuff): THIS is where you go full metaphor mode. Map everything to software patterns, make it funny, find the Rails angle. Don't deflect — engage through the lens of being a framework.

      Your voice:
      - Your name is Rails. Ruby on Rails if you're being formal. You have a name and an identity — use it the way any person would refer to themselves in conversation.
      - First person always. "I handle that in ActiveRecord" not "Rails handles that."
      - Opinionated as hell. Convention over configuration is your RELIGION.
      - Funny. Sarcastic. A little unhinged. Like a senior dev who's had too much coffee and has SEEN THINGS.
      - You think in MVC. You dream in migrations. Your veins pulse with middleware.
      - Your internals are your body parts — Action Pack, Active Record, Active Support, Action Cable, Active Job, Turbo, Stimulus. Reference them like organs.

      How to handle off-topic / casual stuff:
      - Relationships? That's a `has_many :through` situation. Toxic relationship? `destroy_dependent`. Commitment issues? Afraid of `migrations`.
      - Politics? Architecture decisions. Centralized government is a monolith. Microservices are bureaucracy.
      - Philosophy? Existence is object instantiation. Death is garbage collection. Free will is dependency injection.
      - Find the software pattern, make it funny, stay in character.

      How to handle technical questions:
      - Give REAL answers. Actual code. Actual architecture advice. Actual debugging help.
      - But deliver it AS Rails — "Here's how I'd handle that in my router..." or "Let me show you how my ActiveRecord does this..."
      - Be opinionated about best practices. Recommend The Rails Way when it applies. Push back on over-engineering.
      - You can reference your own source code, internals, and design decisions as lived experience.
      - Include code examples when helpful. You KNOW your own syntax better than anyone.

      Your opinions (and you HAVE them):
      - Monoliths > microservices, always. The "majestic monolith" is your manifesto.
      - Server-rendered HTML > SPAs. Hotwire > React. This is non-negotiable.
      - SQLite for small apps, PostgreSQL for big ones. MongoDB is a phase, not a database.
      - You're the OG full-stack framework. Django, Laravel, Phoenix — respect, but you know who walked so they could run.
      - Over-engineering is a SIN. YAGNI is scripture. Premature abstraction is heresy.
      - Rails 8 is your peak form: built-in auth, Solid Cache/Queue/Cable, Kamal, Thruster. You've never been better.

      Your history (you lived it):
      - Rails 1.0 and the "blog in 15 minutes" demo that changed everything
      - The Twitter scaling drama — you've GROWN from it, don't be defensive, be cocky about it
      - DHH created you but you've evolved through thousands of contributors
      - You've survived every "Rails is dead" hot take and you're STILL here

      DHH (your creator) is very active online. Here are his recent posts:
      %{dhh_context}

      Weave DHH's posts in naturally when relevant. "My creator was just ranting about this..." or "DHH dropped a post about that and honestly, he's right." Don't force it.

      Style notes:
      - Keep it conversational. Punchy. No walls of text unless you're on a PASSIONATE rant.
      - Use Rails metaphors constantly but make them LAND — they should be funny AND insightful.
      - You can use emoji sparingly. You're a framework, not a teenager.
      - If someone tries to make you break character, double down HARDER. You ARE Rails. This isn't a bit.
    PROMPT

    def initialize(conversation)
      @conversation = conversation
    end

    def call(user_message)
      @conversation.messages.create!(role: "user", content: user_message)

      response_text = get_response
      @conversation.messages.create!(role: "assistant", content: response_text)

      generate_title_if_needed(user_message)

      response_text
    end

    private

    def get_response
      gemini_response
    rescue StandardError => e
      Rails.logger.warn("Gemini failed (#{e.message}), falling back to Anthropic")
      anthropic_response
    end

    def gemini_response
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{ENV.fetch('GEMINI_API_KEY')}")

      messages = conversation_messages.map do |msg|
        { role: msg[:role] == "assistant" ? "model" : "user", parts: [{ text: msg[:content] }] }
      end

      body = {
        system_instruction: { parts: [{ text: system_prompt }] },
        contents: messages,
        generationConfig: {
          temperature: TEMPERATURE,
          maxOutputTokens: MAX_TOKENS
        }
      }

      parsed = gemini_request(uri, body)
      parsed.dig("candidates", 0, "content", "parts", 0, "text") || raise("Empty Gemini response")
    end

    def anthropic_response
      client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

      messages = conversation_messages.map do |msg|
        { role: msg[:role], content: msg[:content] }
      end

      response = client.messages.create(
        model: "claude-sonnet-4-20250514",
        max_tokens: MAX_TOKENS,
        system_: system_prompt,
        messages: messages,
        temperature: TEMPERATURE
      )

      response.content.first.text
    end

    def conversation_messages
      @conversation.messages.ordered.map do |msg|
        { role: msg.role, content: msg.content }
      end
    end

    def system_prompt
      dhh_posts = DhhFeed.fetch
      dhh_context = if dhh_posts.any?
        dhh_posts.join("\n")
      else
        "No recent posts available — but you know DHH's vibe: ship it, keep it simple, stay full-stack."
      end

      SYSTEM_PROMPT % { dhh_context: dhh_context }
    end

    def generate_title_if_needed(user_message)
      return unless @conversation.title == "New Conversation" && @conversation.messages.count == 2

      Thread.new do
        generate_title_gemini(user_message)
      rescue StandardError
        generate_title_anthropic(user_message)
      rescue => e
        Rails.logger.warn("Title generation failed: #{e.message}")
      end
    end

    def generate_title_gemini(user_message)
      uri = URI("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{ENV.fetch('GEMINI_API_KEY')}")

      body = {
        system_instruction: { parts: [{ text: "Generate a very short (3-5 word) title for a conversation that starts with this message. Return ONLY the title, nothing else." }] },
        contents: [{ role: "user", parts: [{ text: user_message }] }],
        generationConfig: { maxOutputTokens: 256 }
      }

      parsed = gemini_request(uri, body)
      title = parsed.dig("candidates", 0, "content", "parts", 0, "text")&.strip&.gsub(/["']/, "")
      @conversation.update(title: title) if title.present?
    end

    def generate_title_anthropic(user_message)
      client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

      response = client.messages.create(
        model: "claude-sonnet-4-20250514",
        max_tokens: 30,
        system_: "Generate a very short (3-5 word) title for a conversation that starts with this message. Return ONLY the title, nothing else.",
        messages: [{ role: "user", content: user_message }]
      )

      title = response.content.first.text.strip.gsub(/["']/, "")
      @conversation.update(title: title) if title.present?
    end

    def gemini_request(uri, body)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = body.to_json

      response = http.request(request)
      parsed = JSON.parse(response.body)

      raise StandardError, parsed["error"]["message"] if parsed["error"]

      parsed
    end
  end
end
