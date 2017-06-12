module Cfer
  module Auster
    module AwsUtils
      def self.all_from_pager(operation, paged_field)
        ret = []

        resp = operation

        loop do
          ret << resp.send(paged_field)

          if resp.next_page?
            resp = resp.next_page
          else
            break
          end
        end

        ret.flatten
      end
    end
  end
end
