# config/initializers/json_patch.rb
require "active_support/json/encoding"

module ActiveSupport
  module JSON
    module Encoding
      class JSONGemEncoder
        private
          # JSONの文字列化処理を直接上書きし、エラーの原因となるオプションを完全に無視させます
          def stringify(jsonified)
            ::JSON.generate(jsonified)
          end
      end
    end
  end
end
