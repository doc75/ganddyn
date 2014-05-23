# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

require 'webmock/rspec'

# enable to test private method of a class
def describe_internally *args, &block
  example = describe *args, &block
  cur_class = args[0]
  if cur_class.is_a? Class
    saved_private_instance_methods = cur_class.private_instance_methods
    example.before do
      cur_class.class_eval { public *saved_private_instance_methods }
    end
    example.after do
      cur_class.class_eval { private *saved_private_instance_methods }
    end
  end
end

