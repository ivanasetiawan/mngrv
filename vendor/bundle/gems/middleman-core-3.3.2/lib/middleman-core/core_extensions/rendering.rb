# Shutup Tilt Warnings
# @private
class Tilt::Template
  def warn(*args)
    # Kernel.warn(*args)
  end
end

# Rendering extension
module Middleman
  module CoreExtensions
    module Rendering

      # Setup extension
      class << self

        # Once registered
        def registered(app)
          # Include methods
          app.send :include, InstanceMethods

          app.define_hook :before_render
          app.define_hook :after_render

          ::Tilt.mappings.delete('html') # WTF, Tilt?
          ::Tilt.mappings.delete('csv')

          require 'active_support/core_ext/string/output_safety'

          # Activate custom renderers
          require 'middleman-core/renderers/erb'
          app.register Middleman::Renderers::ERb

          # CoffeeScript Support
          begin
            require 'middleman-core/renderers/coffee_script'
            app.register Middleman::Renderers::CoffeeScript
          rescue LoadError
          end

          # Haml Support
          begin
            require 'middleman-core/renderers/haml'
            app.register Middleman::Renderers::Haml
          rescue LoadError
          end

          # Sass Support
          begin
            require 'middleman-core/renderers/sass'
            app.register Middleman::Renderers::Sass
          rescue LoadError
          end

          # Markdown Support
          require 'middleman-core/renderers/markdown'
          app.register Middleman::Renderers::Markdown

          # AsciiDoc Support
          begin
            require 'middleman-core/renderers/asciidoc'
            app.register Middleman::Renderers::AsciiDoc
          rescue LoadError
          end

          # Liquid Support
          begin
            require 'middleman-core/renderers/liquid'
            app.register Middleman::Renderers::Liquid
          rescue LoadError
          end

          # Slim Support
          begin
            require 'middleman-core/renderers/slim'
            app.register Middleman::Renderers::Slim
          rescue LoadError
          end

          # Less Support
          begin
            require 'middleman-core/renderers/less'
            app.register Middleman::Renderers::Less
          rescue LoadError
          end

          # Stylus Support
          begin
            require 'middleman-core/renderers/stylus'
            app.register Middleman::Renderers::Stylus
          rescue LoadError
          end

          # Clean up missing Tilt exts
          app.after_configuration do
            Tilt.mappings.each do |key, klasses|
              begin
                Tilt[".#{key}"]
              rescue LoadError, NameError
                Tilt.mappings.delete(key)
              end
            end
          end
        end

        alias :included :registered
      end

      # Custom error class for handling
      class TemplateNotFound < RuntimeError
      end

      # Rendering instance methods
      module InstanceMethods

        # Add or overwrite a default template extension
        #
        # @param [Hash] extension_map
        # @return [Hash]
        def template_extensions(extension_map=nil)
          @_template_extensions ||= {}
          @_template_extensions.merge!(extension_map) if extension_map
          @_template_extensions
        end

        # Render a template, with layout, given a path
        #
        # @param [String] path
        # @param [Hash] locs
        # @param [Hash] opts
        # @return [String]
        def render_template(path, locs={}, opts={}, blocks=[])
          extension = File.extname(path)
          engine = extension[1..-1].to_sym

          if defined?(::I18n)
            old_locale = ::I18n.locale
            ::I18n.locale = opts[:lang] if opts[:lang]
          end

          # Use a dup of self as a context so that instance variables set within
          # the template don't persist for other templates.
          context = self.dup
          blocks.each do |block|
            context.instance_eval(&block)
          end

          # Store current locs/opts for later
          @current_locs = locs, @current_opts = opts

          # Keep rendering template until we've used up all extensions. This
          # handles cases like `style.css.sass.erb`
          content = nil
          while ::Tilt[path]
            begin
              opts[:template_body] = content if content
              content = render_individual_file(path, locs, opts, context)
              path = File.basename(path, File.extname(path))
            rescue LocalJumpError
              raise "Tried to render a layout (calls yield) at #{path} like it was a template. Non-default layouts need to be in #{source}/#{config[:layouts_dir]}."
            end
          end

          # If we need a layout and have a layout, use it
          if layout_path = fetch_layout(engine, opts)
            content = render_individual_file(layout_path, locs, opts, context) { content }
          end

          # Return result
          content
        ensure
          # Pop all the saved variables from earlier as we may be returning to a
          # previous render (layouts, partials, nested layouts).
          ::I18n.locale = old_locale if defined?(::I18n)
          @content_blocks = nil
          @current_locs = nil
          @current_opts = nil
        end

        # Sinatra/Padrino compatible render method signature referenced by some view
        # helpers. Especially partials.
        #
        # @param [String, Symbol] engine
        # @param [String, Symbol] data
        # @param [Hash] options
        # @return [String]
        def render(engine, data, options={}, &block)
          data = data.to_s

          locals = options[:locals]

          found_partial = false
          resolve_opts = { try_without_underscore: true }

          # If the path is known to the sitemap
          if resource = sitemap.find_resource_by_path(current_path)
            current_dir = File.dirname(resource.source_file)
            resolve_opts[:preferred_engine] = File.extname(resource.source_file)[1..-1].to_sym

            # Look for partials relative to the current path
            relative_dir = File.join(current_dir.sub(%r{^#{Regexp.escape(self.source_dir)}/?}, ''), data)

            found_partial = resolve_template(relative_dir, resolve_opts)
          end

          # Look in the partials_dir for the partial with the current engine
          if !found_partial
            partials_path = File.join(config[:partials_dir], data)
            found_partial = resolve_template(partials_path, resolve_opts)
          end

          raise ::Middleman::CoreExtensions::Rendering::TemplateNotFound, "Could not locate partial: #{data}" unless found_partial

          # Render the partial if found, otherwide throw exception
          render_individual_file(found_partial, locals, options, self, &block)
        end

        # Render an on-disk file. Used for everything, including layouts.
        #
        # @param [String, Symbol] path
        # @param [Hash] locs
        # @param [Hash] opts
        # @param [Class] context
        # @return [String]
        def render_individual_file(path, locs = {}, opts = {}, context = self, &block)
          path = path.to_s

          # Detect the remdering engine from the extension
          extension = File.extname(path)
          engine = extension[1..-1].to_sym

          # Store last engine for later (could be inside nested renders)
          context.current_engine, engine_was = engine, context.current_engine

          # Save current buffer for later
          @_out_buf, _buf_was = '', @_out_buf

          # Read from disk or cache the contents of the file
          body = if opts[:template_body]
            opts.delete(:template_body)
          else
            template_data_for_file(path)
          end

          # Merge per-extension options from config
          extension = File.extname(path)
          options = opts.dup.merge(options_for_ext(extension))
          options[:outvar] ||= '@_out_buf'
          options.delete(:layout)

          # Overwrite with frontmatter options
          options = options.deep_merge(options[:renderer_options]) if options[:renderer_options]

          template_class = Tilt[path]
          # Allow hooks to manipulate the template before render
          self.class.callbacks_for_hook(:before_render).each do |callback|
            newbody = callback.call(body, path, locs, template_class)
            body = newbody if newbody # Allow the callback to return nil to skip it
          end

          # Read compiled template from disk or cache
          template = cache.fetch(:compiled_template, extension, options, body) do
           ::Tilt.new(path, 1, options) { body }
          end

          # Render using Tilt
          content = template.render(context, locs, &block)

          # Allow hooks to manipulate the result after render
          self.class.callbacks_for_hook(:after_render).each do |callback|
            content = callback.call(content, path, locs, template_class)
          end

          output = ::ActiveSupport::SafeBuffer.new ''
          output.safe_concat content
          output
        ensure
          # Reset stored buffer
          @_out_buf = _buf_was
          context.current_engine = engine_was
        end

        # Get the template data from a path
        # @param [String] path
        # @return [String]
        def template_data_for_file(path)
          File.read(File.expand_path(path, source_dir))
        end

        # Get a hash of configuration options for a given file extension, from
        # config.rb
        #
        # @param [String] ext
        # @return [Hash]
        def options_for_ext(ext)
          # Read options for extension from config/Tilt or cache
          cache.fetch(:options_for_ext, ext) do
            options = {}

            # Find all the engines which handle this extension in tilt. Look for
            # config variables of that name and merge it
            extension_class = ::Tilt[ext]
            ::Tilt.mappings.each do |mapping_ext, engines|
              next unless engines.include? extension_class
              engine_options = config[mapping_ext.to_sym] || {}
              options.merge!(engine_options)
            end

            options
          end
        end

        # Find a layout for a given engine
        #
        # @param [Symbol] engine
        # @param [Hash] opts
        # @return [String]
        def fetch_layout(engine, opts)
          # The layout name comes from either the system default or the options
          local_layout = opts.has_key?(:layout) ? opts[:layout] : config[:layout]
          return false unless local_layout

          # Look for engine-specific options
          engine_options = respond_to?(engine) ? send(engine) : {}

          # The engine for the layout can be set in options, engine_options or passed
          # into this method
          layout_engine = if opts.has_key?(:layout_engine)
            opts[:layout_engine]
          elsif engine_options.has_key?(:layout_engine)
            engine_options[:layout_engine]
          else
            engine
          end

          # Automatic mode
          if local_layout == :_auto_layout
            # Look for :layout of any extension
            # If found, use it. If not, continue
            locate_layout(:layout, layout_engine) || false
          else
            # Look for specific layout
            # If found, use it. If not, error.
            if layout_path = locate_layout(local_layout, layout_engine)
              layout_path
            else
              raise ::Middleman::CoreExtensions::Rendering::TemplateNotFound, "Could not locate layout: #{local_layout}"
            end
          end
        end

        # Find a layout on-disk, optionally using a specific engine
        # @param [String] name
        # @param [Symbol] preferred_engine
        # @return [String]
        def locate_layout(name, preferred_engine=nil)
          # Whether we've found the layout
          layout_path = false

          resolve_opts = {}
          resolve_opts[:preferred_engine] = preferred_engine if !preferred_engine.nil?

          # Check layouts folder
          layout_path = resolve_template(File.join(config[:layouts_dir], name.to_s), resolve_opts)

          # If we didn't find it, check root
          layout_path = resolve_template(name, resolve_opts) unless layout_path

          # Return the path
          layout_path
        end

        # Allow layouts to be wrapped in the contents of other layouts
        # @param [String, Symbol] layout_name
        # @return [void]
        def wrap_layout(layout_name, &block)
          # Save current buffer for later
          @_out_buf, _buf_was = '', @_out_buf

          layout_path = locate_layout(layout_name, self.current_engine)

          extension = File.extname(layout_path)
          engine = extension[1..-1].to_sym

          # Store last engine for later (could be inside nested renders)
          self.current_engine, engine_was = engine, self.current_engine

          begin
            content = if block_given?
              capture_html(&block)
            else
              ''
            end
          ensure
            # Reset stored buffer
            @_out_buf = _buf_was
          end

          concat_safe_content render_individual_file(layout_path, @current_locs || {}, @current_opts || {}, self) { content }
        ensure
          self.current_engine = engine_was
        end

        # The currently rendering engine
        # @return [Symbol, nil]
        def current_engine
          @_current_engine ||= nil
        end

        # The currently rendering engine
        # @return [Symbol, nil]
        def current_engine=(v)
          @_current_engine = v
        end

        # Find a template on disk given a output path
        # @param [String] request_path
        # @option options [Boolean] :preferred_engine If set, try this engine first, then fall back to any engine.
        # @option options [Boolean] :try_without_underscore
        # @return [Array<String, Symbol>, Boolean]
        def resolve_template(request_path, options={})
          # Find the path by searching or using the cache
          request_path = request_path.to_s
          cache.fetch(:resolve_template, request_path, options) do
            relative_path = Util.strip_leading_slash(request_path)
            on_disk_path  = File.expand_path(relative_path, self.source_dir)

            # By default, any engine will do
            preferred_engines = ['*']

            # If we're specifically looking for a preferred engine
            if options.has_key?(:preferred_engine)
              extension_class = ::Tilt[options[:preferred_engine]]
              matched_exts = []

              # Get a list of extensions for a preferred engine
              matched_exts = ::Tilt.mappings.select do |ext, engines|
                engines.include? extension_class
              end.keys

              # Prefer to look for the matched extensions
              unless matched_exts.empty?
                preferred_engines.unshift('{' + matched_exts.join(',') + '}')
              end
            end

            search_paths = preferred_engines.flat_map do |preferred_engine|
              path_with_ext = on_disk_path + '.' + preferred_engine
              paths = [path_with_ext]
              if options[:try_without_underscore]
                paths << path_with_ext.sub(relative_path, relative_path.sub(/^_/, '').sub(/\/_/, '/'))
              end
              paths
            end

            found_path = nil
            search_paths.each do |path_with_ext|
              found_path = Dir[path_with_ext].find do |path|
                ::Tilt[path]
              end
              break if found_path
            end

            # If we found one, return it and the found engine
            if found_path
              found_path
            elsif File.exists?(on_disk_path)
              on_disk_path
            else
              false
            end
          end
        end
      end
    end
  end
end