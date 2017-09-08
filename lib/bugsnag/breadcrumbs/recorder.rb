module Bugsnag
    module Breadcrumbs

        class Recorder

            MAX_ITEMS = 25

            attr_accessor :breadcrumbs
            attr_accessor :current_item

            def initialize
                self.breadcrumbs = []
                self.current_item = 0
            end

            def add_breadcrumb(breadcrumb)
                if @breadcrumbs.length >= Recorder::MAX_ITEMS
                    @breadcrumbs[current_item] = breadcrumb
                else
                    @breadcrumbs.push(breadcrumb)
                end

                @current_item += 1

                if @current_item >= Recorder::MAX_ITEMS
                    @current_item = 0
                end
            end

            def ordered_breadcrumbs
                oldest = @breadcrumbs.last(@breadcrumbs.length - @current_item)
                newest = @breadcrumbs.first(@current_item)
                oldest.concat(newest)
            end

            def get_breadcrumbs
                raise ArgumentError, "get_breadcrumbs must be passed a block" unless block_given?
                
                ordered_breadcrumbs.each do |breadcrumb|
                    yield breadcrumb
                end
            end
        end
    end
end