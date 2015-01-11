require 'uri'
require 'paperclip/url_generator'

module DelayedPaperclip
  class UrlGenerator < ::Paperclip::UrlGenerator

    def for(style_name, options)
      foo = most_appropriate_url(style_name)

      # Reversed in paperclip, effects processing
      # effects one test, need to determine how
      escape_url_as_needed(
        timestamp_as_needed(
          @attachment_options[:interpolator].interpolate(foo, @attachment, style_name),
          options
      ), options)
    end

    def most_appropriate_url(style = nil)
      if processing_style?(style)
        if @attachment.original_filename.nil? || delayed_default_url?(style)

          if @attachment.delayed_options.nil? ||
            @attachment.processing_image_url.nil? ||
            !@attachment.processing?
            default_url
          else
            @attachment.processing_image_url
          end

        else
          @attachment_options[:url]
        end
      else
        super()
      end
    end

    def timestamp_possible?
      delayed_default_url? ? false : super
    end

    def delayed_default_url?(style = nil)
      return false if @attachment.job_is_processing
      return false if @attachment.dirty?
      return false unless @attachment.delayed_options.try(:[], :url_with_processing)
      return false unless processing?(style)
      true
    end

    private

    def processing?(style)
      return true if @attachment.processing?
      return processing_style?(style) if style
    end

    def processing_style?(style)
      return false unless @attachment.processing?

      configured_to_process_style?(style)
    end

    def configured_to_process_style?(style)
      # Formerly
      # !split_processing? || @attachment.delayed_options[:only_process].include?(style)
      return true if @attachment.delayed_options[:only_process].nil?

      @attachment.delayed_options[:only_process] &&
      @attachment.delayed_options[:only_process].include?(style)
    end

    # Duplicated in attachment.rb
    def split_processing?
      @attachment.options[:only_process] &&
        @attachment.delayed_options &&
        @attachment.options[:only_process] != @attachment.delayed_options[:only_process]
    end



  end
end
