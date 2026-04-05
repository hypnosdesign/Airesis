module CanCan
  module ModelAdapters
    class ActiveRecordAdapter
      def database_records(eager_load = true)
        if override_scope
          @model_class.where(nil).merge(override_scope)
        elsif @model_class.respond_to?(:where) && @model_class.respond_to?(:joins)
          relation = @model_class.where(conditions || {})
          if joins.present?
            relation = if eager_load
                         relation.includes(joins).references(joins)
                       else
                         relation.left_joins(joins).distinct
                       end
          end
          relation
        else
          @model_class.all
        end
      end
    end
  end
end
