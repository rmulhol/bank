module Depository

  DatasetMethods = [:select, :select_all, :select_append, :select_group,
        :select_more, :join, :left_join, :right_join, :full_join,
        :natural_join, :natural_left_join, :natural_right_join,
        :natural_full_join, :cross_join, :inner_join, :left_outer_join,
        :right_outer_join, :full_outer_join, :join_table, :where, :filter,
        :exclude, :exclude_where, :and, :or, :grep, :invert, :unfiltered,
        :group, :group_by, :group_and_count, :select_group, :ungrouped,
        :having, :exclude_having, :invert, :unfiltered, :order, :order_by,
        :order_append, :order_prepend, :order_more, :reverse, :reverse_order,
        :unordered, :limit, :offset, :unlimited, :union, :intersect, :except,
        :for_update, :lock_style, :with, :with_recursive, :clone, :distinct,
        :naked, :qualify, :server, :with_sql,
        :insert, :update, :delete, :max, :min]

end
