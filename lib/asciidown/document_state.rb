# frozen_string_literal: true

require_relative "constants"

class Asciidown
  # Encapsulates conversion state, registered attributes, and cross-reference targets.
  class DocumentState
    include Constants

    attr_accessor :attrs, :pass, :coseq, :refs, :nrefs, :q, :s

    def initialize(initial_attrs = {})
      @attrs = ATTRIBUTES.merge(initial_attrs.transform_keys(&:to_s))
      @pass = []
      @coseq = 1
      @refs = {}
      @nrefs = {}
      @q = nil
      @s = nil
    end

    def [](key)
      @attrs[key.to_s]
    end

    def []=(key, val)
      @attrs[key.to_s] = val
    end

    def key?(key)
      @attrs.key?(key.to_s)
    end

    def delete(key)
      @attrs.delete(key.to_s)
    end

    def quotes_pair
      @quotes_pair ||= (@attrs["quotes"] || "<q> </q>").split[0..1]
    end

    def strikethrough_pair
      return @s if @s

      pair = (@attrs["markdown-strikethrough"] || "~~").split
      @s = pair.length > 1 ? pair[0..1] : [pair[0], pair[0]]
    end
  end
end
