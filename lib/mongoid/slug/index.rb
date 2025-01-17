module Mongoid
  module Slug
    module Index
      # @param [ String or Symbol ] scope_key The optional scope key for the index
      # @param [ Boolean ] by_model_type Whether or not
      #
      # @return [ Array(Hash, Hash) ] the indexable fields and index options.
      def self.build_index(scope_key = nil, by_model_type = false, locale = nil)
        # The order of field keys is intentional.
        # See: http://docs.mongodb.org/manual/core/index-compound/
        fields = {}
        fields[:_type] = 1       if by_model_type
        fields[scope_key] = 1 if scope_key
        if locale
          fields["_slugs.#{locale}"] = 1
        else
          fields[:_slugs] = 1
        end

        # By design, we use the unique index constraint when possible to enforce slug uniqueness.
        # When migrating legacy data to Mongoid slug, the _slugs field may be null on many records,
        # hence we set the sparse index option to ignore these from the unique index.
        # See: http://docs.mongodb.org/manual/core/index-sparse/
        #
        # There are three edge cases where the index must not be unique:
        #
        # 1) Legacy tables with `scope_key`. The sparse indexes on compound keys (scope + _slugs) are
        #    whenever ANY of the key values are present (e.g. when scope is set and _slugs is unset),
        #    and collisions will occur when multiple records have the same scope but null slugs.
        #
        # 2) Single Table Inheritance (`by_model_type`). MongoDB creates indexes on the parent collection,
        #    irrespective of how STI is defined in Mongoid, i.e. ANY child index will be applied to EVERY child.
        #    This can cause collisions using various combinations of scopes.
        #
        # In the future, MongoDB may implement partial indexes or improve sparse index behavior.
        # See: https://jira.mongodb.org/browse/SERVER-785
        #      https://jira.mongodb.org/browse/SERVER-13780
        #      https://jira.mongodb.org/browse/SERVER-10403
        options = {}
        unless scope_key || by_model_type
          options[:unique] = true
          options[:sparse] = true
        end

        [fields, options]
      end
    end
  end
end
